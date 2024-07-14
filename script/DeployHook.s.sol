// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Script, console} from "forge-std/Script.sol";
import {LendingLPHook} from "../src/LendingLPHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";
import {HookMiner} from "../src/utils/HookMiner.sol";

// forge script script/DeployHook.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify -vvvv
contract DeployHook is Script {
    LendingLPHook public lendingLPHook;

    //addresses with contracts deployed
    //address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
    address constant SEPOLIA_POOLMANAGER = address(0xFf34e285F8ED393E366046153e3C16484A4dD674); //pool manager deployed to SEPOLIA
    address lpRouter = address(0xFB3e0C6F74eB1a21CC1Da29aeC80D2Dfe6C9a317);
    address fakeAave = address(0x3Ab127Aa9D64501e6cBC5aA51f674dfDC9a826Ab);

    function run() public {
        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
                | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
        );

        // Mine a salt that will produce a hook address with the correct flags
        (address hookAddress, bytes32 salt) =
            HookMiner.find(address(0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2), flags, type(LendingLPHook).creationCode, abi.encode(address(SEPOLIA_POOLMANAGER)));


        vm.startBroadcast();
        console.log("Deployer Address", msg.sender);

        lendingLPHook = new LendingLPHook{salt: salt}(
            IPoolManager(SEPOLIA_POOLMANAGER),
            lpRouter,
            fakeAave
        );
        require(address(lendingLPHook) == hookAddress, "hook address mismatch");

        console.log("LendingLPHook address", address(lendingLPHook));

        vm.stopBroadcast();
    }
}
