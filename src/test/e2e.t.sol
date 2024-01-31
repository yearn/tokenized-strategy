// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {Setup, ERC20Mock, MockYieldSource, IMockStrategy} from "./utils/Setup.sol";

contract e2eTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    struct StrategyInfo {
        ERC20Mock _asset;
        IMockStrategy strat;
        uint256 toDeposit;
        uint256 profit;
    }

    StrategyInfo[] public strategies;

    function test_multipleStrategiesAndTokens_depositAndRedeem(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _address != address(0) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

        setFees(0, 0);

        // Pick a random amount of strategies to add between 5-10
        uint256 toMake = (_amount % 6) + 5;
        uint256 i;

        for (i; i < toMake; ++i) {
            asset = new ERC20Mock();
            yieldSource = new MockYieldSource(address(asset));
            IMockStrategy newStrategy = IMockStrategy(setUpStrategy());

            vm.assume(
                _address != address(asset) &&
                    _address != address(yieldSource) &&
                    _address != address(newStrategy)
            );

            setPerformanceFeeToZero(address(newStrategy));

            // Deposit a unique amount for each one
            uint256 toDeposit = _amount + i;

            mintAndDepositIntoStrategy(newStrategy, _address, toDeposit);

            checkStrategyTotals(
                newStrategy,
                toDeposit,
                toDeposit,
                0,
                toDeposit
            );

            strategies.push(StrategyInfo(asset, newStrategy, toDeposit, 0));
        }

        i = 0;

        for (i; i < toMake; ++i) {
            uint256 profit = (strategies[i].toDeposit * _profitFactor) /
                MAX_BPS +
                1;

            // Set the global asset for this specific strategy
            asset = strategies[i]._asset;

            createAndCheckProfit(strategies[i].strat, profit, 0, 0);

            strategies[i].profit = profit;
        }

        skip(10 days);

        i = 0;

        for (i; i < toMake; ++i) {
            StrategyInfo memory info = strategies[i];
            asset = info._asset;

            checkStrategyTotals(
                info.strat,
                info.toDeposit + info.profit,
                info.toDeposit + info.profit,
                0,
                info.toDeposit
            );

            uint256 before = asset.balanceOf(_address);

            vm.prank(_address);
            info.strat.redeem(info.toDeposit, _address, _address);

            assertEq(
                asset.balanceOf(_address) - before,
                info.toDeposit + info.profit
            );
            assertEq(info.strat.pricePerShare(), wad);

            checkStrategyTotals(info.strat, 0, 0, 0);
        }
    }

    function test_multipleStrategiesAndTokens_mintAndWithdraw(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient
        );
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

        setFees(0, 0);

        // Pick a random amount of strategies to add between 5-10
        uint256 toMake = (_amount % 6) + 5;
        uint256 i;

        for (i; i < toMake; ++i) {
            asset = new ERC20Mock();
            yieldSource = new MockYieldSource(address(asset));
            IMockStrategy newStrategy = IMockStrategy(setUpStrategy());

            vm.assume(
                _address != address(asset) &&
                    _address != address(yieldSource) &&
                    _address != address(newStrategy)
            );

            setPerformanceFeeToZero(address(newStrategy));

            // Deposit a unique amount for each one
            uint256 toDeposit = _amount + i;

            // Use mint instead of deposit
            asset.mint(_address, toDeposit);

            vm.prank(_address);
            asset.approve(address(newStrategy), toDeposit);

            vm.prank(_address);
            newStrategy.mint(toDeposit, _address);

            checkStrategyTotals(
                newStrategy,
                toDeposit,
                toDeposit,
                0,
                toDeposit
            );

            strategies.push(StrategyInfo(asset, newStrategy, toDeposit, 0));
        }

        i = 0;

        for (i; i < toMake; ++i) {
            uint256 profit = (strategies[i].toDeposit * _profitFactor) /
                MAX_BPS +
                1;

            // Set the global asset for this specific strategy
            asset = strategies[i]._asset;

            createAndCheckProfit(strategies[i].strat, profit, 0, 0);

            strategies[i].profit = profit;
        }

        skip(10 days);

        i = 0;

        for (i; i < toMake; ++i) {
            StrategyInfo memory info = strategies[i];
            asset = info._asset;

            checkStrategyTotals(
                info.strat,
                info.toDeposit + info.profit,
                info.toDeposit + info.profit,
                0,
                info.toDeposit
            );

            uint256 before = asset.balanceOf(_address);

            vm.prank(_address);
            info.strat.withdraw(
                info.toDeposit + info.profit,
                _address,
                _address
            );

            assertEq(
                asset.balanceOf(_address) - before,
                info.toDeposit + info.profit
            );
            assertEq(info.strat.pricePerShare(), wad);

            checkStrategyTotals(info.strat, 0, 0, 0);
        }
    }

    function test_multipleStrategiesTokensAndUsers(
        address _address,
        address _secondAddress,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != protocolFeeRecipient &&
                _address != performanceFeeRecipient &&
                _address != _secondAddress
        );
        vm.assume(
            _secondAddress != address(0) &&
                _secondAddress != address(strategy) &&
                _secondAddress != protocolFeeRecipient &&
                _secondAddress != performanceFeeRecipient
        );
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

        setFees(0, 0);

        // Pick a random amount of strategies to add between 5-10
        uint256 toMake = (_amount % 6) + 5;
        uint256 i;

        for (i; i < toMake; ++i) {
            asset = new ERC20Mock();
            yieldSource = new MockYieldSource(address(asset));
            IMockStrategy newStrategy = IMockStrategy(setUpStrategy());

            vm.assume(
                _address != address(asset) &&
                    _address != address(yieldSource) &&
                    _address != address(newStrategy)
            );
            vm.assume(
                _secondAddress != address(asset) &&
                    _secondAddress != address(yieldSource) &&
                    _secondAddress != address(newStrategy)
            );

            setPerformanceFeeToZero(address(newStrategy));

            // Deposit a unique amount for each one
            uint256 toDeposit = _amount + i;

            mintAndDepositIntoStrategy(newStrategy, _address, toDeposit);

            checkStrategyTotals(
                newStrategy,
                toDeposit,
                toDeposit,
                0,
                toDeposit
            );

            strategies.push(StrategyInfo(asset, newStrategy, toDeposit, 0));
        }

        i = 0;

        for (i; i < toMake; ++i) {
            uint256 profit = (strategies[i].toDeposit * _profitFactor) /
                MAX_BPS +
                1;

            // Set the global asset for this specific strategy
            asset = strategies[i]._asset;

            createAndCheckProfit(strategies[i].strat, profit, 0, 0);

            strategies[i].profit = profit;
        }

        skip(5 days);

        i = 0;

        // Do another deposit by a second address
        for (i; i < toMake; ++i) {
            StrategyInfo memory info = strategies[i];
            asset = info._asset;

            mintAndDepositIntoStrategy(
                info.strat,
                _secondAddress,
                info.toDeposit
            );

            checkStrategyTotals(
                info.strat,
                info.toDeposit * 2 + info.profit,
                info.toDeposit * 2 + info.profit,
                0
            );

            // make sure second address got less shares than first
            assertGt(
                info.strat.balanceOf(_address),
                info.strat.balanceOf(_secondAddress)
            );
        }

        skip(5 days);

        i = 0;

        for (i; i < toMake; ++i) {
            StrategyInfo memory info = strategies[i];
            asset = info._asset;

            checkStrategyTotals(
                info.strat,
                info.toDeposit * 2 + info.profit,
                info.toDeposit * 2 + info.profit,
                0
            );

            uint256 before = asset.balanceOf(_address);

            vm.prank(_address);
            info.strat.redeem(info.toDeposit, _address, _address);

            assertGt(asset.balanceOf(_address) - before, info.toDeposit);

            before = asset.balanceOf(_secondAddress);
            uint256 balance = info.strat.balanceOf(_secondAddress);

            vm.prank(_secondAddress);
            info.strat.redeem(balance, _secondAddress, _secondAddress);

            assertGt(asset.balanceOf(_secondAddress) - before, info.toDeposit);

            assertEq(info.strat.pricePerShare(), wad);
            checkStrategyTotals(info.strat, 0, 0, 0);
        }
    }
}
