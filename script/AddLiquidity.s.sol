// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";

//  forge script script/AddLiquidity.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast  -vv
contract AddLiquidityScript is Script {
    using CurrencyLibrary for Currency;

    //addresses with contracts deployed
    address constant SEPOLIA_POOLMANAGER = address(0xFf34e285F8ED393E366046153e3C16484A4dD674); //pool manager deployed to SEPOLIA
    address constant MUNI_ADDRESS = address(0x2a238CbF7A05B45Fb101d9Fde6A1025719Da50fF); //mUNI deployed to SEPOLIA
    address constant MUSDC_ADDRESS = address(0x2AFc1b35CA3102111099f02851CA1C20eA208dDc); //mUSDC deployed to SEPOLIA
    //address constant HOOK_ADDRESS = address(0x3CA2cD9f71104a6e1b67822454c725FcaeE35fF6); //address of the hook contract deployed to SEPOLIA
    address constant HOOK_ADDRESS = address(0); //address of the hook contract deployed to SEPOLIA

    PoolModifyLiquidityTest lpRouter = PoolModifyLiquidityTest(address(0xFB3e0C6F74eB1a21CC1Da29aeC80D2Dfe6C9a317));

    function run() external {
        address token0 = MUNI_ADDRESS;
        address token1 = MUSDC_ADDRESS;
        uint24 swapFee = 4000; // 0.40% fee tier
        int24 tickSpacing = 10;

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: swapFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        // approve tokens to the LP Router
        vm.broadcast();
        IERC20(token0).approve(address(lpRouter), 100_000e18);
        vm.broadcast();
        IERC20(token1).approve(address(lpRouter), 100_000e18);

        // optionally specify hookData if the hook depends on arbitrary data for liquidity modification
        bytes memory hookData = new bytes(0);

        // logging the pool ID
        PoolId id = PoolIdLibrary.toId(pool);
        bytes32 idBytes = PoolId.unwrap(id);
        console.log("Pool ID Below");
        console.logBytes32(bytes32(idBytes));

        // Provide 10_000e18 worth of liquidity on the range of [-100, 100]
        vm.broadcast();
        //BalanceDelta delta = lpRouter.modifyLiquidity(pool, IPoolManager.ModifyLiquidityParams(13863 - 1203, 13863 + 1207, 10_000e18, 0), hookData);
        //BalanceDelta delta = lpRouter.modifyLiquidity(pool, IPoolManager.ModifyLiquidityParams(-60, 60, 10e18, bytes32(0)), hookData);
        BalanceDelta delta = lpRouter.modifyLiquidity(pool, IPoolManager.ModifyLiquidityParams(13763 - 63, 13763 + 37, 10e18, bytes32(0)), hookData);
        console.log("delta amount 0 (mUNI)", delta.amount0());
        console.log("delta amount 1 (mUSDC)", delta.amount1());
    }
}