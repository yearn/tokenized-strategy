// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {Setup, IMockStrategy} from "./utils/Setup.sol";

contract AccountingTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_airdropDoesNotIncreasePPS(
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

        // set fees to 0 for calculations simplicity
        setFees(0, 0);

        // nothing has happened pps should be 1
        uint256 pricePerShare = strategy.pricePerShare();
        assertEq(pricePerShare, wad);

        // deposit into the vault
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // should still be 1
        assertEq(strategy.pricePerShare(), pricePerShare);

        // airdrop to strategy
        uint256 toAirdrop = (_amount * _profitFactor) / MAX_BPS;
        asset.mint(address(strategy), toAirdrop);

        // PPS shouldn't change but the balance does.
        assertEq(strategy.pricePerShare(), pricePerShare);
        checkStrategyTotals(
            strategy,
            _amount,
            _amount - toAirdrop,
            toAirdrop,
            _amount
        );

        uint256 beforeBalance = asset.balanceOf(_address);
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        // should have pulled out just the deposited amount leaving the rest deployed.
        assertEq(asset.balanceOf(_address), beforeBalance + _amount);
        assertEq(asset.balanceOf(address(strategy)), 0);
        assertEq(asset.balanceOf(address(yieldSource)), toAirdrop);
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_airdropDoesNotIncreasePPS_reportRecordsIt(
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

        // set fees to 0 for calculations simplicity
        setFees(0, 0);

        // nothing has happened pps should be 1
        uint256 pricePerShare = strategy.pricePerShare();
        assertEq(pricePerShare, wad);

        // deposit into the vault
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // should still be 1
        assertEq(strategy.pricePerShare(), pricePerShare);

        // airdrop to strategy
        uint256 toAirdrop = (_amount * _profitFactor) / MAX_BPS;
        asset.mint(address(strategy), toAirdrop);

        // PPS shouldn't change but the balance does.
        assertEq(strategy.pricePerShare(), pricePerShare);
        checkStrategyTotals(
            strategy,
            _amount,
            _amount - toAirdrop,
            toAirdrop,
            _amount
        );

        // process a report to realize the gain from the airdrop
        uint256 profit;
        vm.prank(keeper);
        (profit, ) = strategy.report();

        assertEq(strategy.pricePerShare(), pricePerShare);
        assertEq(profit, toAirdrop);
        checkStrategyTotals(
            strategy,
            _amount + toAirdrop,
            _amount + toAirdrop,
            0,
            _amount + toAirdrop
        );

        // allow some profit to come unlocked
        skip(profitMaxUnlockTime / 2);

        assertGt(strategy.pricePerShare(), pricePerShare);

        //air drop again, we should not increase again
        pricePerShare = strategy.pricePerShare();
        asset.mint(address(strategy), toAirdrop);
        assertEq(strategy.pricePerShare(), pricePerShare);

        // skip the rest of the time for unlocking
        skip(profitMaxUnlockTime / 2);

        // we should get a % return equal to our profit factor
        assertRelApproxEq(
            strategy.pricePerShare(),
            wad + ((wad * _profitFactor) / MAX_BPS),
            MAX_BPS
        );

        // Total is the same but balance has adjusted again
        checkStrategyTotals(strategy, _amount + toAirdrop, _amount, toAirdrop);

        uint256 beforeBalance = asset.balanceOf(_address);
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        // should have pulled out the deposit plus profit that was reported but not the second airdrop
        assertEq(
            asset.balanceOf(_address),
            beforeBalance + _amount + toAirdrop
        );
        assertEq(asset.balanceOf(address(strategy)), 0);
        assertEq(asset.balanceOf(address(yieldSource)), toAirdrop);
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_earningYieldDoesNotIncreasePPS(
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

        // set fees to 0 for calculations simplicity
        setFees(0, 0);

        // nothing has happened pps should be 1
        uint256 pricePerShare = strategy.pricePerShare();
        assertEq(pricePerShare, wad);

        // deposit into the strategy
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // should still be 1
        assertEq(strategy.pricePerShare(), pricePerShare);

        // airdrop to strategy
        uint256 toAirdrop = (_amount * _profitFactor) / MAX_BPS;
        asset.mint(address(yieldSource), toAirdrop);

        // nothing should change
        assertEq(strategy.pricePerShare(), pricePerShare);
        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        uint256 beforeBalance = asset.balanceOf(_address);
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        // should have pulled out just the deposit amount
        assertEq(asset.balanceOf(_address), beforeBalance + _amount);
        assertEq(asset.balanceOf(address(yieldSource)), toAirdrop);
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_earningYieldDoesNotIncreasePPS_reportRecordsIt(
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

        // set fees to 0 for calculations simplicity
        setFees(0, 0);

        // nothing has happened pps should be 1
        uint256 pricePerShare = strategy.pricePerShare();
        assertEq(pricePerShare, wad);

        // deposit into the vault
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // should still be 1
        assertEq(strategy.pricePerShare(), pricePerShare);

        // airdrop to strategy
        uint256 toAirdrop = (_amount * _profitFactor) / MAX_BPS;
        asset.mint(address(yieldSource), toAirdrop);
        assertEq(asset.balanceOf(address(yieldSource)), _amount + toAirdrop);

        // nothing should change
        assertEq(strategy.pricePerShare(), pricePerShare);
        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        // process a report to realize the gain from the airdrop
        uint256 profit;
        vm.prank(keeper);
        (profit, ) = strategy.report();

        assertEq(strategy.pricePerShare(), pricePerShare);
        assertEq(profit, toAirdrop);

        checkStrategyTotals(
            strategy,
            _amount + toAirdrop,
            _amount + toAirdrop,
            0,
            _amount + toAirdrop
        );

        // allow some profit to come unlocked
        skip(profitMaxUnlockTime / 2);

        assertGt(strategy.pricePerShare(), pricePerShare);

        //air drop again, we should not increase again
        pricePerShare = strategy.pricePerShare();
        asset.mint(address(yieldSource), toAirdrop);
        assertEq(strategy.pricePerShare(), pricePerShare);

        // skip the rest of the time for unlocking
        skip(profitMaxUnlockTime / 2);

        // we should get a % return equal to our profit factor
        assertRelApproxEq(
            strategy.pricePerShare(),
            wad + ((wad * _profitFactor) / MAX_BPS),
            MAX_BPS
        );

        // Total is the same.
        checkStrategyTotals(
            strategy,
            _amount + toAirdrop,
            _amount + toAirdrop,
            0
        );

        uint256 beforeBalance = asset.balanceOf(_address);
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        // should have pulled out the deposit plus profit that was reported but not the second airdrop
        assertEq(
            asset.balanceOf(_address),
            beforeBalance + _amount + toAirdrop
        );

        assertEq(asset.balanceOf(address(yieldSource)), toAirdrop);
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_tend_noIdle_harvestProfit(
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 1, MAX_BPS));

        setFees(0, 0);
        // nothing has happened pps should be 1
        uint256 pricePerShare = strategy.pricePerShare();
        assertEq(pricePerShare, wad);

        // deposit into the vault
        mintAndDepositIntoStrategy(strategy, user, _amount);

        // should still be 1
        assertEq(strategy.pricePerShare(), pricePerShare);

        // airdrop to strategy to simulate a harvesting of rewards
        uint256 toAirdrop = (_amount * _profitFactor) / MAX_BPS;
        asset.mint(address(strategy), toAirdrop);
        assertEq(asset.balanceOf(address(strategy)), toAirdrop);
        checkStrategyTotals(strategy, _amount, _amount - toAirdrop, toAirdrop);

        vm.prank(keeper);
        strategy.tend();

        // Should have deposited the toAirdrop amount but no other changes
        checkStrategyTotals(strategy, _amount, _amount, 0);
        assertEq(
            asset.balanceOf(address(yieldSource)),
            _amount + toAirdrop,
            "!yieldSource"
        );
        assertEq(strategy.pricePerShare(), wad, "!pps");

        // Make sure we now report the profit correctly
        vm.prank(keeper);
        strategy.report();

        skip(profitMaxUnlockTime);

        assertRelApproxEq(
            strategy.pricePerShare(),
            wad + ((wad * _profitFactor) / MAX_BPS),
            MAX_BPS
        );

        uint256 beforeBalance = asset.balanceOf(user);
        vm.prank(user);
        strategy.redeem(_amount, user, user);

        // should have pulled out the deposit plus profit that was reported but not the second airdrop
        assertEq(asset.balanceOf(user), beforeBalance + _amount + toAirdrop);
        assertEq(asset.balanceOf(address(yieldSource)), 0);
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_tend_idleFunds_harvestProfit(
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 1, MAX_BPS));

        // Use the illiquid mock strategy so it doesn't deposit all funds
        strategy = IMockStrategy(setUpIlliquidStrategy());

        setFees(0, 0);
        // nothing has happened pps should be 1
        uint256 pricePerShare = strategy.pricePerShare();
        assertEq(pricePerShare, wad);

        // deposit into the vault
        mintAndDepositIntoStrategy(strategy, user, _amount);

        uint256 expectedDeposit = _amount / 2;
        checkStrategyTotals(
            strategy,
            _amount,
            expectedDeposit,
            _amount - expectedDeposit,
            _amount
        );

        assertEq(
            asset.balanceOf(address(yieldSource)),
            expectedDeposit,
            "!yieldSource"
        );
        // should still be 1
        assertEq(strategy.pricePerShare(), wad);

        // airdrop to strategy to simulate a harvesting of rewards
        uint256 toAirdrop = (_amount * _profitFactor) / MAX_BPS;
        asset.mint(address(strategy), toAirdrop);
        assertEq(
            asset.balanceOf(address(strategy)),
            _amount - expectedDeposit + toAirdrop
        );

        vm.prank(keeper);
        strategy.tend();

        // Should have withdrawn all the funds from the yield source
        checkStrategyTotals(strategy, _amount, 0, _amount, _amount);
        assertEq(asset.balanceOf(address(yieldSource)), 0, "!yieldSource");
        assertEq(asset.balanceOf(address(strategy)), _amount + toAirdrop);
        assertEq(strategy.pricePerShare(), wad, "!pps");

        // Make sure we now report the profit correctly
        vm.prank(keeper);
        strategy.report();

        checkStrategyTotals(
            strategy,
            _amount + toAirdrop,
            (_amount + toAirdrop) / 2,
            (_amount + toAirdrop) - ((_amount + toAirdrop) / 2)
        );
        assertEq(
            asset.balanceOf(address(yieldSource)),
            (_amount + toAirdrop) / 2
        );

        skip(profitMaxUnlockTime);

        assertRelApproxEq(
            strategy.pricePerShare(),
            wad + ((wad * _profitFactor) / MAX_BPS),
            MAX_BPS
        );
    }

    function test_withdrawWithUnrealizedLoss_reverts(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        uint256 toLoose = (_amount * _lossFactor) / MAX_BPS;
        // Simulate a loss.
        vm.prank(address(yieldSource));
        asset.transfer(address(69), toLoose);

        vm.expectRevert("too much loss");
        vm.prank(_address);
        strategy.withdraw(_amount, _address, _address);
    }

    function test_withdrawWithUnrealizedLoss_withMaxLoss(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        uint256 toLoose = (_amount * _lossFactor) / MAX_BPS;
        // Simulate a loss.
        vm.prank(address(yieldSource));
        asset.transfer(address(69), toLoose);

        uint256 beforeBalance = asset.balanceOf(_address);
        uint256 expectedOut = _amount - toLoose;
        // Withdraw the full amount before the loss is reported.
        vm.prank(_address);
        strategy.withdraw(_amount, _address, _address, _lossFactor);

        uint256 afterBalance = asset.balanceOf(_address);

        assertEq(afterBalance - beforeBalance, expectedOut);
        assertEq(strategy.pricePerShare(), wad);
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_redeemWithUnrealizedLoss(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        uint256 toLoose = (_amount * _lossFactor) / MAX_BPS;
        // Simulate a loss.
        vm.prank(address(yieldSource));
        asset.transfer(address(69), toLoose);

        uint256 beforeBalance = asset.balanceOf(_address);
        uint256 expectedOut = _amount - toLoose;
        // Withdraw the full amount before the loss is reported.
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        uint256 afterBalance = asset.balanceOf(_address);

        assertEq(afterBalance - beforeBalance, expectedOut);
        assertEq(strategy.pricePerShare(), wad);
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_redeemWithUnrealizedLoss_allowNoLoss_reverts(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        uint256 toLoose = (_amount * _lossFactor) / MAX_BPS;
        // Simulate a loss.
        vm.prank(address(yieldSource));
        asset.transfer(address(69), toLoose);

        vm.expectRevert("too much loss");
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address, 0);
    }

    function test_redeemWithUnrealizedLoss_customMaxLoss(
        address _address,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 10, MAX_BPS));
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _address, _amount);

        uint256 toLoose = (_amount * _lossFactor) / MAX_BPS;
        // Simulate a loss.
        vm.prank(address(yieldSource));
        asset.transfer(address(69), toLoose);

        uint256 beforeBalance = asset.balanceOf(_address);
        uint256 expectedOut = _amount - toLoose;

        // First set it to just under the expected loss.
        vm.expectRevert("too much loss");
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address, _lossFactor - 1);

        // Now redeem with the correct loss.
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address, _lossFactor);

        uint256 afterBalance = asset.balanceOf(_address);

        assertEq(afterBalance - beforeBalance, expectedOut);
        assertEq(strategy.pricePerShare(), wad);
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }
}
