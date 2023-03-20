// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract InvariantTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    // TODO:
    //      Total assets = debt + idle
    //      idle <= balanceOf()
    //      unlcokedShares <= balanceOf(strategy)
    //      PPS doesnt change unless reporting a loss
    //      maxWithdraw <= totalAssets
    //      maxRedeem <= totalSupply
    //      read the unlocking rate and time
}
