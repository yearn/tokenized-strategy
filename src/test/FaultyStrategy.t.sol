// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import {Setup, IMockStrategy} from "./utils/Setup.sol";

contract FaultyStrategy is Setup {
    bool public reenter;
    address public addr;
    uint256 public amount;

    uint256 public pps;
    uint256 public convertAmountToShares;
    uint256 public convertAmountToAssets;

    function setUp() public override {
        super.setUp();
    }

    function test_deployFundsViewReentrancy(
        address _user,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        configureFaultyStrategy(0, true);
        storeCallBackVariables(_amount);

        mintAndDepositIntoStrategy(strategy, _user, _amount);
    }

    function test_freeFundsViewReentrancy(
        address _user,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        configureFaultyStrategy(0, true);
        storeCallBackVariables(_amount / 2);

        vm.prank(_user);
        strategy.withdraw(_amount / 2, _user, _user);
    }

    function test_tendViewReentrancy(
        address _user,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        configureFaultyStrategy(0, true);

        uint256 toAirdrop = (_amount * _profitFactor) / MAX_BPS;
        storeCallBackVariables(toAirdrop);
        asset.mint(address(strategy), toAirdrop);

        vm.prank(keeper);
        strategy.tend();
    }

    function test_deployFundsReentrancy_reverts(
        address _user,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        configureFaultyStrategy(0, true);
        reenter = true;
        storeReentrancyVariables(_user, _amount);

        asset.mint(_user, _amount);

        vm.prank(_user);
        asset.approve(address(strategy), _amount);

        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(_user);
        strategy.deposit(_amount, _user);

        checkStrategyTotals(strategy, 0, 0, 0, 0);

        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(_user);
        strategy.mint(_amount, _user);

        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_freeFundsReentrancy_reverts(
        address _user,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        configureFaultyStrategy(0, true);
        reenter = true;
        storeReentrancyVariables(_user, _amount);

        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(_user);
        strategy.withdraw(_amount, _user, _user);

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);

        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(_user);
        strategy.redeem(_amount, _user, _user);

        checkStrategyTotals(strategy, _amount, _amount, 0, _amount);
    }

    function test_tendReentrancy_reverts(
        address _user,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        strategy = IMockStrategy(setUpFaultyStrategy());

        vm.assume(
            _user != address(0) &&
                _user != address(strategy) &&
                _user != address(yieldSource)
        );

        setFees(0, 0);
        mintAndDepositIntoStrategy(strategy, _user, _amount);

        configureFaultyStrategy(0, true);
        reenter = true;
        storeReentrancyVariables(_user, _amount);

        vm.expectRevert("ReentrancyGuard: reentrant call");
        vm.prank(keeper);
        strategy.tend();
    }

    function callBack(
        uint256 _pps,
        uint256 _convertAmountToShares,
        uint256 _convertAmountToAssets
    ) public {
        if (reenter) {
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

    function storeReentrancyVariables(address _user, uint256 _amount) public {
        addr = _user;
        amount = _amount;
    }
}
