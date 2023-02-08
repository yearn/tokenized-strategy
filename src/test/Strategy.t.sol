// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

//import "forge-std/Test.sol";

import {Setup} from "./utils/Setup.sol";

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
}