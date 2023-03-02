// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract ProfitLockingTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function createAndCheckProfit(
        uint256 profit,
        uint256 _protocolFees,
        uint256 _performanceFees
    ) public {
        uint256 startingAssets = strategy.totalAssets();
        asset.mint(address(strategy), profit);

        // Check the event matches the expected values
        vm.expectEmit(true, true, false, true, address(strategy));
        emit BaseLibrary.Reported(profit, 0, _performanceFees, _protocolFees);

        vm.prank(keeper);
        (uint256 _profit, uint256 _loss) = strategy.report();

        assertEq(profit, _profit, "profit reported wrong");
        assertEq(_loss, 0, "Reported loss");
        assertEq(
            strategy.totalAssets(),
            startingAssets + profit,
            "total assets wrong"
        );
    }

    function checkStrategyTotals(
        uint256 _totalAssets,
        uint256 _totalDebt,
        uint256 _totalIdle,
        uint256 _totalSupply
    ) public {
        assertEq(strategy.totalAssets(), _totalAssets, "!totalAssets");
        assertEq(strategy.totalDebt(), _totalDebt, "!totalDebt");
        assertEq(strategy.totalIdle(), _totalIdle, "!totalIdle");
        assertEq(_totalAssets, _totalDebt + _totalIdle, "!Added");
        // We give supply a buffer or 1 wei for rounding
        assertApproxEq(strategy.totalSupply(), _totalSupply, 1, "!supply");
    }

    function increaseTimeAndCheckBuffer(uint256 _time, uint256 _buffer) public {
        skip(_time);
        // We give a buffer or 1 wei for rounding
        assertApproxEq(
            strategy.balanceOf(address(strategy)),
            _buffer,
            1,
            "!Buffer"
        );
    }

    function setFees(uint16 _protocolFee, uint256 _performanceFee) public {
        mockFactory.setFee(_protocolFee);
        vm.prank(management);

        strategy.setPerformanceFee(_performanceFee);
    }

    function getExpectedProtocolFee(uint256 _amount, uint16 _fee)
        public
        returns (uint256)
    {
        uint256 timePassed = Math.min(
            block.timestamp - strategy.lastReport(),
            block.timestamp - mockFactory.lastChange()
        );
        return (_amount * _fee * timePassed) / MAX_BPS / 31536000;
    }

    function test_gain_NoFeesNoBuffer(
        address _address,
        uint256 _amount,
        uint256 _profitFactor
    ) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_profitFactor > 10 && _profitFactor < MAX_BPS);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set all fees to 0
        uint16 protocolFee = 0;
        uint256 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(_address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(profitMaxUnlockTime / 2, profit / 2);

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + (profit / 2)
        );

        increaseTimeAndCheckBuffer(profitMaxUnlockTime / 2, 0);

        assertRelApproxEq(
            strategy.pricePerShare(),
            wad + ((wad * _profitFactor) / MAX_BPS),
            MAX_BPS
        );

        checkStrategyTotals(_amount + profit, _amount + profit, 0, _amount);

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        checkStrategyTotals(0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainProtocolFee_NoPerformanceFeeNoBuffer(
        address _address,
        uint256 _amount,
        uint256 _profitFactor
    ) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_profitFactor > 10 && _profitFactor < MAX_BPS);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set protocol fee to 100 bps so there will always be fees charged over a 10 day period with minFuzzAmount
        uint16 protocolFee = 100;
        uint256 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(_address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        increaseTimeAndCheckBuffer(profitMaxUnlockTime / 2, 0);

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        checkStrategyTotals(
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

        checkStrategyTotals(0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainPerformanceFee_NoProtocolNoBuffer(
        address _address,
        uint256 _amount,
        uint256 _profitFactor
    ) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_profitFactor > 10 && _profitFactor < MAX_BPS);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set perf fee to 10%
        uint16 protocolFee = 0;
        uint256 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(_address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        increaseTimeAndCheckBuffer(profitMaxUnlockTime / 2, 0);

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        checkStrategyTotals(
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

        checkStrategyTotals(0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainProtocolFeePerformanceFee_NoBuffer(
        address _address,
        uint256 _amount,
        uint256 _profitFactor
    ) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_profitFactor > 10 && _profitFactor < MAX_BPS);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set perf fee to 10% protcol fee to 100 bps
        uint16 protocolFee = 100;
        uint256 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(_address, _amount);
        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit - ((profit - totalExpectedFees) / 2)
        );

        increaseTimeAndCheckBuffer(profitMaxUnlockTime / 2, 0);

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        checkStrategyTotals(
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

        checkStrategyTotals(0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainBuffer_noProtocolFeeNoPerformanceFee(
        address _address,
        uint256 _amount,
        uint256 _profitFactor
    ) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_profitFactor > 10 && _profitFactor < MAX_BPS);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set fees to 0
        uint16 protocolFee = 0;
        uint256 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(_address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;
        createAndCheckProfit(
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
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

        createAndCheckProfit(
            profit,
            secondExpectedProtocolFee,
            expectedPerformanceFee
        );

        //uint256 expectedLockedShares = strategy.convertToShares(
        //    profit - expectedPerformanceFee + secondExpectedProtocolFee
        //);
        
        checkStrategyTotals(
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount -
                ((profit - totalExpectedFees) / 2) +
                strategy.convertToShares(profit)
        );
        /*
        increaseTimeAndCheckBuffer(
            profitMaxUnlockTime / 2,
            expectedLockedShares / 2
        );

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        checkStrategyTotals(
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount - profit + totalExpectedFees + (expectedLockedShares / 2)
        );
        */
        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        checkStrategyTotals(newAmount + profit, newAmount + profit, 0, newAmount - profit + totalExpectedFees + secondExpectedProtocolFee + expectedPerformanceFee);

        vm.prank(_address);
        strategy.redeem(newAmount - profit, _address, _address);

        checkStrategyTotals(0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainProtocolFeeBuffer_noPerformanceFee(
        address _address,
        uint256 _amount,
        uint256 _profitFactor
    ) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_profitFactor > 10 && _profitFactor < MAX_BPS);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set fees
        uint16 protocolFee = 100;
        uint256 performanceFee = 0;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(_address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        createAndCheckProfit(
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
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

        uint256 secondShares = strategy.convertToShares(secondExpectedProtocolFee + expectedPerformanceFee);

        createAndCheckProfit(
            profit,
            secondExpectedProtocolFee,
            expectedPerformanceFee
        );

        checkStrategyTotals(
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount -
                ((profit - totalExpectedFees) / 2) +
                strategy.convertToShares(profit)
        );

        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        checkStrategyTotals(newAmount + profit, newAmount + profit, 0, newAmount - profit + totalExpectedFees + secondShares);

        vm.prank(_address);
        strategy.redeem(newAmount - profit, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalExpectedFees + secondShares
        );

        checkStrategyTotals(
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees + secondShares 
        );

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        uint256 balance = strategy.balanceOf(protocolFeeRecipient);
        vm.prank(protocolFeeRecipient);
        strategy.redeem(
            balance,
            protocolFeeRecipient,
            protocolFeeRecipient
        );

        checkStrategyTotals(0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainPerformanceFeeBuffer_noProtocolFee(
        address _address,
        uint256 _amount,
        uint256 _profitFactor
    ) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_profitFactor > 10 && _profitFactor < MAX_BPS);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set fees
        uint16 protocolFee = 0;
        uint256 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(_address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        createAndCheckProfit(
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
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

        uint256 secondShares = strategy.convertToShares(secondExpectedProtocolFee + expectedPerformanceFee);

        createAndCheckProfit(
            profit,
            secondExpectedProtocolFee,
            expectedPerformanceFee
        );

        checkStrategyTotals(
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount -
                ((profit - totalExpectedFees) / 2) +
                strategy.convertToShares(profit)
        );

        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        checkStrategyTotals(newAmount + profit, newAmount + profit, 0, newAmount - profit + totalExpectedFees + secondShares);

        vm.prank(_address);
        strategy.redeem(newAmount - profit, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalExpectedFees + secondShares
        );

        checkStrategyTotals(
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees + secondShares 
        );

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        uint256 balance = strategy.balanceOf(performanceFeeRecipient);
        vm.prank(performanceFeeRecipient);
        strategy.redeem(
            balance,
            performanceFeeRecipient,
            performanceFeeRecipient
        );

        checkStrategyTotals(0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    function test_gainProtocolFeePerformanceFeeBuffer(
        address _address,
        uint256 _amount,
        uint256 _profitFactor
    ) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_profitFactor > 10 && _profitFactor < MAX_BPS);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        // set fees
        uint16 protocolFee = 100;
        uint256 performanceFee = 1_000;
        setFees(protocolFee, performanceFee);
        mintAndDepositIntoStrategy(_address, _amount);

        // Increase time to simulate interest being earned
        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedProtocolFee = getExpectedProtocolFee(
            _amount,
            protocolFee
        );
        uint256 expectedPerformanceFee = (profit * performanceFee) / MAX_BPS;
        uint256 totalExpectedFees = expectedPerformanceFee +
            expectedProtocolFee;

        createAndCheckProfit(
            profit,
            expectedProtocolFee,
            expectedPerformanceFee
        );

        assertEq(strategy.pricePerShare(), wad, "!pps");

        checkStrategyTotals(
            _amount + profit,
            _amount + profit,
            0,
            _amount + profit
        );

        increaseTimeAndCheckBuffer(
            profitMaxUnlockTime / 2,
            (profit - totalExpectedFees) / 2
        );

        checkStrategyTotals(
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

        uint256 secondShares = strategy.convertToShares(secondExpectedProtocolFee + expectedPerformanceFee);

        createAndCheckProfit(
            profit,
            secondExpectedProtocolFee,
            expectedPerformanceFee
        );

        checkStrategyTotals(
            newAmount + profit,
            newAmount + profit,
            0,
            newAmount -
                ((profit - totalExpectedFees) / 2) +
                strategy.convertToShares(profit)
        );

        increaseTimeAndCheckBuffer(profitMaxUnlockTime, 0);

        checkStrategyTotals(newAmount + profit, newAmount + profit, 0, newAmount - profit + totalExpectedFees + secondShares);

        vm.prank(_address);
        strategy.redeem(newAmount - profit, _address, _address);

        uint256 expectedAssetsForFees = strategy.convertToAssets(
            totalExpectedFees + secondShares
        );

        checkStrategyTotals(
            expectedAssetsForFees,
            expectedAssetsForFees,
            0,
            totalExpectedFees + secondShares 
        );

        assertGt(strategy.pricePerShare(), wad, "pps decreased");

        uint256 balance = strategy.balanceOf(protocolFeeRecipient);
        vm.prank(protocolFeeRecipient);
        strategy.redeem(
            balance,
            protocolFeeRecipient,
            protocolFeeRecipient
        );

        balance = strategy.balanceOf(performanceFeeRecipient);
        vm.prank(performanceFeeRecipient);
        strategy.redeem(
            balance,
            performanceFeeRecipient,
            performanceFeeRecipient
        );

        checkStrategyTotals(0, 0, 0, 0);

        assertEq(strategy.pricePerShare(), wad, "pps reset");
    }

    // TODO:
    // gain prot no perf no buffer x
    // gain prot perf fee no buffer X
    // gain no prot no perf fee buffer X
    // gain prot no perf buffer X
    // gain prot perf buffer X
    // all for loss
    // all for no gain or loss
}
