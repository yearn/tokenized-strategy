// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";

contract AccesssControlTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_setManagement(address _address) public {
        vm.assume(_address != management && _address != address(0));

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdateManagement(_address);

        vm.prank(management);
        strategy.setManagement(_address);

        assertEq(strategy.management(), _address);
    }

    function test_setKeeper(address _address) public {
        vm.assume(_address != keeper);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdateKeeper(_address);

        vm.prank(management);
        strategy.setKeeper(_address);

        assertEq(strategy.keeper(), _address);
    }

    function test_setPerformanceFee(uint16 _amount) public {
        _amount = uint16(bound(_amount, 0, 9_999));

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdatePerformanceFee(_amount);

        vm.prank(management);
        strategy.setPerformanceFee(_amount);

        assertEq(strategy.performanceFee(), _amount);
    }

    function test_setPerformanceFeeRecipient(address _address) public {
        vm.assume(
            _address != performanceFeeRecipient &&
                _address != address(0) &&
                _address != address(strategy)
        );

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdatePerformanceFeeRecipient(_address);

        vm.prank(management);
        strategy.setPerformanceFeeRecipient(_address);

        assertEq(strategy.performanceFeeRecipient(), _address);
    }

    function test_setProfitMaxUnlockTime(uint32 _amount) public {
        // Must be less than 1 year
        uint256 amount = bound(uint256(_amount), 1, 31_556_952);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdateProfitMaxUnlockTime(amount);

        vm.prank(management);
        strategy.setProfitMaxUnlockTime(amount);

        assertEq(strategy.profitMaxUnlockTime(), amount);
    }

    function test_shutdown() public {
        assertTrue(!strategy.isShutdown());

        vm.expectEmit(true, true, true, true, address(strategy));
        emit StrategyShutdown();

        vm.prank(management);
        strategy.shutdownStrategy();

        assertTrue(strategy.isShutdown());
    }

    function test_setManagement_reverts(address _address) public {
        vm.assume(_address != management && _address != address(0));

        address _management = strategy.management();

        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.setManagement(address(69));

        assertEq(strategy.management(), _management);
    }

    function test_setKeeper_reverts(address _address) public {
        vm.assume(_address != management);

        address _keeper = strategy.keeper();

        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.setKeeper(address(69));

        assertEq(strategy.keeper(), _keeper);
    }

    function test_settingPerformanceFee_reverts(
        address _address,
        uint16 _amount
    ) public {
        _amount = uint16(bound(_amount, 0, 9_999));
        vm.assume(_address != management);

        uint256 _performanceFee = strategy.performanceFee();

        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.setPerformanceFee(_amount);

        assertEq(strategy.performanceFee(), _performanceFee);

        vm.prank(management);
        vm.expectRevert("MAX BPS");
        strategy.setPerformanceFee(uint16(_amount + MAX_BPS));
    }

    function test_settingPerformanceFeeRecipient_reverts(
        address _address
    ) public {
        vm.assume(_address != management && _address != address(strategy));

        address _performanceFeeRecipient = strategy.performanceFeeRecipient();

        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.setPerformanceFeeRecipient(address(69));

        vm.prank(management);
        vm.expectRevert("Can't be self");
        strategy.setPerformanceFeeRecipient(address(strategy));

        assertEq(strategy.performanceFeeRecipient(), _performanceFeeRecipient);
    }

    function test_settingProfitMaxUnlockTime_reverts(
        address _address,
        uint32 _amount,
        uint256 _badAmount
    ) public {
        // Must be less than 1 year
        uint256 amount = bound(uint256(_amount), 1, 31_556_952);
        _badAmount = bound(_badAmount, 31_556_952 + 1, type(uint256).max);
        vm.assume(_address != management);

        uint256 profitMaxUnlockTime = strategy.profitMaxUnlockTime();

        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.setProfitMaxUnlockTime(amount);

        assertEq(strategy.profitMaxUnlockTime(), profitMaxUnlockTime);

        // Can't be more than 1 year of seconds
        vm.prank(management);
        vm.expectRevert("to long");
        strategy.setProfitMaxUnlockTime(_badAmount);

        // Can't be 0
        vm.prank(management);
        vm.expectRevert("to short");
        strategy.setProfitMaxUnlockTime(0);

        assertEq(strategy.profitMaxUnlockTime(), profitMaxUnlockTime);
    }

    function test_shutdown_reverts(address _address) public {
        vm.assume(_address != management);
        assertTrue(!strategy.isShutdown());

        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.shutdownStrategy();

        assertTrue(!strategy.isShutdown());
    }

    function test_initializeTokenizedStrategy_reverts(
        address _address,
        string memory name_
    ) public {
        vm.assume(_address != address(0));

        assertEq(tokenizedStrategy.management(), address(0));
        assertEq(tokenizedStrategy.keeper(), address(0));

        vm.expectRevert();
        tokenizedStrategy.init(
            address(asset),
            name_,
            _address,
            _address,
            _address
        );

        assertEq(tokenizedStrategy.management(), address(0));
        assertEq(tokenizedStrategy.keeper(), address(0));
    }

    function test_accessControl_deployFunds(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(strategy));

        asset.mint(address(strategy), _amount);

        // doesnt work from random address
        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.deployFunds(_amount);

        vm.prank(management);
        vm.expectRevert("!Authorized");
        strategy.deployFunds(_amount);

        assertEq(asset.balanceOf(address(yieldSource)), 0);

        vm.prank(address(strategy));
        strategy.deployFunds(_amount);

        // make sure we deposited into the funds
        assertEq(asset.balanceOf(address(yieldSource)), _amount, "!out");
    }

    function test_accessControl_freeFunds(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(strategy));

        // deposit into the vault and should deploy funds
        mintAndDepositIntoStrategy(strategy, user, _amount);

        // assure the deposit worked correctly
        assertEq(asset.balanceOf(address(yieldSource)), _amount);
        assertEq(asset.balanceOf(address(strategy)), 0);

        // doesnt work from random address
        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.freeFunds(_amount);
        (_amount);

        // doesnt work from management either
        vm.prank(management);
        vm.expectRevert("!Authorized");
        strategy.freeFunds(_amount);

        assertEq(asset.balanceOf(address(strategy)), 0);

        vm.prank(address(strategy));
        strategy.freeFunds(_amount);

        assertEq(asset.balanceOf(address(yieldSource)), 0);
        assertEq(asset.balanceOf(address(strategy)), _amount, "!out");
    }

    function test_accessControl_harvestAndReport(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(strategy));

        // deposit into the vault and should deploy funds
        mintAndDepositIntoStrategy(strategy, user, _amount);

        // assure the deposit worked correctly
        assertEq(asset.balanceOf(address(yieldSource)), _amount);
        assertEq(asset.balanceOf(address(strategy)), 0);

        // doesnt work from random address
        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.harvestAndReport();

        // doesnt work from management either
        vm.prank(management);
        vm.expectRevert("!Authorized");
        strategy.harvestAndReport();

        vm.prank(address(strategy));
        uint256 amountOut = strategy.harvestAndReport();

        assertEq(amountOut, _amount, "!out");
    }

    function test_accessControl_tendThis(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(strategy));

        // doesnt work from random address
        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.tendThis(_amount);

        vm.prank(address(strategy));
        strategy.tendThis(_amount);
    }

    function test_accessControl_tend(address _address, uint256 _amount) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != keeper && _address != management);

        asset.mint(address(strategy), _amount);

        // doesnt work from random address
        vm.prank(_address);
        vm.expectRevert("!Authorized");
        strategy.tend();

        vm.prank(keeper);
        strategy.tend();
    }
}
