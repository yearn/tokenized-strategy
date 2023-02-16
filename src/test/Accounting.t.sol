// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract AccountingTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_airdropDoesNotIncreasePPS(address _address, uint256 _amount)
        public
    {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        vm.assume(_address != address(0) && _address != address(strategy));

        // set fees to 0 for calculations simplicity
        vm.prank(management);
        strategy.setPerformanceFee(0);

        // nothing has happened pps should be 1
        uint256 pricePerShare = strategy.pricePerShare();
        assertEq(pricePerShare, wad);

        // deposit into the vault
        mintAndDepositIntoStrategy(_address, _amount);
        uint256 strategyBalance = asset.balanceOf(address(strategy));

        // should still be 1
        assertEq(strategy.pricePerShare(), pricePerShare);

        // aidrop to strategy
        uint256 toAirdrop = strategyBalance / 10;
        asset.mint(address(strategy), toAirdrop);

        // nothing should change
        assertEq(strategy.pricePerShare(), pricePerShare);
        assertEq(strategy.totalDebt(), _amount);
        assertEq(strategy.totalIdle(), 0);

        // process a report to realize the gain from the airdrop
        uint256 profit;
        vm.prank(keeper);
        (profit, ) = strategy.report();

        assertEq(strategy.pricePerShare(), pricePerShare);
        assertEq(profit, toAirdrop);
        assertEq(strategy.totalDebt(), _amount + toAirdrop);
        assertEq(strategy.totalIdle(), 0);

        // allow some profit to come unlocked
        skip(profitMaxUnlockTime / 2);

        assertGt(strategy.pricePerShare(), pricePerShare);

        //air drop again, we should not increase again
        pricePerShare = strategy.pricePerShare();
        asset.mint(address(strategy), toAirdrop);
        assertEq(strategy.pricePerShare(), pricePerShare);

        // skip the rest of the time for unlocking
        skip(profitMaxUnlockTime / 2);

        // we should get a 10% return - any rounding down erros for airdrop
        assertRelApproxEq(
            strategy.pricePerShare(),
            wad + (wad / 10),
            maxPPSPercentDelta
        );
        assertEq(strategy.totalDebt(), _amount + toAirdrop);
        assertEq(strategy.totalIdle(), 0);

        uint256 beforeBalance = asset.balanceOf(_address);
        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        // should have pulled out the deposit plus profit that was reported but not the second airdrop
        assertEq(
            asset.balanceOf(_address),
            beforeBalance + _amount + toAirdrop
        );
        assertEq(strategy.totalDebt(), 0);
        assertEq(strategy.totalIdle(), 0);
        assertEq(asset.balanceOf(address(strategy)), toAirdrop);
    }
}
