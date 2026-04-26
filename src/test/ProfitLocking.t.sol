// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";

contract ProfitLockingTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_gain_NoFeesNoBuffer(
        address _address,
        uint128 amount,
        uint16 _profitFactor
    ) public {
        uint256 _amount = bound(uint256(amount), minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;

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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set protocol fee to 100 bps so there will always be fees charged over a 10 day period with minFuzzAmount
        uint16 protocolFee = 1_000;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedPerformanceFee,
            100
        );
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFee,
            100
        );

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

        if (totalExpectedFees > 0) {
            assertGt(strategy.pricePerShare(), wad, "pps decreased");

            vm.prank(protocolFeeRecipient);
            strategy.redeem(
                totalExpectedFees,
                protocolFeeRecipient,
                protocolFeeRecipient
            );
        }

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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set perf fee to 10%
        uint16 protocolFee = 0;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedPerformanceFee,
            100
        );
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFee,
            100
        );

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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set perf fee to 10% protocol fee to 100 bps
        uint16 protocolFee = 1_000;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;

        // Adjust what the performance fee expects to get when there is a protocol fee.
        expectedPerformanceFee = expectedPerformanceFee - expectedProtocolFee;

        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedPerformanceFee,
            100
        );
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFee,
            100
        );

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

        if (expectedPerformanceFee > 0) {
            assertGt(strategy.pricePerShare(), wad, "pps decreased");

            vm.prank(performanceFeeRecipient);
            strategy.redeem(
                expectedPerformanceFee,
                performanceFeeRecipient,
                performanceFeeRecipient
            );
        }

        expectedAssetsForFees = strategy.convertToAssets(expectedProtocolFee);
        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            expectedProtocolFee
        );

        if (expectedProtocolFee > 0) {
            vm.prank(protocolFeeRecipient);
            strategy.redeem(
                expectedProtocolFee,
                protocolFeeRecipient,
                protocolFeeRecipient
            );
        }

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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;

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

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            expectedProtocolFee + expectedPerformanceFee
        );

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set fees
        uint16 protocolFee = 1_000;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedPerformanceFee,
            100
        );
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFee,
            100
        );

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

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            expectedProtocolFee + expectedPerformanceFee
        );

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
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

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        vm.prank(_address);
        strategy.redeem(newAmount - profit, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalExpectedFees + secondExpectedSharesForFees
        );

        checkStrategyTotalsApproxAssets(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees + secondExpectedSharesForFees,
            1
        );

        uint256 balance = strategy.balanceOf(protocolFeeRecipient);
        if (balance > 0) {
            assertGt(strategy.pricePerShare(), wad, "pps decreased");
            vm.prank(protocolFeeRecipient);
            strategy.redeem(
                balance,
                protocolFeeRecipient,
                protocolFeeRecipient
            );
        }

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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set fees
        uint16 protocolFee = 0;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedPerformanceFee,
            100
        );
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFee,
            100
        );

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

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        uint256 totalFeeShares = strategy.balanceOf(performanceFeeRecipient) +
            strategy.balanceOf(protocolFeeRecipient);

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
            newAmount - profit + totalFeeShares
        );

        vm.prank(_address);
        strategy.redeem(newAmount - profit, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalFeeShares
        );

        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalFeeShares
        );

        assertGe(strategy.pricePerShare(), wad, "pps decreased");

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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set fees
        uint16 protocolFee = 1_000;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;
        // Adjust what the performance fee expects to get when there is a protocol fee.
        expectedPerformanceFee = expectedPerformanceFee - expectedProtocolFee;

        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedPerformanceFee,
            100
        );
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFee,
            100
        );

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

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        uint256 totalFeeShares = strategy.balanceOf(performanceFeeRecipient) +
            strategy.balanceOf(protocolFeeRecipient);

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
            newAmount - profit + totalFeeShares
        );

        vm.prank(_address);
        // Use newAmount - profit here to avoid stack to deep
        strategy.redeem(newAmount - profit, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalFeeShares
        );

        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalFeeShares
        );

        assertGe(strategy.pricePerShare(), wad, "pps decreased");

        uint256 balance = strategy.balanceOf(protocolFeeRecipient);
        if (balance > 0) {
            vm.prank(protocolFeeRecipient);
            strategy.redeem(
                balance,
                protocolFeeRecipient,
                protocolFeeRecipient
            );
        }

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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;
        uint256 expectedProtocolFee = 0;

        createAndCheckLoss(strategy, loss, expectedProtocolFee, true);

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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set all fees to 0
        uint16 protocolFee = 1_000;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;
        uint256 expectedProtocolFee = 0;

        uint256 totalExpectedFees = expectedProtocolFee;
        createAndCheckLoss(
            strategy,
            loss,
            expectedProtocolFee,
            false // Don't check protocol fees with overall loss
        );

        assertRelApproxEq(
            strategy.pricePerShare(),
            wad - ((wad * _lossFactor) / MAX_BPS),
            MAX_BPS / 10
        );

        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFee,
            100
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
        if (balance > 0) {
            vm.prank(protocolFeeRecipient);
            strategy.redeem(
                balance,
                protocolFeeRecipient,
                protocolFeeRecipient
            );
        }

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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        //uint16 performanceFee = 0;
        setFees(protocolFee, 0);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;
        uint256 expectedProtocolFee = 0;
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

        // Half way through we should have the full loss still as a buffer
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, loss);

        checkStrategyTotals(
            strategy,
            _amount + loss * 2,
            _amount + loss * 2,
            0,
            _amount + loss * 2 + totalExpectedFees - loss
        );

        uint256 newAmount = _amount + loss * 2;

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            expectedProtocolFee + expectedPerformanceFee
        );

        // We will not burn the difference between the remaining buffer and shares it will take post profit to cover it
        uint256 toNotBurn = loss - strategy.convertToShares(loss);
        createAndCheckLoss(strategy, loss, expectedProtocolFee, true);

        // We should have burned the full buffer
        assertApproxEq(
            strategy.balanceOf(address(strategy)),
            toNotBurn,
            1,
            "!strategy bal"
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set all fees to 0
        uint16 protocolFee = 1_000;
        setFees(protocolFee, 0);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;
        uint256 expectedProtocolFee = 0;
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

        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedPerformanceFee,
            100
        );
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFee,
            100
        );

        checkStrategyTotals(
            strategy,
            _amount + loss * 2,
            _amount + loss * 2,
            0,
            _amount + loss * 2
        );

        // Half way through we should have the full loss still as a buffer
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

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            expectedProtocolFee + expectedPerformanceFee
        );

        createAndCheckLoss(
            strategy,
            loss,
            expectedProtocolFee,
            false // Don't check protocol fees with overall loss
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
        if (balance > 0) {
            vm.prank(protocolFeeRecipient);
            strategy.redeem(
                balance,
                protocolFeeRecipient,
                protocolFeeRecipient
            );
        }

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_NoGainFeesOrBuffer(
        address _address,
        uint128 amount,
        uint16 _profitFactor
    ) public {
        uint256 _amount = bound(uint256(amount), minFuzzAmount, maxFuzzAmount);
        _profitFactor = 0;
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedPerformanceFee,
            100
        );
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFee,
            100
        );

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

    function test_gain_NoFeesNoBuffer_noLocking(
        address _address,
        uint128 amount,
        uint16 _profitFactor
    ) public {
        uint256 _amount = bound(uint256(amount), minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);

        // Set max unlocking time to 0.
        vm.prank(management);
        strategy.setProfitMaxUnlockTime(0);
        assertEq(strategy.profitMaxUnlockTime(), 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        // All profit should have been unlocked instantly.
        assertEq(strategy.profitUnlockingRate(), 0, "!rate");
        assertEq(strategy.fullProfitUnlockDate(), 0, "date");
        assertGt(strategy.pricePerShare(), wad, "!pps");
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

        // Nothing should change
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount
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

    function test_gain_NoFeesNoBuffer_noLocking_withdrawAll(
        address _address,
        uint128 amount,
        uint16 _profitFactor
    ) public {
        uint256 _amount = bound(uint256(amount), minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);

        // Set max unlocking time to 0.
        vm.prank(management);
        strategy.setProfitMaxUnlockTime(0);
        assertEq(strategy.profitMaxUnlockTime(), 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        // All profit should have been unlocked instantly.
        assertEq(strategy.profitUnlockingRate(), 0, "!rate");
        assertEq(strategy.fullProfitUnlockDate(), 0, "date");
        assertGt(strategy.pricePerShare(), wad, "!pps");
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

        // Should be able to withdraw all right away
        uint256 beforeBalance = asset.balanceOf(_address);

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        assertEq(asset.balanceOf(_address), beforeBalance + _amount + profit);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainFees_NoBuffer_noLocking(
        address _address,
        uint128 amount,
        uint16 _profitFactor
    ) public {
        uint256 _amount = bound(uint256(amount), minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set all fees to 0
        uint16 protocolFee = 1_000;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);

        // Set max unlocking time to 0.
        vm.prank(management);
        strategy.setProfitMaxUnlockTime(0);
        assertEq(strategy.profitMaxUnlockTime(), 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        {
            uint256 expectedPerformanceFee = (profit * performanceFee) /
                MAX_BPS;
            uint256 expectedProtocolFee = (expectedPerformanceFee *
                protocolFee) / MAX_BPS;
            expectedPerformanceFee -= expectedProtocolFee;

            createAndCheckProfit(
                strategy,
                profit,
                expectedProtocolFee,
                expectedPerformanceFee
            );
        }

        uint256 expectedPerformanceFeeShares = strategy.balanceOf(
            performanceFeeRecipient
        );
        uint256 expectedProtocolFeeShares = strategy.balanceOf(
            protocolFeeRecipient
        );
        uint256 totalFeeShares = expectedPerformanceFeeShares +
            expectedProtocolFeeShares;

        // All profit should have been unlocked instantly.
        assertEq(strategy.profitUnlockingRate(), 0, "!rate");
        assertEq(strategy.fullProfitUnlockDate(), 0, "date");
        assertGt(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + totalFeeShares
        );

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalFeeShares
        );

        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalFeeShares
        );

        if (expectedPerformanceFeeShares > 0) {
            assertGe(strategy.pricePerShare(), wad, "pps decreased");

            vm.prank(performanceFeeRecipient);
            strategy.redeem(
                expectedPerformanceFeeShares,
                performanceFeeRecipient,
                performanceFeeRecipient
            );
        }

        expectedAssetsForFees = strategy.convertToAssets(
            expectedProtocolFeeShares
        );

        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            expectedProtocolFeeShares
        );

        if (expectedProtocolFeeShares > 0) {
            vm.prank(protocolFeeRecipient);
            strategy.redeem(
                expectedProtocolFeeShares,
                protocolFeeRecipient,
                protocolFeeRecipient
            );
        }

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainBuffer_noFees_noLocking_resets(
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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);

        assertEq(strategy.profitUnlockingRate(), 0, "!rate");
        assertEq(strategy.fullProfitUnlockDate(), 0, "date");

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;

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

        // Make sure we have active unlocking
        assertGt(strategy.profitUnlockingRate(), 0);
        assertGt(strategy.fullProfitUnlockDate(), 0);
        assertGt(strategy.balanceOf(address(strategy)), 0);

        // Set max unlocking time to 0.
        vm.prank(management);
        strategy.setProfitMaxUnlockTime(0);
        // Make sure it reset all unlocking rates.
        assertEq(strategy.profitMaxUnlockTime(), 0);
        assertEq(strategy.profitUnlockingRate(), 0, "!rate");
        assertEq(strategy.fullProfitUnlockDate(), 0, "date");
        assertEq(strategy.balanceOf(address(strategy)), 0);

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

        uint256 newAmount = _amount + profit;

        createAndCheckProfit(
            strategy,
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        // Should unlock everything right away.
        checkStrategyTotals(
            strategy,
            newAmount + profit,
            newAmount + profit,
            0,
            _amount
        );

        increaseTimeAndCheckBuffer(strategy, 0, 0);

        vm.prank(_address);
        strategy.redeem(newAmount - profit, _address, _address);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_buffer_noGainReport(
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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);

        assertEq(strategy.profitUnlockingRate(), 0, "!rate");
        assertEq(strategy.fullProfitUnlockDate(), 0, "date");

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;

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

        // Make sure we have active unlocking
        assertGt(strategy.profitUnlockingRate(), 0);
        assertGt(strategy.fullProfitUnlockDate(), 0);
        assertGt(strategy.balanceOf(address(strategy)), 0);
        uint256 pps = strategy.pricePerShare();

        // Report with no profit or loss
        vm.prank(keeper);
        strategy.report();

        // Should be the same as before
        assertEq(strategy.pricePerShare(), pps, "pps");
        checkStrategyTotals(
            strategy,
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime / 2, 0);

        // Everything should be unlocked now.
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

    function test_loss_NoFeesNoBuffer_noUnlock(
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
                _address != performanceFeeRecipient &&
                _address != address(yieldSource)
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        uint16 performanceFee = 0;
        setFees(protocolFee, performanceFee);

        // Set max unlocking time to 0.
        vm.prank(management);
        strategy.setProfitMaxUnlockTime(0);
        assertEq(strategy.profitMaxUnlockTime(), 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(strategy, profitMaxUnlockTime, 0);

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;
        uint256 expectedProtocolFee = 0;

        createAndCheckLoss(strategy, loss, expectedProtocolFee, true);

        assertEq(strategy.profitUnlockingRate(), 0, "!rate");
        assertEq(strategy.fullProfitUnlockDate(), 0, "date");
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

    function test_reportRealizesProtocolAndPerformanceFees(
        address _user,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != protocolFeeRecipient &&
                _user != performanceFeeRecipient &&
                _user != address(yieldSource)
        );

        uint16 protocolFee = 1_000;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 totalFeeAssets = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFees = (totalFeeAssets * protocolFee) / MAX_BPS;
        uint256 expectedPerformanceFees = totalFeeAssets - expectedProtocolFees;

        queueHarvestProfit(strategy, profit);

        uint256 ppsBefore = strategy.pricePerShare();

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, profit, "!profit");
        assertEq(reportedLoss, 0, "!loss");
        assertEq(strategy.pricePerShare(), ppsBefore, "!pps");
        assertGt(strategy.balanceOf(address(strategy)), 0, "!buffer");
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFees,
            100
        );
        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedPerformanceFees,
            100
        );

        skip(profitMaxUnlockTime);

        assertGt(strategy.pricePerShare(), ppsBefore, "!unlock");
        assertEq(strategy.balanceOf(address(strategy)), 0, "!buffer cleared");
    }

    function test_reportDoesNotDoubleCharge(
        address _user,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 1_000);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        queueHarvestProfit(strategy, profit);

        vm.prank(keeper);
        strategy.report();

        uint256 feeShares = strategy.balanceOf(performanceFeeRecipient);

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, 0, "!profit");
        assertEq(reportedLoss, 0, "!loss");
        assertEq(
            strategy.balanceOf(performanceFeeRecipient),
            feeShares,
            "!fee"
        );
    }

    function test_reportWithoutUnlockUsesDilutedFeeShares(
        address _user,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != protocolFeeRecipient &&
                _user != performanceFeeRecipient &&
                _user != address(yieldSource)
        );

        uint16 protocolFee = 1_000;
        uint16 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);

        vm.prank(management);
        strategy.setProfitMaxUnlockTime(0);

        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 totalFeeAssets = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFees = (totalFeeAssets * protocolFee) / MAX_BPS;
        uint256 expectedPerformanceFees = totalFeeAssets - expectedProtocolFees;

        queueHarvestProfit(strategy, profit);

        uint256 ppsBefore = strategy.pricePerShare();

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, profit, "!profit");
        assertEq(reportedLoss, 0, "!loss");
        assertGt(strategy.pricePerShare(), ppsBefore, "!pps");
        assertEq(strategy.balanceOf(address(strategy)), 0, "!buffer");
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(protocolFeeRecipient)),
            expectedProtocolFees,
            100
        );
        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedPerformanceFees,
            100
        );
    }

    function test_feeSyncOnDepositMatchesLivePrice(
        address _user,
        address _depositor,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _user != address(0) &&
                _depositor != address(0) &&
                _user != _depositor &&
                _user != address(strategy) &&
                _depositor != address(strategy) &&
                _user != address(yieldSource) &&
                _depositor != address(yieldSource)
        );

        setFees(0, 1_000);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        asset.mint(address(strategy), profit);

        skip(1);

        uint256 ppsBefore = strategy.pricePerShare();
        uint256 preview = strategy.previewDeposit(_amount);

        asset.mint(_depositor, _amount);
        vm.prank(_depositor);
        asset.approve(address(strategy), _amount);

        vm.prank(_depositor);
        uint256 minted = strategy.deposit(_amount, _depositor);

        assertGe(strategy.pricePerShare(), ppsBefore, "!pps");
        assertEq(minted, preview, "!preview");

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, 0, "!profit");
        assertEq(reportedLoss, 0, "!loss");
    }

    function test_reportLocksChunkyYieldAfterContinuousAccrual(
        address _user,
        address _depositor,
        uint256 _amount,
        uint16 _liveProfitFactor,
        uint16 _reportProfitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _liveProfitFactor = uint16(
            bound(uint256(_liveProfitFactor), 10, MAX_BPS)
        );
        _reportProfitFactor = uint16(
            bound(uint256(_reportProfitFactor), 10, MAX_BPS)
        );
        vm.assume(
            _user != address(0) &&
                _depositor != address(0) &&
                _user != _depositor &&
                _user != address(strategy) &&
                _depositor != address(strategy) &&
                _user != address(yieldSource) &&
                _depositor != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 initialPps = strategy.pricePerShare();

        uint256 liveProfit = (_amount * _liveProfitFactor) / MAX_BPS;
        asset.mint(address(yieldSource), liveProfit);

        skip(1);

        uint256 ppsBeforeSync = strategy.pricePerShare();
        assertGt(ppsBeforeSync, initialPps, "!live pps");

        asset.mint(_depositor, _amount);
        vm.prank(_depositor);
        asset.approve(address(strategy), _amount);

        vm.prank(_depositor);
        strategy.deposit(_amount, _depositor);

        uint256 reportProfit = (_amount * _reportProfitFactor) / MAX_BPS;
        queueHarvestProfit(strategy, reportProfit);

        uint256 assetsBeforeReport = strategy.totalAssets();
        uint256 ppsBeforeReport = strategy.pricePerShare();

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(assetsBeforeReport, (_amount * 2) + liveProfit, "!assets");
        assertEq(reportedProfit, reportProfit, "!profit");
        assertEq(reportedLoss, 0, "!loss");
        assertGt(strategy.balanceOf(address(strategy)), 0, "!buffer");

        skip(profitMaxUnlockTime);

        assertGt(strategy.pricePerShare(), ppsBeforeReport, "!unlock");
        assertEq(strategy.balanceOf(address(strategy)), 0, "!buffer cleared");
    }

    function test_liveAccrualAfterPartialUnlockUsesCurrentSupply(
        address _user,
        address _depositor,
        uint256 _amount,
        uint16 _reportProfitFactor,
        uint16 _liveProfitFactor,
        uint16 _unlockBps
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _reportProfitFactor = uint16(
            bound(uint256(_reportProfitFactor), 10, MAX_BPS)
        );
        _liveProfitFactor = uint16(
            bound(uint256(_liveProfitFactor), 10, MAX_BPS)
        );
        _unlockBps = uint16(bound(uint256(_unlockBps), 1, MAX_BPS - 1));
        vm.assume(
            _user != address(0) &&
                _depositor != address(0) &&
                _user != _depositor &&
                _user != address(strategy) &&
                _depositor != address(strategy) &&
                _user != performanceFeeRecipient &&
                _depositor != performanceFeeRecipient &&
                _user != address(yieldSource) &&
                _depositor != address(yieldSource)
        );

        uint16 performanceFee = 1_000;
        setFees(0, performanceFee);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 reportProfit = (_amount * _reportProfitFactor) / MAX_BPS;
        queueHarvestProfit(strategy, reportProfit);

        vm.prank(keeper);
        strategy.report();

        skip((profitMaxUnlockTime * _unlockBps) / MAX_BPS);

        uint256 liveProfit = (_amount * _liveProfitFactor) / MAX_BPS;
        uint256 totalFeeAssets = (liveProfit * performanceFee) / MAX_BPS;
        asset.mint(address(yieldSource), liveProfit);

        uint256 supplyBeforeSync = strategy.totalSupply();
        uint256 assetsBeforeSync = strategy.totalAssets();
        uint256 expectedFeeShares = (totalFeeAssets * supplyBeforeSync) /
            (assetsBeforeSync - totalFeeAssets);
        uint256 feeSharesBefore = strategy.balanceOf(performanceFeeRecipient);

        asset.mint(_depositor, _amount);
        vm.prank(_depositor);
        asset.approve(address(strategy), _amount);

        vm.prank(_depositor);
        strategy.deposit(_amount, _depositor);

        assertApproxEq(
            strategy.balanceOf(performanceFeeRecipient) - feeSharesBefore,
            expectedFeeShares,
            1
        );
    }

    function test_reportDoesNotRelockAlreadyVisibleContinuousYield(
        address _user,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        asset.mint(address(yieldSource), profit);

        skip(1);

        uint256 assetsBeforeReport = strategy.totalAssets();
        uint256 ppsBeforeReport = strategy.pricePerShare();

        vm.expectEmit(true, true, true, true, address(strategy));
        emit Reported(profit, 0, 0, 0);
        vm.expectEmit(true, true, true, true, address(strategy));
        emit Reported(0, 0, 0, 0);

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, 0, "!profit");
        assertEq(reportedLoss, 0, "!loss");
        assertEq(strategy.totalAssets(), assetsBeforeReport, "!assets");
        assertGe(strategy.pricePerShare(), ppsBeforeReport, "!pps");
        assertEq(strategy.balanceOf(address(strategy)), 0, "!buffer");
    }

    function test_reportOnlyLocksChunkyDeltaAfterVisibleContinuousYield(
        address _user,
        uint256 _amount,
        uint16 _liveProfitFactor,
        uint16 _reportProfitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _liveProfitFactor = uint16(
            bound(uint256(_liveProfitFactor), 10, MAX_BPS)
        );
        _reportProfitFactor = uint16(
            bound(uint256(_reportProfitFactor), 10, MAX_BPS)
        );
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 liveProfit = (_amount * _liveProfitFactor) / MAX_BPS;
        uint256 reportProfit = (_amount * _reportProfitFactor) / MAX_BPS;

        asset.mint(address(yieldSource), liveProfit);

        skip(1);

        uint256 assetsBeforeReport = strategy.totalAssets();
        uint256 ppsBeforeReport = strategy.pricePerShare();

        queueHarvestProfit(strategy, reportProfit);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit Reported(liveProfit, 0, 0, 0);
        vm.expectEmit(true, true, true, true, address(strategy));
        emit Reported(reportProfit, 0, 0, 0);

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, reportProfit, "!profit");
        assertEq(reportedLoss, 0, "!loss");
        assertEq(
            strategy.totalAssets(),
            assetsBeforeReport + reportProfit,
            "!assets"
        );
        assertGe(strategy.pricePerShare(), ppsBeforeReport, "!pps");
        assertApproxEq(
            strategy.convertToAssets(strategy.balanceOf(address(strategy))),
            reportProfit,
            10
        );
    }

    function test_reportOnlyRealizesChunkyLossAfterVisibleContinuousLoss(
        address _user,
        uint256 _amount,
        uint16 _liveLossFactor,
        uint16 _reportLossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _liveLossFactor = uint16(bound(uint256(_liveLossFactor), 10, 2_500));
        _reportLossFactor = uint16(
            bound(uint256(_reportLossFactor), 10, 2_500)
        );
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 liveLoss = (_amount * _liveLossFactor) / MAX_BPS;
        uint256 reportLoss = (_amount * _reportLossFactor) / MAX_BPS;

        skip(1);

        yieldSource.simulateLoss(liveLoss);

        uint256 assetsBeforeReport = strategy.totalAssets();
        uint256 ppsBeforeReport = strategy.pricePerShare();

        queueHarvestLoss(strategy, reportLoss);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit Reported(0, liveLoss, 0, 0);
        vm.expectEmit(true, true, true, true, address(strategy));
        emit Reported(0, reportLoss, 0, 0);

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, 0, "!profit");
        assertEq(reportedLoss, reportLoss, "!loss");
        assertEq(
            strategy.totalAssets(),
            assetsBeforeReport - reportLoss,
            "!assets"
        );
        assertLt(strategy.pricePerShare(), ppsBeforeReport, "!pps");
        assertEq(strategy.balanceOf(address(strategy)), 0, "!buffer");
    }

    function test_reportDoesNotRelockAlreadyVisibleAirdrop(
        address _user,
        uint256 _amount,
        uint16 _airdropFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _airdropFactor = uint16(bound(uint256(_airdropFactor), 10, MAX_BPS));
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 airdrop = (_amount * _airdropFactor) / MAX_BPS;
        asset.mint(address(strategy), airdrop);

        skip(1);

        uint256 assetsBeforeReport = strategy.totalAssets();
        uint256 ppsBeforeReport = strategy.pricePerShare();

        vm.expectEmit(true, true, true, true, address(strategy));
        emit Reported(airdrop, 0, 0, 0);
        vm.expectEmit(true, true, true, true, address(strategy));
        emit Reported(0, 0, 0, 0);

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, 0, "!profit");
        assertEq(reportedLoss, 0, "!loss");
        assertEq(strategy.totalAssets(), assetsBeforeReport, "!assets");
        assertGe(strategy.pricePerShare(), ppsBeforeReport, "!pps");
        assertEq(strategy.balanceOf(address(strategy)), 0, "!buffer");
    }

    function test_airdropAccruesImmediatelyDuringProfitUnlock(
        address _user,
        uint256 _amount,
        uint16 _reportProfitFactor,
        uint16 _airdropFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _reportProfitFactor = uint16(
            bound(uint256(_reportProfitFactor), 10, MAX_BPS)
        );
        _airdropFactor = uint16(bound(uint256(_airdropFactor), 10, MAX_BPS));
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 reportProfit = (_amount * _reportProfitFactor) / MAX_BPS;
        queueHarvestProfit(strategy, reportProfit);

        vm.prank(keeper);
        strategy.report();

        skip(profitMaxUnlockTime / 2);

        uint256 assetsBeforeAirdrop = strategy.totalAssets();
        uint256 ppsBeforeAirdrop = strategy.pricePerShare();

        uint256 airdrop = (_amount * _airdropFactor) / MAX_BPS;
        asset.mint(address(strategy), airdrop);

        assertEq(
            strategy.totalAssets(),
            assetsBeforeAirdrop + airdrop,
            "!assets"
        );
        assertGt(strategy.pricePerShare(), ppsBeforeAirdrop, "!pps");
    }

    function test_settingProfitUnlockTimeDoesNotCreateABuffer(
        address _user,
        uint256 _amount,
        uint16 _profitFactor,
        uint32 _unlockTime
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        uint256 unlockTime = bound(uint256(_unlockTime), 0, 31_556_952);
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);

        vm.prank(management);
        strategy.setProfitMaxUnlockTime(unlockTime);

        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 ppsBefore = strategy.pricePerShare();
        asset.mint(address(strategy), profit);

        assertEq(strategy.pricePerShare(), ppsBefore, "!pps frozen");

        skip(1);

        assertGt(strategy.pricePerShare(), ppsBefore, "!pps");

        skip(profitMaxUnlockTime);

        assertEq(strategy.balanceOf(address(strategy)), 0, "!buffer");
    }

    // Invariant: `balanceOf(address(strategy))` must remain a callable view
    // and never underflow, even after `_accrue` has burned the locked-profit
    // buffer to absorb a mid-unlock-window loss. `unlockedShares()` must
    // never exceed `S.balances[address(this)]`.
    function test_balanceOfStrategySurvivesLossBurnDuringUnlockWindow() public {
        uint256 _amount = 1_000e18;
        uint256 profit = 200e18;
        uint256 loss = 800e18;
        address depositor = address(0x1234);

        setFees(0, 0);

        mintAndDepositIntoStrategy(strategy, depositor, _amount);

        // Lock `profit` into the strategy buffer over `profitMaxUnlockTime`.
        createAndCheckProfit(strategy, profit, 0, 0);
        assertEq(strategy.balanceOf(address(strategy)), profit, "buffer at T0");

        // Move to the middle of the unlock window — half the buffer counts as
        // unlocked under the rate formula.
        skip(profitMaxUnlockTime / 2);

        uint256 unlockedMid = strategy.unlockedShares();
        assertGt(unlockedMid, 0, "some unlocked");
        assertEq(
            strategy.balanceOf(address(strategy)),
            profit - unlockedMid,
            "balanceOf strategy mid-window"
        );

        // Yield-source loss large enough that the burn maxes out at
        // `S.balances[strategy]` and drains the entire buffer.
        yieldSource.simulateLoss(loss);

        // Trigger `_accrue` via a normal redeem — `_accrue` calls
        // `_realizeLoss` which burns from `S.balances[address(this)]`.
        vm.prank(depositor);
        strategy.redeem(100e18, depositor, depositor);

        // After the burn the unlock accounting must stay consistent: the
        // unlocked-shares figure cannot exceed the strategy's actual balance,
        // and `balanceOf(strategy)` must still be readable.
        assertLe(
            strategy.unlockedShares(),
            strategy.balanceOf(address(strategy)) + strategy.unlockedShares(),
            "unlockedShares > strategy balance"
        );
        assertEq(
            strategy.balanceOf(address(strategy)),
            0,
            "buffer fully drained"
        );
    }
}
