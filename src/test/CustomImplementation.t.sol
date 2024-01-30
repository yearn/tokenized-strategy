// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {Setup, IMockStrategy} from "./utils/Setup.sol";

contract CustomImplementationsTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_customWithdrawLimit(
        address _address,
        uint256 _amount,
        uint16 _profitFactor
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

        uint256 profit = (_amount * _profitFactor) / MAX_BPS;

        strategy = IMockStrategy(setUpIlliquidStrategy());

        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        setFees(0, 0);

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        uint256 idle = asset.balanceOf(address(strategy));
        assertGt(idle, 0);

        // Assure we have a withdraw limit
        assertEq(strategy.availableWithdrawLimit(_address), idle);
        assertGt(strategy.totalAssets(), idle);

        // Make sure max withdraw and redeem return the correct amounts
        assertEq(strategy.maxWithdraw(_address), idle);
        assertEq(strategy.maxRedeem(_address), strategy.convertToShares(idle));
        assertLe(
            strategy.convertToAssets(strategy.maxRedeem(_address)),
            strategy.availableWithdrawLimit(_address)
        );

        vm.expectRevert("ERC4626: redeem more than max");
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        vm.expectRevert("ERC4626: withdraw more than max");
        vm.prank(_address);
        strategy.withdraw(_amount, _address, _address);

        createAndCheckProfit(strategy, profit, 0, 0);

        increaseTimeAndCheckBuffer(strategy, 5 days, profit / 2);

        idle = asset.balanceOf(address(strategy));
        assertGt(idle, 0);

        // Assure we have a withdraw limit
        assertEq(strategy.availableWithdrawLimit(_address), idle);
        assertGt(strategy.totalAssets(), idle);

        // Make sure max withdraw and redeem return the correct amounts
        assertEq(strategy.maxWithdraw(_address), idle);
        assertEq(strategy.maxRedeem(_address), strategy.convertToShares(idle));
        assertLe(
            strategy.convertToAssets(strategy.maxRedeem(_address)),
            strategy.availableWithdrawLimit(_address)
        );


        vm.expectRevert("ERC4626: redeem more than max");
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        vm.expectRevert("ERC4626: withdraw more than max");
        vm.prank(_address);
        strategy.withdraw(_amount, _address, _address);

        uint256 before = asset.balanceOf(_address);
        uint256 redeem = strategy.maxRedeem(idle);

        vm.prank(_address);
        strategy.redeem(redeem, _address, _address, 0);

        // We need to give a i wei rounding buffer
        assertApproxEq(asset.balanceOf(_address) - before, idle, 1);
        assertApproxEq(strategy.availableWithdrawLimit(_address), 0, 1);
        assertApproxEq(strategy.maxWithdraw(_address), 0, 1);
        assertApproxEq(strategy.maxRedeem(_address), 0, 1);
        assertLe(
            strategy.maxRedeem(_address),
            strategy.availableWithdrawLimit(_address)
        );
    }

    function test_customDepositLimit(
        address _allowed,
        address _notAllowed,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        strategy = IMockStrategy(setUpIlliquidStrategy());

        vm.assume(
            _allowed != address(0) &&
                _allowed != address(strategy) &&
                _allowed != _notAllowed &&
                _allowed != address(yieldSource)
        );
        vm.assume(
            _notAllowed != address(0) &&
                _notAllowed != address(strategy) &&
                _notAllowed != address(yieldSource)
        );

        setupWhitelist(_allowed);

        assertEq(strategy.maxDeposit(_allowed), type(uint256).max);
        assertEq(strategy.maxMint(_allowed), type(uint256).max);
        assertEq(strategy.maxDeposit(_notAllowed), 0);
        assertEq(strategy.maxMint(_notAllowed), 0);

        // Deposit should work fine for normal
        mintAndDepositIntoStrategy(strategy, _allowed, _amount);

        // Assure we deposit correctly
        assertEq(strategy.totalAssets(), _amount);

        asset.mint(_notAllowed, _amount);
        vm.prank(_notAllowed);
        asset.approve(address(strategy), _amount);

        vm.expectRevert("ERC4626: deposit more than max");
        vm.prank(_notAllowed);
        strategy.deposit(_amount, _notAllowed);

        vm.expectRevert("ERC4626: mint more than max");
        vm.prank(_notAllowed);
        strategy.mint(_amount, _notAllowed);
    }

    function test_tendTrigger(address _address, uint256 _amount) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(0) && _address != address(strategy));

        bool trigger;
        bytes memory data;
        // Should be false
        (trigger, data) = strategy.tendTrigger();
        assertTrue(!trigger);
        assertEq(data, abi.encodeWithSelector(strategy.tend.selector));

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        // Should still be false
        (trigger, ) = strategy.tendTrigger();
        assertTrue(!trigger);

        strategy.setTrigger(true);

        // Make sure it overrides correctly
        (trigger, ) = strategy.tendTrigger();
        assertTrue(trigger);
    }

    function test_onlyManagementModifier(address _address) public {
        vm.assume(_address != management && _address != address(strategy));

        assertTrue(!strategy.managed());

        vm.expectRevert("!management");
        vm.prank(_address);
        strategy.onlyLetManagers();

        assertTrue(!strategy.managed());

        vm.prank(management);
        strategy.onlyLetManagers();

        assertTrue(strategy.managed());
    }

    function test_onlyKeepersModifier(address _address) public {
        vm.assume(
            _address != keeper &&
                _address != management &&
                _address != address(strategy)
        );

        assertTrue(!strategy.kept());

        vm.expectRevert("!keeper");
        vm.prank(_address);
        strategy.onlyLetKeepersIn();

        assertTrue(!strategy.kept());

        vm.prank(keeper);
        strategy.onlyLetKeepersIn();

        assertTrue(strategy.kept());

        // Reset the slot holding the bool's all to false.
        vm.store(address(strategy), bytes32(uint256(0)), bytes32(0));

        assertTrue(!strategy.kept());

        // Make sure management works as well
        vm.prank(management);
        strategy.onlyLetKeepersIn();

        assertTrue(strategy.kept());
    }

    function test_onlyEmergencyAuthorizedModifier(address _address) public {
        vm.assume(
            _address != emergencyAdmin &&
                _address != management &&
                _address != address(strategy)
        );

        assertEq(strategy.emergencyAdmin(), emergencyAdmin);

        assertTrue(!strategy.emergentizated());

        vm.expectRevert("!emergency authorized");
        vm.prank(_address);
        strategy.onlyLetEmergencyAdminsIn();

        assertTrue(!strategy.emergentizated());

        vm.prank(emergencyAdmin);
        strategy.onlyLetEmergencyAdminsIn();

        assertTrue(strategy.emergentizated());

        // Reset the slot holding the bools all to false.
        vm.store(address(strategy), bytes32(uint256(0)), bytes32(0));

        assertTrue(!strategy.emergentizated());

        // Make sure management works as well
        vm.prank(management);
        strategy.onlyLetEmergencyAdminsIn();

        assertTrue(strategy.emergentizated());
    }
}
