// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";

// forge script script/Swap.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast  -vv
contract SwapScript is Script {
    // PoolSwapTest Contract address on Sepolia
    PoolSwapTest swapRouter = PoolSwapTest(0x9A8ca723F5dcCb7926D00B71deC55c2fEa1F50f7);

    address constant MUNI_ADDRESS = address(0x2a238CbF7A05B45Fb101d9Fde6A1025719Da50fF); //mUNI deployed to SEPOLIA
    address constant MUSDC_ADDRESS = address(0x2AFc1b35CA3102111099f02851CA1C20eA208dDc); //mUSDC deployed to SEPOLIA
    //address constant HOOK_ADDRESS = address(0x3CA2cD9f71104a6e1b67822454c725FcaeE35fF6); //address of the hook contract deployed to SEPOLIA
    address constant HOOK_ADDRESS = address(0); //address of the hook contract deployed to SEPOLIA

    // slippage tolerance to allow for unlimited price impact
    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;

    function run() external {
        address token0 = MUNI_ADDRESS;
        address token1 = MUSDC_ADDRESS;
        uint24 swapFee = 4000; // 0.40% fee tier
        int24 tickSpacing = 10;

        // Using a hooked pool
        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: swapFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        // approve tokens to the swap router
        vm.broadcast();
        IERC20(token0).approve(address(swapRouter), type(uint256).max);
        vm.broadcast();
        IERC20(token1).approve(address(swapRouter), type(uint256).max);

        // ---------------------------- //
        // Swap 100e18 token0 into token1 //
        // ---------------------------- //
        bool zeroForOne = true;
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: 100e18,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT // unlimited impact
        });

        // in v4, users have the option to receieve native ERC20s or wrapped ERC1155 tokens
        // here, we'll take the ERC20s
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        bytes memory hookData = new bytes(0);
        vm.broadcast();
        swapRouter.swap(pool, params, testSettings, hookData);
    }
}