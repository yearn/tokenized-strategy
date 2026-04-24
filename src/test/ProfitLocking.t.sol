// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import {Setup} from "./utils/Setup.sol";

contract ProfitLockingTest is Setup {
    function setUp() public override {
        super.setUp();
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

        asset.mint(address(strategy), profit);

        uint256 ppsBefore = strategy.pricePerShare();

        vm.prank(keeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();

        assertEq(reportedProfit, profit, "!profit");
        assertEq(reportedLoss, 0, "!loss");
        assertGt(strategy.pricePerShare(), ppsBefore, "!pps");
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
        asset.mint(address(strategy), profit);

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
}
