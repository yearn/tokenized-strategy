// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup, IMockStrategy} from "./utils/Setup.sol";

contract ShutdownTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_shutdownStrategy(address _address, uint256 _amount) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        assertTrue(!strategy.isShutdown());

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        assertTrue(!strategy.isShutdown());

        vm.expectEmit(true, true, true, true, address(strategy));
        emit StrategyShutdown();

        vm.prank(management);
        strategy.shutdownStrategy();

        assertTrue(strategy.isShutdown());
        assertEq(strategy.maxMint(_address), 0);
        assertEq(strategy.madDeposit(_address), 0);

        asset.mint(_address, _amount);
        vm.prank(_address);
        asset.approve(address(strategy), _amount);

        vm.expectRevert("shutdown");
        vm.prank(_address);
        strategy.deposit(_amount, _address);

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);
    }

    function test_shutdownStrategy_canWithdraw(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        assertTrue(!strategy.isShutdown());

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        assertTrue(!strategy.isShutdown());

        vm.expectEmit(true, true, true, true, address(strategy));
        emit StrategyShutdown();

        vm.prank(management);
        strategy.shutdownStrategy();

        assertTrue(strategy.isShutdown());
        assertEq(strategy.maxMint(_address), 0);
        assertEq(strategy.madDeposit(_address), 0);

        asset.mint(_address, _amount);
        vm.prank(_address);
        asset.approve(address(strategy), _amount);

        vm.expectRevert("shutdown");
        vm.prank(_address);
        strategy.deposit(_amount, _address);

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        uint256 before = asset.balanceOf(_address);

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(asset.balanceOf(_address), before + _amount);
    }

    function test_shutdownStrategy_canReport(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );
        _lossFactor = uint16(bound(uint256(_lossFactor), 10, 5_000));

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;

        assertTrue(!strategy.isShutdown());

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        assertTrue(!strategy.isShutdown());

        vm.expectEmit(true, true, true, true, address(strategy));
        emit StrategyShutdown();

        vm.prank(management);
        strategy.shutdownStrategy();

        assertTrue(strategy.isShutdown());

        asset.mint(_address, _amount);
        vm.prank(_address);
        asset.approve(address(strategy), _amount);

        vm.expectRevert("shutdown");
        vm.prank(_address);
        strategy.deposit(_amount, _address);

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        // Make sure report still works and we can report a final loss
        createAndCheckLoss(strategy, loss, 0, 0);

        checkStrategyTotals(
            strategy,
            _amount - loss,
            _amount - loss,
            0,
            _amount
        );

        uint256 before = asset.balanceOf(_address);

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(asset.balanceOf(_address), before + _amount - loss);
    }
}
