// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

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
        // set perf fee to 10% protcol fee to 100 bps
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

        // Adjust what the percormance fee expects to get when there is a protocol fee.
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

        checkStrategyTotals(
            strategy,
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees + secondExpectedSharesForFees
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
        // Adjust what the percormance fee expects to get when there is a protocol fee.
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

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            expectedPerformanceFee
        ) + strategy.convertToShares(expectedProtocolFee);

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
                strategy.previewWithdraw(
                    profit - (expectedProtocolFee + expectedPerformanceFee)
                ) +
                secondExpectedSharesForFees
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
            false // Dont check protocol fees with overall loss
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
            "!strat bal"
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

        uint256 secondExpectedSharesForFees = strategy.convertToShares(
            expectedProtocolFee + expectedPerformanceFee
        );

        createAndCheckLoss(
            strategy,
            loss,
            expectedProtocolFee,
            false // Dont check protocol fees with overall loss
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

        // Should be able to withdaw all right away
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
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 expectedProtocolFee = (expectedPerformanceFee * protocolFee) /
            MAX_BPS;
        expectedPerformanceFee -= expectedProtocolFee;

        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

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
}
