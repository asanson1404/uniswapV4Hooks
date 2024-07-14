// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";

contract CreatePoolScript is Script {
    using CurrencyLibrary for Currency;

    //addresses with contracts deployed
    address constant SEPOLIA_POOLMANAGER = address(0xFf34e285F8ED393E366046153e3C16484A4dD674); //pool manager deployed to SEPOLIA
    address constant MUNI_ADDRESS = address(0x2a238CbF7A05B45Fb101d9Fde6A1025719Da50fF); //mUNI deployed to SEPOLIA
    address constant MUSDC_ADDRESS = address(0x2AFc1b35CA3102111099f02851CA1C20eA208dDc); //mUSDC deployed to SEPOLIA
    address constant HOOK_ADDRESS = address(0xA2b10AEd128770a99Ec138C1a61bD806A010e20A); //address of the hook contract deployed to SEPOLIA

    IPoolManager manager = IPoolManager(SEPOLIA_POOLMANAGER);

    function run() external {
        address token0 = MUNI_ADDRESS;
        address token1 = MUSDC_ADDRESS;
        uint24 swapFee = 4000;
        int24 tickSpacing = 10;

        // floor(sqrt(4) * 2^96)
        // uint160 startingPrice = 158456325028528675187087900672;
        // floor(sqrt(1) * 2^96)
        uint160 startingPrice = 79228162514264337593543950336;

        bytes memory hookData = abi.encode(block.timestamp);

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: swapFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        // Turn the Pool into an ID so you can use it for modifying positions, swapping, etc.
        PoolId id = PoolIdLibrary.toId(pool);
        bytes32 idBytes = PoolId.unwrap(id);

        console.log("Pool ID Below");
        console.logBytes32(bytes32(idBytes));

        vm.broadcast();
        manager.initialize(pool, startingPrice, hookData);
    }
}