// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup, BaseLibrary} from "./utils/Setup.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract ProfitLockingTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function getExpectedProtocolFee(
        uint256 _amount,
        uint16 _fee
    ) public view returns (uint256) {
        uint256 timePassed = Math.min(
            block.timestamp - strategy.lastReport(),
            block.timestamp - mockFactory.lastChange()
        );
        return (_amount * _fee * timePassed) / MAX_BPS / 31_556_952;
    }

    function test_gain_NoFeesNoBuffer(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            strategy,
            profitMaxUnlockTime / 2,
            profit / 2
        );

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + (profit / 2)
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        assertRelApproxEq(
            strategy.pricePerShare(),
            wad + ((wad * _profitFactor) / MAX_BPS),
            MAX_BPS
        );

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount
        );

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainProtocolFee_NoPerformanceFeeNoBuffer(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set protocol fee to 100 bps so there will always be fees charged over a 10 day period with minFuzzAmount
        uint16 protocolFee = 100;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            strategy,
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + totalExpectedFees
        );

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalExpectedFees
        );
        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees
        );

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        vm.prank(protocolFeeRecipient);
        strategy.redeem(
            totalExpectedFees,
            protocolFeeRecipient,
            protocolFeeRecipient
        );

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainPerformanceFee_NoProtocolNoBuffer(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set perf fee to 10%
        uint16 protocolFee = 0;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            strategy,
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + totalExpectedFees
        );

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalExpectedFees
        );
        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees
        );

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        vm.prank(performanceFeeRecipient);
        strategy.redeem(
            totalExpectedFees,
            performanceFeeRecipient,
            performanceFeeRecipient
        );

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainProtocolFeePerformanceFee_NoBuffer(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set perf fee to 10% protcol fee to 100 bps
        uint16 protocolFee = 100;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            strategy,
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + totalExpectedFees
        );

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalExpectedFees
        );
        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees
        );

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        vm.prank(performanceFeeRecipient);
        strategy.redeem(
            expectedPerformanceFee,
            performanceFeeRecipient,
            performanceFeeRecipient
        );

        expectedAssetsForFees = strategy.convertToAssets(expectedProtocolFee);
        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            expectedProtocolFee
        );

        vm.prank(protocolFeeRecipient);
        strategy.redeem(
            expectedProtocolFee,
            protocolFeeRecipient,
            protocolFeeRecipient
        );

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainBuffer_noProtocolFeeNoPerformanceFee(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            strategy,
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        uint256 newAmount = _amount + profit;
        uint256 secondExpectedProtocolFee = getExpectedProtocolFee(
            newAmount,
            protocolFee
        );

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            secondExpectedProtocolFee + expectedPerformanceFee
        );

        createAndCheckProfit(
            strategy,
            profit,
            secondExpectedProtocolFee,
            expectedPerformanceFee
        );

        checkStrategyTotals(
            strategy,
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount -
                ((profit - totalExpectedFees) / 2) +
                strategy.convertToShares(profit)
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        checkStrategyTotals(
            strategy,
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount - profit + totalExpectedFees + secondExpectedSharesForFees
        );

        vm.prank(_address);
        strategy.redeem(newAmount - profit, _address, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainProtocolFeeBuffer_noPerformanceFee(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set fees
        uint16 protocolFee = 100;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            strategy,
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        uint256 newAmount = _amount + profit;
        uint256 secondExpectedProtocolFee = getExpectedProtocolFee(
            newAmount,
            protocolFee
        );

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            secondExpectedProtocolFee + expectedPerformanceFee
        );

        createAndCheckProfit(
            strategy,
            profit,
            secondExpectedProtocolFee,
            expectedPerformanceFee
        );

        checkStrategyTotals(
            strategy,
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount -
                ((profit - totalExpectedFees) / 2) +
                strategy.convertToShares(profit)
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        checkStrategyTotals(
            strategy,
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount - profit + totalExpectedFees + secondExpectedSharesForFees
        );

        vm.prank(_address);
        strategy.redeem(newAmount - profit, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalExpectedFees + secondExpectedSharesForFees
        );

        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees + secondExpectedSharesForFees
        );

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        uint256 balance = strategy.balanceOf(protocolFeeRecipient);
        vm.prank(protocolFeeRecipient);
        strategy.redeem(balance, protocolFeeRecipient, protocolFeeRecipient);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainPerformanceFeeBuffer_noProtocolFee(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set fees
        uint16 protocolFee = 0;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            strategy,
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        uint256 newAmount = _amount + profit;
        uint256 secondExpectedProtocolFee = getExpectedProtocolFee(
            newAmount,
            protocolFee
        );

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            secondExpectedProtocolFee + expectedPerformanceFee
        );

        createAndCheckProfit(
            strategy,
            profit,
            secondExpectedProtocolFee,
            expectedPerformanceFee
        );

        checkStrategyTotals(
            strategy,
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount -
                ((profit - totalExpectedFees) / 2) +
                strategy.convertToShares(profit)
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        checkStrategyTotals(
            strategy,
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount - profit + totalExpectedFees + secondExpectedSharesForFees
        );

        vm.prank(_address);
        strategy.redeem(newAmount - profit, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalExpectedFees + secondExpectedSharesForFees
        );

        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees + secondExpectedSharesForFees
        );

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        uint256 balance = strategy.balanceOf(performanceFeeRecipient);
        vm.prank(performanceFeeRecipient);
        strategy.redeem(
            balance,
            performanceFeeRecipient,
            performanceFeeRecipient
        );

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainProtocolFeePerformanceFeeBuffer(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set fees
        uint16 protocolFee = 100;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            strategy,
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        uint256 newAmount = _amount + profit;
        uint256 secondExpectedProtocolFee = getExpectedProtocolFee(
            newAmount,
            protocolFee
        );

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            secondExpectedProtocolFee + expectedPerformanceFee
        );

        createAndCheckProfit(
            strategy,
            profit,
            secondExpectedProtocolFee,
            expectedPerformanceFee
        );

        checkStrategyTotals(
            strategy,
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount -
                ((profit - totalExpectedFees) / 2) +
                strategy.convertToShares(profit)
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        checkStrategyTotals(
            strategy,
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount - profit + totalExpectedFees + secondExpectedSharesForFees
        );

        vm.prank(_address);
        // Use newAmount - profit here to avoid stack to deep
        strategy.redeem(newAmount - profit, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalExpectedFees + secondExpectedSharesForFees
        );

        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees + secondExpectedSharesForFees
        );

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        uint256 balance = strategy.balanceOf(protocolFeeRecipient);
        vm.prank(protocolFeeRecipient);
        strategy.redeem(balance, protocolFeeRecipient, protocolFeeRecipient);

        balance = strategy.balanceOf(performanceFeeRecipient);
        vm.prank(performanceFeeRecipient);
        strategy.redeem(
            balance,
            performanceFeeRecipient,
            performanceFeeRecipient
        );

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_loss_NoFeesNoBuffer(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 1, 5_000));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (loss * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckLoss(
            strategy,
            loss,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertRelApproxEq(
            strategy.pricePerShare(),
            wad - ((wad * _lossFactor) / MAX_BPS),
            MAX_BPS / 10
        );

        checkStrategyTotals(
            strategy,
            _amount - loss,
            _amount - loss,
            0,
            _amount
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        checkStrategyTotals(
            strategy,
            _amount - loss,
            _amount - loss,
            0,
            _amount
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        assertRelApproxEq(
            strategy.pricePerShare(),
            wad - ((wad * _lossFactor) / MAX_BPS),
            MAX_BPS / 10
        );

        checkStrategyTotals(
            strategy,
            _amount - loss,
            _amount - loss,
            0,
            _amount
        );

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_lossProtocolFees_NoBuffer(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 1, 5_000));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set all fees to 0
        uint16 protocolFee = 100;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (loss * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckLoss(
            strategy,
            loss,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertRelApproxEq(
            strategy.pricePerShare(),
            wad - ((wad * _lossFactor) / MAX_BPS),
            MAX_BPS / 10
        );

        checkStrategyTotals(
            strategy,
            _amount - loss,
            _amount - loss,
            0,
            _amount + totalExpectedFees
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        checkStrategyTotals(
            strategy,
            _amount - loss,
            _amount - loss,
            0,
            _amount + totalExpectedFees
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        assertRelApproxEq(
            strategy.pricePerShare(),
            wad - ((wad * _lossFactor) / MAX_BPS),
            MAX_BPS / 10
        );

        checkStrategyTotals(
            strategy,
            _amount - loss,
            _amount - loss,
            0,
            _amount + totalExpectedFees
        );

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        uint256 balance = strategy.balanceOf(protocolFeeRecipient);
        vm.prank(protocolFeeRecipient);
        strategy.redeem(balance, protocolFeeRecipient, protocolFeeRecipient);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_lossBuffer_NoProtocolFees(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 10, 5_000));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        //uint16 performanceFee = 0;
        setFees(protocolFee, 0);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (loss * 0) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        // Simulate an original profit of 2x the loss
        createAndCheckProfit(
            strategy,
            loss * 2,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + loss * 2,
            _amount + loss * 2,
            0,
            _amount + loss * 2
        );

        // Half way through we should have the full loss still as abuffer
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, loss);

        checkStrategyTotals(
            strategy,
            _amount + loss * 2,
            _amount + loss * 2,
            0,
            _amount + loss * 2 + totalExpectedFees - loss
        );

        uint256 newAmount = _amount + loss * 2;
        uint256 secondExpectedProtocolFee = getExpectedProtocolFee(
            newAmount,
            protocolFee
        );

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            secondExpectedProtocolFee + expectedPerformanceFee
        );

        // We will not burn the difference between the remaining buffer and shares it will take post profit to cover it
        uint256 toNotBurn = loss - strategy.convertToShares(loss);
        createAndCheckLoss(
            strategy,
            loss,
            secondExpectedProtocolFee,
            expectedPerformanceFee
        );

        // We should have burned the full buffer
        assertApproxEq(
            strategy.balanceOf(address(strategy)),
            toNotBurn,
            1,
            "!strat bal"
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        console.log("Current bal ", strategy.balanceOf(address(strategy)));
        checkStrategyTotals(
            strategy,
            newAmount - loss,
            newAmount - loss,
            0,
            newAmount -
                loss *
                2 +
                totalExpectedFees +
                secondExpectedSharesForFees
        );

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_lossProtocolFeesBuffer(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 10, 5_000));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set all fees to 0
        uint16 protocolFee = 100;
        setFees(protocolFee, 0);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (loss * 0) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        // Simulate an original profit of 2x the loss
        createAndCheckProfit(
            strategy,
            loss * 2,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + loss * 2,
            _amount + loss * 2,
            0,
            _amount + loss * 2
        );

        // Half way through we should have the full loss still as abuffer
        increaseTimeAndCheckBuffer(
            strategy,
            profitMaxUnlockTime / 2,
            (loss * 2 - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            strategy,
            _amount + loss * 2,
            _amount + loss * 2,
            0,
            _amount + loss * 2 - ((loss * 2 - totalExpectedFees) / 2)
        );

        uint256 newAmount = _amount + loss * 2;
        uint256 secondExpectedProtocolFee = getExpectedProtocolFee(
            newAmount,
            protocolFee
        );

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            secondExpectedProtocolFee + expectedPerformanceFee
        );

        createAndCheckLoss(
            strategy,
            loss,
            secondExpectedProtocolFee,
            expectedPerformanceFee
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        console.log("Current bal ", strategy.balanceOf(address(strategy)));
        checkStrategyTotals(
            strategy,
            newAmount - loss,
            newAmount - loss,
            0,
            newAmount -
                loss *
                2 +
                totalExpectedFees +
                secondExpectedSharesForFees
        );

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        uint256 balance = strategy.balanceOf(protocolFeeRecipient);
        vm.prank(protocolFeeRecipient);
        strategy.redeem(balance, protocolFeeRecipient, protocolFeeRecipient);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }
}

// TODO:
//      read the unlocking rate and time
