// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup, IMockStrategy} from "./utils/Setup.sol";

contract FaultyStrategy is Setup {
    // Full reentrancy variables
    bool public reenter;
    address public addr;
    uint256 public amount;

    // View reentrancy variables
    uint256 public pps;
    uint256 public convertAmountToShares;
    uint256 public convertAmountToAssets;

    function setUp() public override {
        super.setUp();
    }

    function test_faultyStrategy_depositsToMuch(
        address _address,
        uint256 _amount,
        uint256 _faultAmount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _faultAmount = bound(_faultAmount, 10, MAX_BPS);

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        configureFaultyStrategy(_faultAmount, false);

        // We need to allow the strategy to deploy Funds more than it should
        asset.mint(address(strategy), _faultAmount);

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // These should all be right even though the amount deployed was actually more
        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        assertEq(asset.balanceOf(address(yieldSource)), _amount + _faultAmount);

        uint256 before = asset.balanceOf(_address);

        vm.prank(_address);
        strategy.withdraw(_amount, _address, _address);

        // We should have just withdrawn '_amount' and
        // not accounted for the _faultAmount but will be in the strategy now
        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(asset.balanceOf(_address) - before, _amount);
        assertEq(asset.balanceOf(address(strategy)), _faultAmount);
    }

    function test_faultyStrategy_withdrawsToMuch(
        address _address,
        uint256 _amount,
        uint256 _faultAmount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _faultAmount = bound(_faultAmount, 10, MAX_BPS);

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        configureFaultyStrategy(_faultAmount, false);

        // We need to allow the strategy to pull more than it should
        asset.mint(address(yieldSource), _faultAmount);

        uint256 before = asset.balanceOf(_address);

        vm.prank(_address);
        strategy.withdraw(_amount, _address, _address);

        // We should have just withdrawn '_amount' and
        // not accounted for the _faultAmount but will be in the strategy now
        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(asset.balanceOf(_address) - before, _amount);
        assertEq(asset.balanceOf(address(strategy)), _faultAmount);
    }

    function test_deployFundsViewReentrancy(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        setFees(0, 0);

        configureFaultyStrategy(0, true);

        // Save current values for view reentrancy checks
        storeCallBackVariables(_amount);

        // The deposit should check against the stored variables
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        configureFaultyStrategy(0, false);

        createAndCheckProfit(strategy, profit, 0, 0);

        increaseTimeAndCheckBuffer(strategy, 5 days, profit / 2);

        // Check again while there is profit unlocking
        configureFaultyStrategy(0, true);

        storeCallBackVariables(_amount);

        mintAndDepositIntoStrategy(strategy, _address, _amount);
    }

    function test_freeFundsViewReentrancy(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        setFees(0, 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        increaseTimeAndCheckBuffer(strategy, 5 days, 0);

        configureFaultyStrategy(0, true);

        storeCallBackVariables(_amount / 2);

        vm.prank(_address);
        strategy.withdraw(_amount / 2, _address, _address);

        configureFaultyStrategy(0, false);

        createAndCheckProfit(strategy, profit, 0, 0);

        increaseTimeAndCheckBuffer(strategy, 5 days, profit / 2);

        // Check again while there is profit unlocking
        configureFaultyStrategy(0, true);

        storeCallBackVariables(_amount / 2);

        vm.prank(_address);
        strategy.withdraw(_amount / 2, _address, _address);
    }

    function test_reportViewReentrancy(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        setFees(0, 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // The expected '_amount' for the callback check
        uint256 assets = _amount + profit;

        configureFaultyStrategy(0, true);

        storeCallBackVariables(assets);

        createAndCheckProfit(strategy, profit, 0, 0);

        increaseTimeAndCheckBuffer(strategy, 10 days, 0);

        storeCallBackVariables(_amount);

        createAndCheckLoss(strategy, profit, 0, true);
    }

    function test_tendViewReentrancy(address _address, uint256 _amount) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        setFees(0, 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        configureFaultyStrategy(0, true);
        // Tend with some idle
        storeCallBackVariables(strategy.totalIdle());

        vm.prank(keeper);
        strategy.tend();
    }

    function test_deployFundsReentrancy_reverts(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(_address != address(0) && _address != address(strategy));

        setFees(0, 0);

        configureFaultyStrategy(0, true);

        reenter = true;

        // Save current values for view reentrancy checks
        storeReentrancyVariables(_address, _amount);

        asset.mint(_address, _amount);

        vm.prank(_address);
        asset.approve(address(strategy), _amount);

        // The deposit should try to trigger a second deposit within it
        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(_address);
        strategy.deposit(_amount, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(_address);
        strategy.mint(_amount, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_freeFundsReentrancy_reverts(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        setFees(0, 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        increaseTimeAndCheckBuffer(strategy, 5 days, 0);

        configureFaultyStrategy(0, true);
        reenter = true;

        // Save current values for reentrancy
        storeReentrancyVariables(_address, _amount);

        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(_address);
        strategy.withdraw(_amount, _address, _address);

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);
    }

    // Reentrancy cant be allowed during a report call/
    function test_reportReentrancy_reverts(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        setFees(0, 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        configureFaultyStrategy(0, true);

        storeReentrancyVariables(_address, _amount);

        reenter = true;

        asset.mint(address(strategy), profit);

        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(keeper);
        strategy.report();

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);
    }

    function test_tendReentrancy_reverts(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        setFees(0, 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        configureFaultyStrategy(0, true);

        reenter = true;

        storeReentrancyVariables(_address, _amount);

        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(keeper);
        strategy.tend();
    }

    // This function simulates being called during a extenal call of a deposit withdraw or report.
    // This should return the same values as will be stored right before the call and checked right after the call.
    function callBack(
        uint256 _pps,
        uint256 _convertAmountToShares,
        uint256 _convertAmountToAssets
    ) public {
        // If 'reenter' we will actually try to deposit if not just check values for views
        if (reenter) {
            // Try and deposit back into the strategy within the original call
            mintAndDepositIntoStrategy(strategy, addr, amount);
        } else {
            assertEq(_pps, pps);
            assertEq(_convertAmountToShares, convertAmountToShares);
            assertEq(_convertAmountToAssets, convertAmountToAssets);
        }
    }

    function storeCallBackVariables(uint256 _amount) public {
        pps = strategy.pricePerShare();
        convertAmountToShares = strategy.convertToShares(_amount);
        convertAmountToAssets = strategy.convertToAssets(_amount);
    }

    function storeReentrancyVariables(
        address _address,
        uint256 _amount
    ) public {
        addr = _address;
        amount = _amount;
    }
}
