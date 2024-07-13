// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MUNI} from "../src/ERC20/MUNI.sol";
import {MUSDC} from "../src/ERC20/MUSDC.sol";

// forge script script/DeployTokens.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify -vvvv
contract DeployTokens is Script {
    MUNI public mUNI;
    MUSDC public mUSDC;

    function run() public {
        vm.startBroadcast();
        console.log("Deployer Address", msg.sender);

        mUNI = new MUNI();
        mUSDC = new MUSDC();

        console.log("mUNI address", address(mUNI));
        console.log("mUSDC address", address(mUSDC));

        vm.stopBroadcast();
    }
}
