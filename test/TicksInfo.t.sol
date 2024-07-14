// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";

// forge test -vv --match-test test_DisplayTickInfo
contract TakeProfitsHookTest is Test {

    // Pool definition
    int24 tickSpacing = 10;
    // floor(sqrt(4) * 2^96)
    uint160 startingPrice4 = 158456325028528675187087900672;
    // floor(sqrt(1) * 2^96)
    uint160 startingPrice1 = 79228162514264337593543950336;

    
    function setUp() public {}

    function test_DisplayTickInfo() public view {
        int24 maxUsableTick = TickMath.maxUsableTick(tickSpacing);
        int24 minUsableTick = TickMath.minUsableTick(tickSpacing);
        int24 tickAtSqrtPrice = TickMath.getTickAtSqrtPrice(startingPrice4);
        uint160 sqrtPriceAtTick = TickMath.getSqrtPriceAtTick(tickAtSqrtPrice);

        console.log("maxUsableTick: ", maxUsableTick);
        console.log("minUsableTick: ", minUsableTick);
        console.log("Tick at price: ", tickAtSqrtPrice);
        console.log("Price at tick: ", sqrtPriceAtTick);
    }


}