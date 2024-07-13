// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";

// forge script script/GetCurrentTick.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast  -vv
contract GetPoolInfo is Script {
    using CurrencyLibrary for Currency;

    //addresses with contracts deployed
    address constant SEPOLIA_POOLMANAGER = address(0xFf34e285F8ED393E366046153e3C16484A4dD674); //pool manager deployed to SEPOLIA
    address constant MUNI_ADDRESS = address(0x2a238CbF7A05B45Fb101d9Fde6A1025719Da50fF); //mUNI deployed to SEPOLIA
    address constant MUSDC_ADDRESS = address(0x2AFc1b35CA3102111099f02851CA1C20eA208dDc); //mUSDC deployed to SEPOLIA
    //address constant HOOK_ADDRESS = address(0x3CA2cD9f71104a6e1b67822454c725FcaeE35fF6); //address of the hook contract deployed to SEPOLIA
    address constant HOOK_ADDRESS = address(0); //address of the hook contract deployed to SEPOLIA

    IPoolManager manager = IPoolManager(SEPOLIA_POOLMANAGER);

    // Pool definition
    address token0 = MUNI_ADDRESS;
    address token1 = MUSDC_ADDRESS;
    uint24 swapFee = 4000;
    int24 tickSpacing = 10;
    // floor(sqrt(4) * 2^96)
    uint160 startingPrice = 158456325028528675187087900672;

    function run() public {
        int24 maxUsableTick = TickMath.maxUsableTick(tickSpacing);
        int24 minUsableTick = TickMath.minUsableTick(tickSpacing);
        int24 tickAtSartingPrice = TickMath.getTickAtSqrtPrice(startingPrice);

        console.log("maxUsableTick: ", maxUsableTick);
        console.log("minUsableTick: ", minUsableTick);
        console.log("Tick at starting price: ", tickAtSartingPrice);
        console.log("Strating price: ", startingPrice);

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: swapFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        vm.startBroadcast();
        (, int24 currentTick,,) = StateLibrary.getSlot0(manager, PoolIdLibrary.toId(pool));
        vm.stopBroadcast();
        console.log("Current tick: ", currentTick);
    }


}