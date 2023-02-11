// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract StrategyTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function testPreviewDeposit(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 amountOut = strategy.previewDeposit(_amount);

        assertEq(amountOut, _amount, "Amount out wrong");
    }

    function testPreviewMint(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 amountOut = strategy.previewMint(_amount);

        assertEq(amountOut, _amount, "Amount out wrong");
    }

    function testPreviewWithdraw(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 amountOut = strategy.previewWithdraw(_amount);

        assertEq(amountOut, _amount, "Amount out wrong");
    }

    function testPreviewRedeem(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 amountOut = strategy.previewRedeem(_amount);

        assertEq(amountOut, _amount, "Amount out wrong");
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        token.mint(user, _amount);

        vm.prank(user);
        token.approve(address(strategy), _amount);

        vm.prank(user);
        uint256 amountOut = strategy.deposit(_amount, user);

        assertEq(amountOut, _amount, "Amount out");
        assertEq(amountOut, strategy.balanceOf(user), "bal");
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        token.mint(user, _amount);

        vm.prank(user);
        token.approve(address(strategy), _amount);

        vm.prank(user);
        uint256 amountOut = strategy.mint(_amount, user);

        assertEq(amountOut, _amount, "Amount out");
        assertEq(amountOut, strategy.balanceOf(user), "bal");
    }

    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        token.mint(user, _amount);

        vm.prank(user);
        token.approve(address(strategy), _amount);

        vm.prank(user);
        uint256 amountOut = strategy.deposit(_amount, user);

        assertEq(amountOut, _amount, "Amount out");
        assertEq(amountOut, strategy.balanceOf(user), "bal");

        skip(10);

        vm.prank(user);
        uint256 sharesOut = strategy.withdraw(_amount, user, user);

        assertEq(sharesOut, _amount, "assets out");
        assertEq(0, strategy.balanceOf(user), "bal");
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        token.mint(user, _amount);

        vm.prank(user);
        token.approve(address(strategy), _amount);

        vm.prank(user);
        uint256 amountOut = strategy.deposit(_amount, user);

        assertEq(amountOut, _amount, "Amount out");
        assertEq(amountOut, strategy.balanceOf(user), "bal");

        skip(10);

        vm.prank(user);
        uint256 assetsOut = strategy.redeem(_amount, user, user);

        assertEq(assetsOut, _amount, "assets out");
        assertEq(0, strategy.balanceOf(user), "bal");
    }
}
