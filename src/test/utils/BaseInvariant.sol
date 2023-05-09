// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup, TokenizedStrategy} from "./Setup.sol";

abstract contract BaseInvariant is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    // Simple version used by the straegy to calculate what should be unlocked shares
    function _unlockedShares() internal view returns (uint256 unlockedShares) {
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
            2
        );
        assertApproxEq(
            strategy.maxRedeem(msg.sender),
            strategy.convertToShares(strategy.maxWithdraw(msg.sender)),
            2
        );
    }

    function assert_unlockingTime() public {
        uint256 unlockingDate = strategy.fullProfitUnlockDate();
        uint256 balance = strategy.balanceOf(address(strategy));
        uint256 unlockedShares = _unlockedShares();
        if (unlockingDate != 0 && strategy.profitUnlockingRate() > 0) {
            if (block.timestamp == strategy.lastReport()) {
                assertEq(unlockedShares, 0);
                assertGt(balance, 0);
            } else if (block.timestamp < unlockingDate) {
                assertGt(unlockedShares, 0);
                assertGt(balance, 0);
            } else {
                // We should have unlocked full balance
                assertEq(balance, 0);
                assertGt(unlockedShares, 0);
            }
        } else {
            assertEq(balance, 0);
        }
    }

    function assert_unlockedShares() public {
        uint256 unlockedShares = _unlockedShares();
        uint256 fullBalance = strategy.balanceOf(address(strategy)) +
            unlockedShares;
        uint256 unlockingDate = strategy.fullProfitUnlockDate();
        if (
            unlockingDate != 0 &&
            strategy.profitUnlockingRate() > 0 &&
            block.timestamp < unlockingDate
        ) {
            assertLt(unlockedShares, fullBalance);
        } else {
            assertEq(unlockedShares, fullBalance);
            assertEq(strategy.balanceOf(address(strategy)), 0);
        }
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
