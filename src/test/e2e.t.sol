// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/console.sol";
import {Setup, DiamondHelper, MockFactory, ERC20Mock, MockYieldSource, IMockStrategy} from "./utils/Setup.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract e2eTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    // TODO: multiple deposits/mints/redeem/withdraw and reports
    //      Multiple strategies added to the same library, deposits/storage check
}
