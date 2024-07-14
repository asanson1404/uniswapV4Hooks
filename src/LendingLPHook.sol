// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/console.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";

contract LendingLPHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    PoolModifyLiquidityTest public lpRouter;
    address public fakeAave;

    uint256 public numberOfRangeAboveCurrentTick;
    uint256 public numberOfRangeBelowCurrentTick;
    uint256 public numberOfActiveRange;
    int24 public nbTicksBuffer = 100;

    // Create a mapping to store the last known tickLower value for a given Pool
    mapping(PoolId poolId => int24 tickLower) public tickLowerLasts;

    mapping(bytes32 => PositionStatus) public positionStatus;

    bytes32[] public positionIds;

    struct PositionStatus {
        int24 tickLower;
        int24 tickUpper;
        bool tokensWorkingSomewhereElse;
        PoolKey poolKey;
    }

    // Initialize BaseHook
    constructor(
        IPoolManager _poolManager,
        address _lpRouter,
        address _fakeAave
    ) BaseHook(_poolManager) {
        lpRouter = PoolModifyLiquidityTest(_lpRouter);
        fakeAave = _fakeAave;
    }

    // function validateHookAddress(BaseHook _this) internal pure override {}

    // Required override function for BaseHook to let the PoolManager know which hooks are implemented
    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: true,
                beforeAddLiquidity: false,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }


    /* -------------- afterInitialize Hook --------------- */
    function afterInitialize(
        address,
        PoolKey calldata key,
        uint160,
        int24 tick,
        // Add bytes calldata after tick
        bytes calldata
    ) external override onlyByManager returns (bytes4) {
        _setTickLowerLast(key.toId(), getTickLower(tick, key.tickSpacing));
        return LendingLPHook.afterInitialize.selector;
    }

    /* -------------- afterAddLiquidity Hook --------------- */
    function afterAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta balanceDelta,
        bytes calldata
    ) external override onlyByManager returns (bytes4, BalanceDelta) {
        console.log("In AFTER ADD LIQUIDITY HOOOOOOOOOOOOOOOOOOOOOOOOK");
        bytes32 positionId =
            keccak256(abi.encodePacked(address(lpRouter), params.tickLower, params.tickUpper, bytes32(0)));
        positionIds.push(positionId);

        // Create a PositionStatus
        positionStatus[positionId] = PositionStatus(
            params.tickLower,
            params.tickUpper,
            false,
            key
        );

        int24 lastTickLower = tickLowerLasts[key.toId()];

        // Verify if the tickLower bound is above the current tickUpper + buffer
        if (params.tickLower > (lastTickLower + key.tickSpacing) + (nbTicksBuffer * key.tickSpacing)) {

        }
        // Verify if the tickUpper bound is below the current tickLower
        else if (params.tickUpper < lastTickLower - (nbTicksBuffer * key.tickSpacing)) {
        }

        return (LendingLPHook.afterAddLiquidity.selector, balanceDelta);

    }

    /* -------------- afterSwap Hook --------------- */
    function afterSwap(
        address addr,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta,
        bytes calldata
    ) external override onlyByManager returns (bytes4, int128) {
        // Get the exact current tick and use it to calculate the currentTickLower
        (, int24 currentTick,,) = StateLibrary.getSlot0(manager, key.toId());
        int24 currentTickLower = getTickLower(currentTick, key.tickSpacing);
        int24 lastTickLower = tickLowerLasts[key.toId()];

        bytes32 positionId;
        uint128 liquidityToSend;

        // If tick has increased since last tick (i.e. OneForZero swaps happened)
        if (lastTickLower < currentTickLower) {
            for (uint256 i = 0; i < positionIds.length; i++) {
                positionId = positionIds[i];
                if (positionStatus[positionId].tickLower > currentTickLower + (nbTicksBuffer * key.tickSpacing) ) {
                    liquidityToSend += getPositionLiquidity(key, positionStatus[positionId].tickLower, positionStatus[positionId].tickUpper);
                    positionStatus[positionId].tokensWorkingSomewhereElse = true;
                }
            }
            manager.take(key.currency1, address(this), liquidityToSend);
            key.currency1.transfer(fakeAave, uint256(liquidityToSend));
        } else {
            for (uint256 i = 0; i < positionIds.length; i++) {
                positionId = positionIds[i];
                if (positionStatus[positionId].tickUpper < currentTickLower - (nbTicksBuffer * key.tickSpacing) ) {
                    liquidityToSend += getPositionLiquidity(key, positionStatus[positionId].tickLower, positionStatus[positionId].tickUpper);
                    positionStatus[positionId].tokensWorkingSomewhereElse = true;
                }
            }
        }

        return (LendingLPHook.afterSwap.selector, 0);
    }


    /* -------------- Utility Helpers --------------- */
    function _setTickLowerLast(PoolId poolId, int24 tickLower) private {
        tickLowerLasts[poolId] = tickLower;
    }

    function getTickLower(int24 actualTick, int24 tickSpacing) public pure returns (int24) {
        int24 intervals = actualTick / tickSpacing;
        if (actualTick < 0 && actualTick % tickSpacing != 0) intervals--; // round towards negative infinity
        return intervals * tickSpacing;
    }

    function getPositionLiquidity(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper
    ) public view returns (uint128) {
        bytes32 positionId =
            keccak256(abi.encodePacked(address(lpRouter), tickLower, tickUpper, bytes32(0)));
        return StateLibrary.getPositionLiquidity(manager, PoolIdLibrary.toId(key), positionId);
    }
}