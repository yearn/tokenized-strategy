// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import {Setup} from "./utils/Setup.sol";

contract AccountingTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_airdropImmediatelyAccruesInViews(
        address _user,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _user != address(0) &&
                _user != 0x000000000000000000000000000000000000dEaD &&
                _user != address(strategy) &&
                _user != keeper &&
                _user != management &&
                _user != emergencyAdmin &&
                _user != protocolFeeRecipient &&
                _user != performanceFeeRecipient &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 pps = strategy.pricePerShare();

        asset.mint(address(strategy), profit);

        assertEq(strategy.totalAssets(), _amount, "!assets frozen");
        assertEq(strategy.pricePerShare(), pps, "!pps frozen");

        skip(1);

        assertEq(strategy.totalAssets(), _amount + profit, "!assets");
        assertGt(strategy.pricePerShare(), pps, "!pps");

        uint256 before = asset.balanceOf(_user);

        uint256 shares = strategy.balanceOf(_user);

        vm.prank(_user);
        strategy.redeem(shares, _user, _user);

        assertEq(asset.balanceOf(_user) - before, _amount + profit, "!out");
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_yieldSourceGainImmediatelyAccruesInViews(
        address _user,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _user != address(0) &&
                _user != 0x000000000000000000000000000000000000dEaD &&
                _user != address(strategy) &&
                _user != keeper &&
                _user != management &&
                _user != emergencyAdmin &&
                _user != protocolFeeRecipient &&
                _user != performanceFeeRecipient &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 pps = strategy.pricePerShare();

        asset.mint(address(yieldSource), profit);

        assertEq(strategy.totalAssets(), _amount, "!assets frozen");
        assertEq(strategy.pricePerShare(), pps, "!pps frozen");

        skip(1);

        assertEq(strategy.totalAssets(), _amount + profit, "!assets");
        assertGt(strategy.pricePerShare(), pps, "!pps");

        uint256 before = asset.balanceOf(_user);

        uint256 shares = strategy.balanceOf(_user);

        vm.prank(_user);
        strategy.redeem(shares, _user, _user);

        assertEq(asset.balanceOf(_user) - before, _amount + profit, "!out");
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_previewDepositMatchesSyncAfterAccruedFees(
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
                _user != keeper &&
                _depositor != keeper &&
                _user != management &&
                _depositor != management &&
                _user != emergencyAdmin &&
                _depositor != emergencyAdmin &&
                _user != protocolFeeRecipient &&
                _depositor != protocolFeeRecipient &&
                _user != performanceFeeRecipient &&
                _depositor != performanceFeeRecipient &&
                _user != address(yieldSource) &&
                _depositor != address(yieldSource)
        );

        uint16 performanceFee = 1_000;
        setFees(0, performanceFee);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedFeeAssets = (profit * performanceFee) / MAX_BPS;
        asset.mint(address(strategy), profit);

        skip(1);

        uint256 preview = strategy.previewDeposit(_amount);

        asset.mint(_depositor, _amount);
        vm.prank(_depositor);
        asset.approve(address(strategy), _amount);

        vm.prank(_depositor);
        uint256 minted = strategy.deposit(_amount, _depositor);

        assertEq(minted, preview, "!preview");
        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedFeeAssets,
            100
        );
    }

    function test_reportReturnsZeroAfterWriteSync(
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
                _user != keeper &&
                _depositor != keeper &&
                _user != management &&
                _depositor != management &&
                _user != emergencyAdmin &&
                _depositor != emergencyAdmin &&
                _user != protocolFeeRecipient &&
                _depositor != protocolFeeRecipient &&
                _user != performanceFeeRecipient &&
                _depositor != performanceFeeRecipient &&
                _user != address(yieldSource) &&
                _depositor != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        asset.mint(address(strategy), profit);

        skip(1);

        asset.mint(_depositor, _amount);
        vm.prank(_depositor);
        asset.approve(address(strategy), _amount);

        vm.prank(_depositor);
        strategy.deposit(_amount, _depositor);

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, 0, "!profit");
        assertEq(reportedLoss, 0, "!loss");
    }

    function test_settingFeeSyncsExistingProfit(
        address _user,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != keeper &&
                _user != management &&
                _user != emergencyAdmin &&
                _user != protocolFeeRecipient &&
                _user != performanceFeeRecipient &&
                _user != address(yieldSource)
        );

        uint16 performanceFee = 1_000;
        setFees(0, performanceFee);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;
        uint256 expectedFeeAssets = (profit * performanceFee) / MAX_BPS;
        asset.mint(address(strategy), profit);

        skip(1);

        vm.prank(management);
        strategy.setPerformanceFee(0);

        assertEq(strategy.performanceFee(), 0, "!fee");
        assertApproxEq(
            strategy.convertToAssets(
                strategy.balanceOf(performanceFeeRecipient)
            ),
            expectedFeeAssets,
            100
        );
    }

    function test_lossHitsViewsImmediately(
        address _user,
        uint256 _amount,
        uint16 _lossFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _lossFactor = uint16(bound(uint256(_lossFactor), 10, 5_000));
        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != keeper &&
                _user != management &&
                _user != emergencyAdmin &&
                _user != protocolFeeRecipient &&
                _user != performanceFeeRecipient &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        uint256 loss = (_amount * _lossFactor) / MAX_BPS;
        yieldSource.simulateLoss(loss);

        assertEq(strategy.totalAssets(), _amount, "!assets frozen");
        assertEq(strategy.maxWithdraw(_user), _amount, "!withdraw frozen");

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, 0, "!profit");
        assertEq(reportedLoss, loss, "!loss");
        assertEq(strategy.totalAssets(), _amount - loss, "!assets");
        assertEq(strategy.maxWithdraw(_user), _amount - loss, "!withdraw");

        uint256 before = asset.balanceOf(_user);
        uint256 shares = strategy.balanceOf(_user);

        vm.prank(_user);
        uint256 assets = strategy.redeem(shares, _user, _user);

        assertEq(assets, _amount - loss, "!redeem");
        assertEq(asset.balanceOf(_user) - before, _amount - loss, "!out");
    }

    function test_initialDonationMintsDeadShares(
        address _user,
        uint256 _amount,
        uint256 _donation
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _donation = bound(_donation, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _user != address(0) &&
                _user != 0x000000000000000000000000000000000000dEaD &&
                _user != address(strategy) &&
                _user != keeper &&
                _user != management &&
                _user != emergencyAdmin &&
                _user != protocolFeeRecipient &&
                _user != performanceFeeRecipient &&
                _user != address(yieldSource)
        );

        setFees(0, 0);

        skip(1);

        asset.mint(address(strategy), _donation);

        assertEq(strategy.previewDeposit(_amount), _amount, "!preview");

        mintAndDepositIntoStrategy(strategy, _user, _amount);

        assertEq(strategy.balanceOf(_user), _amount, "!shares");
        assertEq(
            strategy.balanceOf(0x000000000000000000000000000000000000dEaD),
            _donation,
            "!dead"
        );
        assertEq(strategy.totalAssets(), _amount + _donation, "!assets");

        uint256 before = asset.balanceOf(_user);

        uint256 shares = strategy.balanceOf(_user);

        vm.prank(_user);
        strategy.redeem(shares, _user, _user);

        assertEq(asset.balanceOf(_user) - before, _amount, "!out");
        assertEq(strategy.totalAssets(), _donation, "!remaining");
    }
}
