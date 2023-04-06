// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup, IMockStrategy} from "./utils/Setup.sol";

contract CloningTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_clone(address _address, uint256 _amount) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(0) && _address != address(strategy));

        assertTrue(strategy.isOriginal());

        // We dont know what the cloned address will be so only check the strategy.
        vm.expectEmit(false, true, true, true, address(strategy));
        emit Cloned(address(0), address(strategy));
        address clone = strategy.clone(address(asset), address(yieldSource));
        IMockStrategy clonedStrategy = IMockStrategy(clone);

        assertNeq(clone, address(strategy));
        assertTrue(!clonedStrategy.isOriginal());
        assertEq(clonedStrategy.asset(), address(asset));
        assertEq(clonedStrategy.management(), address(this));
        assertEq(clonedStrategy.performanceFee(), 1_000);
        assertEq(clonedStrategy.performanceFeeRecipient(), address(this));

        if (clone == _address) {
            _address = management;
        }

        // Deposit into the original and make sure it only changes that one
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        assertEq(clonedStrategy.totalAssets(), 0);
        assertEq(clonedStrategy.totalSupply(), 0);

        // Mint into the new strategy and check working correct.
        uint256 clonedAmount = _amount * 2;

        asset.mint(_address, clonedAmount);
        vm.prank(_address);
        asset.approve(address(clonedStrategy), clonedAmount);

        vm.prank(_address);
        clonedStrategy.deposit(clonedAmount, _address);

        // Nothing changes with OG
        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        // Deposit worked correctly in clone
        assertEq(clonedStrategy.totalAssets(), clonedAmount);
        assertEq(clonedStrategy.totalSupply(), clonedAmount);
        assertEq(clonedStrategy.totalIdle(), 0);
        assertEq(clonedStrategy.totalDebt(), clonedAmount);
    }

    function test_cloneCustomAddresses(
        address _address,
        uint256 _amount,
        address _mangement,
        address _pfr,
        address _keeper
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(0) && _address != address(strategy));
        vm.assume(_mangement != address(0) && _mangement != address(strategy));
        vm.assume(_pfr != address(0) && _pfr != address(strategy));
        vm.assume(_keeper != address(0) && _keeper != address(strategy));

        assertTrue(strategy.isOriginal());

        // We dont know what the cloned address will be so only check the strategy.
        vm.expectEmit(false, true, true, true, address(strategy));
        emit Cloned(address(0), address(strategy));
        address clone = strategy._clone(
            address(asset),
            "Test Namez",
            _mangement,
            _pfr,
            _keeper,
            address(yieldSource)
        );
        IMockStrategy clonedStrategy = IMockStrategy(clone);

        assertNeq(clone, address(strategy));
        assertTrue(!clonedStrategy.isOriginal());
        assertEq(clonedStrategy.asset(), address(asset));
        assertEq(clonedStrategy.management(), _mangement);
        assertEq(clonedStrategy.performanceFee(), 1_000);
        assertEq(clonedStrategy.performanceFeeRecipient(), _pfr);
        assertEq(clonedStrategy.keeper(), _keeper);

        if (clone == _address) {
            _address = management;
        }

        // Deposit into the original and make sure it only changes that one
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        assertEq(clonedStrategy.totalAssets(), 0);
        assertEq(clonedStrategy.totalSupply(), 0);

        // Mint into the new strategy and check working correct.
        uint256 clonedAmount = _amount * 2;

        asset.mint(_address, clonedAmount);
        vm.prank(_address);
        asset.approve(address(clonedStrategy), clonedAmount);

        vm.prank(_address);
        clonedStrategy.deposit(clonedAmount, _address);

        // Nothing changes with OG
        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        // Deposit worked correctly in clone
        assertEq(clonedStrategy.totalAssets(), clonedAmount);
        assertEq(clonedStrategy.totalSupply(), clonedAmount);
        assertEq(clonedStrategy.totalIdle(), 0);
        assertEq(clonedStrategy.totalDebt(), clonedAmount);
    }

    function test_cloneAClone_reverts(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(0) && _address != address(strategy));

        assertTrue(strategy.isOriginal());

        address clone = strategy.clone(address(asset), address(yieldSource));
        IMockStrategy clonedStrategy = IMockStrategy(clone);

        assertNeq(clone, address(strategy));
        assertTrue(!clonedStrategy.isOriginal());
        assertEq(clonedStrategy.asset(), address(asset));
        assertEq(clonedStrategy.management(), address(this));
        assertEq(clonedStrategy.performanceFee(), 1_000);
        assertEq(clonedStrategy.performanceFeeRecipient(), address(this));

        // Try and clone the cloned strategy
        vm.expectRevert("!clone");
        clonedStrategy.clone(address(asset), address(yieldSource));
    }

    function test_cloneWithBadPerformanceFeeRecipient_reverts(
        address _address,
        uint256 _amount,
        address _mangement,
        address _keeper
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(0) && _address != address(strategy));
        vm.assume(_mangement != address(0) && _mangement != address(strategy));
        vm.assume(_keeper != address(0) && _keeper != address(strategy));

        assertTrue(strategy.isOriginal());

        vm.expectRevert("init failed");
        strategy._clone(
            address(asset),
            "Test Namez",
            _mangement,
            address(0),
            _keeper,
            address(yieldSource)
        );

        // Otherwise would work fine
        // We dont know what the cloned address will be so only check the strategy.
        vm.expectEmit(false, true, true, true, address(strategy));
        emit Cloned(address(0), address(strategy));
        strategy._clone(
            address(asset),
            "Test Namez",
            _mangement,
            address(1),
            _keeper,
            address(yieldSource)
        );
    }
}
