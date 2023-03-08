// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/console.sol";
import {Setup, DiamondHelper, MockFactory, ERC20Mock, MockYieldSource, IStrategy} from "./utils/Setup.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract LockedStrategyTest is Setup {
    function setUp() public override {}

    function test_deployStrategy() public {
        // deploy the selector helper first to get a deterministic location
        bytes4[] memory selectors = getSelectors();
        diamondHelper = new DiamondHelper(selectors);

        // deploy the mock factory next for deterministic location
        mockFactory = new MockFactory(0, protocolFeeRecipient);

        //BaseLibrary BaseLibrary = new BaseLibrary();
        console.log(address(BaseLibrary));

        diamondHelper.setLibrary(address(BaseLibrary));

        // create asset we will be using as the underlying asset
        asset = new ERC20Mock("Test asset", "tTKN", address(this), 0);
        // create a mock yield source to deposit into
        yieldSource = new MockYieldSource(address(asset));

        // Deploy strategy and set variables
        strategy = IStrategy(setUpStrategy());
    }
}
