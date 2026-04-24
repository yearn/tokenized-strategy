// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "forge-std/console.sol";
import {Setup} from "./Setup.sol";

abstract contract BaseInvariant is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function assert_totalAssets(uint256, uint256, uint256, uint256) public {
        uint256 totalAssets_ = strategy.totalAssets();
        uint256 actualAssets = yieldSource.balance() +
            asset.balanceOf(address(strategy));

        if (totalAssets_ != actualAssets) {
            assertEq(totalAssets_, strategy.lastTotalAssets());
        }
    }

    function assert_maxWithdraw() public {
        assertLe(strategy.maxWithdraw(msg.sender), strategy.totalAssets());
        assertLe(
            strategy.maxWithdraw(msg.sender),
            strategy.availableWithdrawLimit(msg.sender)
        );
    }

    function assert_maxRedeem() public {
        assertLe(strategy.maxRedeem(msg.sender), strategy.totalSupply());
        assertLe(
            strategy.maxRedeem(msg.sender),
            strategy.balanceOf(msg.sender)
        );
    }

    function assert_maxRedeemEqualsMaxWithdraw() public {
        assertApproxEq(
            strategy.maxWithdraw(msg.sender),
            strategy.convertToAssets(strategy.maxRedeem(msg.sender)),
            10
        );
        assertApproxEq(
            strategy.maxRedeem(msg.sender),
            strategy.convertToShares(strategy.maxWithdraw(msg.sender)),
            10
        );
    }

    function assert_previewMintAndConvertToAssets() public {
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

    function assert_balanceAndTotalAssets() public {
        assertLe(
            strategy.totalAssets(),
            yieldSource.balance() + asset.balanceOf(address(strategy))
        );
    }
}
