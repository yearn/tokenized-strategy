// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup, TokenizedStrategy} from "./Setup.sol";

abstract contract BaseInvariant is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    bytes32 private constant BASE_STRATEGY_STORAGE =
        bytes32(uint256(keccak256("yearn.base.strategy.storage")) - 1);

    function _strategyStorgage()
        private
        pure
        returns (TokenizedStrategy.StrategyData storage S)
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

    function assert_totalAssets() public {
        assertEq(
            strategy.totalAssets(),
            strategy.totalIdle() + strategy.totalDebt()
        );
    }

    function assert_idle() public {
        assertLe(strategy.totalIdle(), asset.balanceOf(address(strategy)));
    }

    function assert_maxWithdraw() public {
        assertLe(strategy.maxWithdraw(msg.sender), strategy.totalAssets());
    }

    function assert_maxRedeem() public {
        assertLe(strategy.maxRedeem(msg.sender), strategy.totalSupply());
    }

    function asert_maxRedeemEqualsMaxWithdraw() public {
        assertApproxEq(
            strategy.maxWithdraw(msg.sender),
            strategy.convertToAssets(strategy.maxRedeem(msg.sender)),
            1
        );
        assertApproxEq(
            strategy.maxRedeem(msg.sender),
            strategy.convertToShares(strategy.maxWithdraw(msg.sender)),
            2
        );
    }

    function assert_unlockingTime() public {
        uint256 unlockingDate = strategy.fullProfitUnlockDate();
        uint256 fullBalance = _strategyStorgage().balances[address(strategy)];
        if (unlockingDate != 0) {
            if (block.timestamp < unlockingDate) {
                assertLe(_unlockedShares(), fullBalance);
            } else {
                // We should have unlocked full balance
                assertEq(strategy.balanceOf(address(strategy)), 0);
            }
        } else {
            assertEq(fullBalance, 0);
        }
    }

    function assert_unlockedShares() public {
        assertLe(
            _unlockedShares(),
            _strategyStorgage().balances[address(strategy)]
        );
    }

    function assert_totalSupplyToUnlockedShares() public {
        assertLe(_strategyStorgage().totalSupply, _unlockedShares());
    }

    function assert_previewMinAndConvertToAssets() public {
        assertApproxEq(
            strategy.previewMint(wad),
            strategy.convertToAssets(wad),
            1
        );
    }

    function assert_previewWithdrawAndConvertToShares() public {
        assertApproxEq(
            strategy.previewWithdraw(wad),
            strategy.convertToShares(wad),
            1
        );
    }

    function assert_balanceToCoverAssets() public {
        assertLe(
            strategy.totalAssets(),
            yieldSource.balance() + asset.balanceOf(address(strategy))
        );
    }
}
