// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract AccesssControlTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function testManagementSetter(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        vm.prank(management);
        strategy.setManagement(address(69));

        assertEq(strategy.management(), address(69));
    }

    function testKeeperSetter(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        vm.prank(management);
        strategy.setKeeper(address(69));

        assertEq(strategy.keeper(), address(69));
    }

    function testPerformanceFeeSetter(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        vm.prank(management);
        strategy.setPerformanceFee(8_000);

        assertEq(strategy.performanceFee(), 8_000);
    }

    function testTreasurySetter(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        vm.prank(management);
        strategy.setTreasury(address(69));

        assertEq(strategy.treasury(), address(69));
    }

    function testProfitMaxUnlockTimeSetter(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        vm.prank(management);
        strategy.setProfitMaxUnlockTime(3 days);

        assertEq(strategy.profitMaxUnlockTime(), 3 days);
    }

    function testManagementSetterReverts(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        address _management = strategy.management();

        vm.prank(user);
        vm.expectRevert("!auth");
        strategy.setManagement(address(69));

        assertEq(strategy.management(), _management);
    }

    function testKeeperSetterReverts(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        address _keeper = strategy.keeper();

        vm.prank(user);
        vm.expectRevert("!auth");
        strategy.setKeeper(address(69));

        assertEq(strategy.keeper(), _keeper);
    }

    function testPerformanceFeeSetterReverts(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 _performanceFee = strategy.performanceFee();

        vm.prank(user);
        vm.expectRevert("!auth");
        strategy.setPerformanceFee(8_000);

        assertEq(strategy.performanceFee(), _performanceFee);
    }

    function testTreasurySetterReverts(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        address _treasury = strategy.treasury();

        vm.prank(user);
        vm.expectRevert("!auth");
        strategy.setTreasury(address(69));

        assertEq(strategy.treasury(), _treasury);
    }

    function testProfitMaxUnlockTimeSetterReverts(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 profitMaxUnlockTime = strategy.profitMaxUnlockTime();

        vm.prank(user); 
        vm.expectRevert("!auth");
        strategy.setProfitMaxUnlockTime(3 days);

        assertEq(strategy.profitMaxUnlockTime(), profitMaxUnlockTime);
    }

    function testReInitializeReverts(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        string memory _name = strategy.name();
        string memory _symbol = strategy.symbol();
        address _management = strategy.management();
        
        vm.prank(management);
        vm.expectRevert("!init");
        strategy.initialize(token, "Name", "sym", user);

        assertEq(strategy.name(), _name);
        assertEq(strategy.symbol(), _symbol);
        assertEq(strategy.management(), _management);
    }   

    // TODO: add calls to invest, freeFunds totalInvested and tend
}