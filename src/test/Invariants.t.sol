// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";
import {StrategyHandler} from "./handlers/StrategyHandler.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract InvariantTest is Setup {

    StrategyHandler public strategyHandler;

    function setUp() public override {
        super.setUp();

        strategyHandler = new StrategyHandler();


        targetContract(address(strategyHandler));
    }

    function invariant_totalAssets() public {
        assertEq(strategy.totalAssets(), strategy.totalIdle() + strategy.totalDebt());
    }

    function invariant_idle() public {
        assertLe(strategy.totalIdle(), asset.balanceOf(address(strategy)));
    }

    // TODO:
    //      Total assets = debt + idle
    //      idle <= balanceOf()
    //      unlcokedShares <= balanceOf(strategy)
    //      PPS doesnt change unless reporting a loss
    //      maxWithdraw <= totalAssets
    //      maxRedeem <= totalSupply
    //      read the unlocking rate and time
}
