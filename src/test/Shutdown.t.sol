// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

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
        assertEq(strategy.maxDeposit(_address), 0);

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
        assertEq(strategy.maxDeposit(_address), 0);

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
        createAndCheckLoss(strategy, loss, 0, true);

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

    function test_emergencyWithdraw_halfAmount(
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

        vm.expectEmit(true, true, true, true, address(strategy));
        emit StrategyShutdown();

        vm.prank(management);
        strategy.shutdownStrategy();

        assertTrue(strategy.isShutdown());

        // Withdra half and make sure it records properly
        uint256 toWithdraw = _amount / 2;

        vm.prank(management);
        strategy.emergencyWithdraw(toWithdraw);

        // Make sure it pulled out the correct amount.
        // And recorded it correctly
        checkStrategyTotals(
            strategy,
            _amount,
            _amount - toWithdraw,
            toWithdraw,
            _amount
        );

        assertEq(asset.balanceOf(address(strategy)), toWithdraw);

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(asset.balanceOf(_address), _amount);
    }

    function test_emergencyWithdraw_withProfit(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        setFees(0, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        assertTrue(!strategy.isShutdown());

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit StrategyShutdown();

        vm.prank(management);
        strategy.shutdownStrategy();

        assertTrue(strategy.isShutdown());

        uint256 pps = strategy.pricePerShare();
        // Simulate a profit
        asset.mint(address(yieldSource), profit);

        vm.prank(management);
        strategy.emergencyWithdraw(_amount + profit);

        // Make sure it recorded the correct amount
        checkStrategyTotals(strategy, _amount, 0, _amount, _amount);

        // PPS should not change.
        assertEq(strategy.pricePerShare(), pps);
        assertEq(asset.balanceOf(address(strategy)), _amount + profit);

        // Make sure we can now report the profit.
        vm.expectEmit(true, true, true, true, address(strategy));
        emit Reported(profit, 0, 0, 0);

        vm.prank(management);
        strategy.report();

        skip(strategy.profitMaxUnlockTime());

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(asset.balanceOf(_address), _amount + profit);
    }

    function test_emergencyWithdraw_withLoss(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 10, 5_000));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;

        assertTrue(!strategy.isShutdown());

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit StrategyShutdown();

        vm.prank(management);
        strategy.shutdownStrategy();

        assertTrue(strategy.isShutdown());

        uint256 pps = strategy.pricePerShare();
        // Simulate a loss
        yieldSource.simulateLoss(loss);

        vm.prank(management);
        strategy.emergencyWithdraw(_amount - loss);

        // Make sure it recorded the correct amount.
        // Loss will still be counted as debt.
        checkStrategyTotals(strategy, _amount, loss, _amount - loss, _amount);

        // PPS should not change.
        assertEq(strategy.pricePerShare(), pps);
        assertEq(asset.balanceOf(address(strategy)), _amount - loss);

        // Make sure we can now report the profit.
        vm.expectEmit(true, true, true, true, address(strategy));
        emit Reported(0, loss, 0, 0);

        vm.prank(management);
        strategy.report();

        uint256 before = asset.balanceOf(_address);

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(asset.balanceOf(_address) - before, _amount - loss);
    }

    function test_emergencyWithdraw_notShutdown_reverts(
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

        uint256 toWithdraw = _amount / 2;

        vm.expectRevert("not shutdown");
        vm.prank(management);
        strategy.emergencyWithdraw(toWithdraw);
    }
}
