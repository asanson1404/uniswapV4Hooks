
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";

// Our contracts
import {LendingLPHook} from "../src/LendingLPHook.sol";
import {LendingLPHookStub} from "../src/LendingLPHookStub.sol";

contract TestLendingLPHook is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    // The two currencies (tokens) from the pool
    Currency token0;
    Currency token1;

    LendingLPHook lendingLPHook = LendingLPHookStub(
        address(
            uint160(Hooks.AFTER_INITIALIZE_FLAG | Hooks.AFTER_SWAP_FLAG)
        )
    );

    address public fakeAaveAddr = makeAddr("fakeAaveAddr");

    function setUp() public {
        // Deploy v4 core contracts
        deployFreshManagerAndRouters();
        // Deploy two test tokens
        (token0, token1) = deployMintAndApprove2Currencies();

        _stubValidateHookAddress();

        // Approve our hook address to spend these tokens as well
        MockERC20(Currency.unwrap(token0)).approve(
            address(lendingLPHook),
            type(uint256).max
        );
        MockERC20(Currency.unwrap(token1)).approve(
            address(lendingLPHook),
            type(uint256).max
        );

        (key, ) = initPool(token0, token1, lendingLPHook, 3000, SQRT_PRICE_1_1, abi.encode(block.timestamp));

        // Add initial liquidity to the pool
        bytes memory hookData = abi.encode(block.timestamp);

        // Some liquidity from -60 to +60 tick range
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 10 ether,
                salt: bytes32(0)
            }),
            hookData
        );
        // Some liquidity from -120 to +120 tick range
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -120,
                tickUpper: 120,
                liquidityDelta: 11 ether,
                salt: bytes32(0)
            }),
            hookData
        );
        // Some liquidity from 200 to 300 tick range
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: 200,
                tickUpper: 300,
                liquidityDelta: 12 ether,
                salt: bytes32(0)
            }),
            hookData
        );
        // Some liquidity from -100 to -50 tick range
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -100,
                tickUpper: -50,
                liquidityDelta: 13 ether,
                salt: keccak256(abi.encodePacked(msg.sender))
            }),
            hookData
        );
        // some liquidity for full range
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: TickMath.minUsableTick(60),
                tickUpper: TickMath.maxUsableTick(60),
                liquidityDelta: 14 ether,
                salt: keccak256(abi.encodePacked(msg.sender))
            }),
            hookData
        );
    }

    function test_getPositionLiquidity() public {
        lendingLPHook.getPositionLiquidity(key, -60, 60);
    }


    function _stubValidateHookAddress() private {
        LendingLPHookStub stub = new LendingLPHookStub(manager, lendingLPHook, address(modifyLiquidityRouter), fakeAaveAddr);
        
        // Fetch all the storage slot writes that have been done at the stub address
        // during deployment
        (, bytes32[] memory writes) = vm.accesses(address(stub));

        // Etch the code of the stub at the hardcoded hook address
        vm.etch(address(lendingLPHook), address(stub).code);

        // Replay the storage slot writes at the hook address
        unchecked {
            for (uint256 i = 0; i < writes.length; i++) {
                bytes32 slot = writes[i];
                vm.store(address(lendingLPHook), slot, vm.load(address(stub), slot));
            }
        }
    }
}