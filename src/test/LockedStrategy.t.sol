// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/console.sol";
import {Setup, DiamondHelper, MockFactory, ERC20Mock, MockYieldSource, IMockStrategy} from "./utils/Setup.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract LockedStrategyTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_gas() public {
        uint256 amount = 10e18;

        mintAndDepositIntoStrategy(user, amount);

        vm.prank(user);
        strategy.withdraw(amount, user, user);
    }

    function test_withdrawWithUnrealizedLoss(
        address _address,
        uint256 _amount,
        uint256 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = bound(_lossFactor, 10, MAX_BPS);
        vm.assume(_address != address(0) && _address != address(strategy));

        setFees(0, 0);
        mintAndDepositIntoStrategy(_address, _amount);

        uint256 toLoose = (_amount * _lossFactor) / MAX_BPS;
        // Simulate a loss.
        vm.prank(address(yieldSource));
        asset.transfer(address(69), toLoose);

        uint256 beforeBalance = asset.balanceOf(_address);
        uint256 expectedOut = _amount - toLoose;
        // Withdraw the full amount before the loss is reported.
        vm.prank(_address);
        strategy.withdraw(_amount, _address, _address);

        uint256 afterBalance = asset.balanceOf(_address);

        assertEq(afterBalance - beforeBalance, expectedOut);
        assertEq(strategy.totalDebt(), 0);
        assertEq(strategy.totalIdle(), 0);
        assertEq(strategy.totalSupply(), 0);
        assertEq(strategy.pricePerShare(), wad);
    }
}
