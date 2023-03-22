// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";
import {StrategyHandler} from "./handlers/StrategyHandler.sol";

import {BaseLibrary} from "../libraries/BaseLibrary.sol";

contract SingleStrategyInvariantTest is Setup {
    StrategyHandler public strategyHandler;

    function setUp() public override {
        super.setUp();

        setFees(0, 0);

        strategyHandler = new StrategyHandler();

        excludeSender(address(0));
        excludeSender(address(strategy));
        excludeSender(address(asset));
        excludeSender(address(yieldSource));

        targetContract(address(strategyHandler));

        targetSelector(
            FuzzSelector({
                addr: address(strategyHandler),
                selectors: getTargetSelectors()
            })
        );
    }

    function invariant_totalAssets() public {
        assertEq(
            strategy.totalAssets(),
            strategy.totalIdle() + strategy.totalDebt()
        );
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

    function invariant_callSummary() public view {
        strategyHandler.callSummary();
    }

    bytes32 private constant BASE_STRATEGY_STORAGE =
        bytes32(uint256(keccak256("yearn.base.strategy.storage")) - 1);

    function _baseStrategyStorgage()
        private
        pure
        returns (BaseLibrary.BaseStrategyData storage S)
    {
        // Since STORAGE_SLOT is a constant, we have to put a variable
        // on the stack to access it from an inline assembly block.
        bytes32 slot = BASE_STRATEGY_STORAGE;
        assembly {
            S.slot := slot
        }
    }

    // Simple version used by the straegy to calculate what should be unlocked shares
    function _unlockedShares() private view returns (uint256 unlockedShares) {
        uint256 _fullProfitUnlockDate = strategy.fullProfitUnlockDate();
        if (_fullProfitUnlockDate > block.timestamp) {
            unlockedShares =
                (strategy.profitUnlockingRate() *
                    (block.timestamp - strategy.lastReport())) /
                1_000_000_000_000;
        }
    }

    function getTargetSelectors()
        internal
        view
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](11);
        selectors[0] = strategyHandler.deposit.selector;
        selectors[1] = strategyHandler.withdraw.selector;
        selectors[2] = strategyHandler.mint.selector;
        selectors[3] = strategyHandler.redeem.selector;
        selectors[4] = strategyHandler.reportProfit.selector;
        selectors[5] = strategyHandler.reportLoss.selector;
        selectors[6] = strategyHandler.tend.selector;
        selectors[7] = strategyHandler.approve.selector;
        selectors[8] = strategyHandler.transfer.selector;
        selectors[9] = strategyHandler.transferFrom.selector;
        selectors[10] = strategyHandler.increaseTime.selector;
    }
}
