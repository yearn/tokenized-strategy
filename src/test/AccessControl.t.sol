// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/console.sol";
import {Setup, IStrategy} from "./utils/Setup.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract AccesssControlTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_setManagement(address _address) public {
        vm.assume(_address != management);

        vm.prank(management);
        strategy.setManagement(_address);

        assertEq(strategy.management(), _address);
    }

    function test_setKeeper(address _address) public {
        vm.assume(_address != keeper);

        vm.prank(management);
        strategy.setKeeper(_address);

        assertEq(strategy.keeper(), _address);
    }

    function test_setPerformanceFee(uint256 _amount) public {
        vm.assume(_amount >= 0 && _amount < 10_000);

        vm.prank(management);
        strategy.setPerformanceFee(_amount);

        assertEq(strategy.performanceFee(), _amount);
    }

    function test_setTreasury(address _address) public {
        vm.assume(_address != treasury);

        vm.prank(management);
        strategy.setTreasury(_address);

        assertEq(strategy.treasury(), _address);
    }

    function test_setProfitMaxUnlockTime(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        vm.prank(management);
        strategy.setProfitMaxUnlockTime(_amount);

        assertEq(strategy.profitMaxUnlockTime(), _amount);
    }

    function test_setManagement_reverts(address _address) public {
        vm.assume(_address != management && _address != address(0));

        address _management = strategy.management();

        vm.prank(_address);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.setManagement(address(69));

        assertEq(strategy.management(), _management);
    }

    function test_setKeeper_reverts(address _address) public {
        vm.assume(_address != management);

        address _keeper = strategy.keeper();

        vm.prank(_address);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.setKeeper(address(69));

        assertEq(strategy.keeper(), _keeper);
    }

    function test_settingPerformanceFee_reverts(
        address _address,
        uint256 _amount
    ) public {
        vm.assume(_amount >= 0 && _amount < 10_000);
        vm.assume(_address != management);

        uint256 _performanceFee = strategy.performanceFee();

        vm.prank(_address);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.setPerformanceFee(_amount);

        assertEq(strategy.performanceFee(), _performanceFee);

        // TODO: add a test with > MAX_BPS
    }

    function test_settingTreasury_reverts(address _address) public {
        vm.assume(_address != management);

        address _treasury = strategy.treasury();

        vm.prank(_address);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.setTreasury(address(69));

        assertEq(strategy.treasury(), _treasury);
    }

    function test_settingProfitMaxUnlockTime_reverts(
        address _address,
        uint256 _amount
    ) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_address != management);

        uint256 profitMaxUnlockTime = strategy.profitMaxUnlockTime();

        vm.prank(_address);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.setProfitMaxUnlockTime(_amount);

        assertEq(strategy.profitMaxUnlockTime(), profitMaxUnlockTime);
    }

    function test_reInitialize_reverts(
        address _address,
        string memory name_,
        string memory symbol_
    ) public {
        string memory _name = strategy.name();
        string memory _symbol = strategy.symbol();
        address _management = strategy.management();

        vm.assume(
            uint256(keccak256(abi.encode(_name))) !=
                uint256(keccak256(abi.encode(name_)))
        );
        vm.assume(
            uint256(keccak256(abi.encode(_symbol))) !=
                uint256(keccak256(abi.encode(symbol_)))
        );
        vm.assume(_address != _management);

        vm.prank(management);
        vm.expectRevert("!init");
        strategy.initialize(address(asset), name_, symbol_, _address);

        assertEq(strategy.name(), _name);
        assertEq(strategy.symbol(), _symbol);
        assertEq(strategy.management(), _management);
    }

    // TODO: add test to re init on the library

    function test_accessControl_invest(address _address, uint256 _amount, bool _reported)
        public
    {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_address != address(strategy));

        asset.mint(address(strategy), _amount);

        // doesnt work from random address
        vm.prank(_address);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.invest(_amount, _reported);

        vm.prank(management);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.invest(_amount, _reported);

        assertEq(asset.balanceOf(address(yieldSource)), 0);

        vm.prank(address(strategy));
        strategy.invest(_amount, _reported);

        // make sure we deposited into the funds
        assertEq(asset.balanceOf(address(yieldSource)), _amount, "!out");
    }

    function test_accessControl_freeFunds(address _address, uint256 _amount)
        public
    {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_address != address(strategy));

        // deposit into the vault and should invest funds
        mintAndDepositIntoStrategy(user, _amount);

        // assure the deposit worked correctly
        assertEq(asset.balanceOf(address(yieldSource)), _amount);
        assertEq(asset.balanceOf(address(strategy)), 0);

        // doesnt work from random address
        vm.prank(_address);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.freeFunds(_amount);
        (_amount);

        // doesnt work from management either
        vm.prank(management);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.freeFunds(_amount);

        assertEq(asset.balanceOf(address(strategy)), 0);

        vm.prank(address(strategy));
        strategy.freeFunds(_amount);

        assertEq(asset.balanceOf(address(yieldSource)), 0);
        assertEq(asset.balanceOf(address(strategy)), _amount, "!out");
    }

    function test_accessControl_totalInvested(address _address, uint256 _amount)
        public
    {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_address != address(strategy));

        // deposit into the vault and should invest funds
        mintAndDepositIntoStrategy(user, _amount);

        // assure the deposit worked correctly
        assertEq(asset.balanceOf(address(yieldSource)), _amount);
        assertEq(asset.balanceOf(address(strategy)), 0);

        // doesnt work from random address
        vm.prank(_address);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.totalInvested();

        // doesnt work from management either
        vm.prank(management);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.totalInvested();

        vm.prank(address(strategy));
        uint256 amountOut = strategy.totalInvested();

        assertEq(amountOut, _amount, "!out");
    }

    function test_accessControl_tend(address _address, uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_address != keeper && _address != management);

        asset.mint(address(strategy), _amount);

        // doesnt work from random address
        vm.prank(_address);
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.tend();

        // doesnt work from library either
        vm.prank(address(strategy));
        vm.expectRevert(IStrategy.Unauthorized.selector);
        strategy.tend();

        vm.prank(keeper);
        strategy.tend();
    }
}
