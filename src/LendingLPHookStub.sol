// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {LendingLPHook} from "./LendingLPHook.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";

contract LendingLPHookStub is LendingLPHook {
    constructor(
        IPoolManager _poolManager,
        LendingLPHook addressToEtch,
        address _lpRouter,
        address _fakeAave
    ) LendingLPHook(_poolManager, _lpRouter, _fakeAave) {
        Hooks.validateHookPermissions(addressToEtch, getHookPermissions());
    }

    // make this a no-op in testing
    function validateHookAddress(BaseHook _this) internal pure override {}
}