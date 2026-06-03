// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import {BaseInvariant} from "./utils/BaseInvariant.sol";
import {ConstantAccrualHandler} from "./handlers/ConstantAccrualHandler.sol";

contract ConstantAccrualInvariantTest is BaseInvariant {
    address internal constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    ConstantAccrualHandler public constantAccrualHandler;

    function setUp() public override {
        super.setUp();

        setFees(100, 1_000);

        constantAccrualHandler = new ConstantAccrualHandler();

        excludeSender(address(0));
        excludeSender(address(strategy));
        excludeSender(address(asset));
        excludeSender(address(yieldSource));
        excludeSender(keeper);
        excludeSender(management);
        excludeSender(emergencyAdmin);
        excludeSender(protocolFeeRecipient);
        excludeSender(performanceFeeRecipient);
        excludeSender(DEAD_ADDRESS);

        targetContract(address(constantAccrualHandler));

        targetSelector(
            FuzzSelector({
                addr: address(constantAccrualHandler),
                selectors: getTargetSelectors()
            })
        );
    }

    function invariant_latchedAssets() public {
        if (strategy.lastAccrual() == block.timestamp) {
            assertEq(
                strategy.totalAssets(),
                strategy.lastTotalAssets(),
                "latched assets"
            );
        } else {
            assertEq(
                strategy.totalAssets(),
                constantAccrualHandler.actualAssets(),
                "unlatched assets"
            );
        }
    }

    function invariant_bufferAccounting() public {
        uint256 unlockedShares = strategy.unlockedShares();
        uint256 rawBuffer = constantAccrualHandler.rawStrategyBuffer();
        uint256 visibleBuffer = strategy.balanceOf(address(strategy));
        uint256 fullProfitUnlockDate = strategy.fullProfitUnlockDate();
        uint256 profitUnlockingRate = strategy.profitUnlockingRate();

        if (fullProfitUnlockDate == 0) {
            assertEq(rawBuffer, 0, "date cleared with buffer");
        }

        if (profitUnlockingRate > 0 && fullProfitUnlockDate > block.timestamp) {
            assertGt(rawBuffer, 0, "rate without buffer");
            assertGt(visibleBuffer, 0, "future unlock without visible buffer");
            assertLt(unlockedShares, rawBuffer, "fully unlocked before date");
        }

        if (
            fullProfitUnlockDate != 0 && fullProfitUnlockDate <= block.timestamp
        ) {
            assertEq(visibleBuffer, 0, "expired visible buffer");
            assertEq(
                unlockedShares,
                rawBuffer,
                "expired buffer not fully unlocked"
            );
        }
    }

    function invariant_supplyConservation() public {
        assertApproxEq(
            strategy.totalSupply(),
            constantAccrualHandler.trackedSupply(),
            1,
            "tracked supply"
        );
    }

    function invariant_handlerAccountingProperties() public {
        assertEq(
            constantAccrualHandler.accountingViolations(),
            0,
            "handler accounting violation"
        );
    }

    function invariant_maxWithdraw() public {
        assert_maxWithdraw();
    }

    function invariant_maxRedeem() public {
        assert_maxRedeem();
    }

    function invariant_maxWithdrawEqualsMaxRedeem() public {
        assert_maxRedeemEqualsMaxWithdraw();
    }

    function invariant_previewMintAndConvertToAssets() public {
        assert_previewMintAndConvertToAssets();
    }

    function invariant_previewWithdrawAndConvertToShares() public {
        assert_previewWithdrawAndConvertToShares();
    }

    function invariant_callSummary() public view {
        constantAccrualHandler.callSummary();
    }

    function test_wiredConstantAccrualHandlerActionsDoNotRevert() public {
        constantAccrualHandler.deposit(1e18);
        constantAccrualHandler.liveProfit(1e17);
        skip(1);
        constantAccrualHandler.syncViaManagementSetter();
        constantAccrualHandler.sameBlockDoubleAccrual(1e17);
        constantAccrualHandler.setProfitMaxUnlockTime(0);
        assertEq(
            constantAccrualHandler.accountingViolations(),
            0,
            "handler accounting violation"
        );
    }

    function getTargetSelectors()
        internal
        view
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](19);
        selectors[0] = constantAccrualHandler.deposit.selector;
        selectors[1] = constantAccrualHandler.mint.selector;
        selectors[2] = constantAccrualHandler.withdraw.selector;
        selectors[3] = constantAccrualHandler.redeem.selector;
        selectors[4] = constantAccrualHandler.liveProfit.selector;
        selectors[5] = constantAccrualHandler.liveLoss.selector;
        selectors[6] = constantAccrualHandler.queueReportProfit.selector;
        selectors[7] = constantAccrualHandler.queueReportLoss.selector;
        selectors[8] = constantAccrualHandler.report.selector;
        selectors[9] = constantAccrualHandler.reportWithQueuedProfit.selector;
        selectors[10] = constantAccrualHandler.reportWithQueuedLoss.selector;
        selectors[11] = constantAccrualHandler.tendNeutral.selector;
        selectors[12] = constantAccrualHandler.skipSmall.selector;
        selectors[13] = constantAccrualHandler.skipToHalfUnlock.selector;
        selectors[14] = constantAccrualHandler.skipPastUnlock.selector;
        selectors[15] = constantAccrualHandler.setFees.selector;
        selectors[16] = constantAccrualHandler.syncViaManagementSetter.selector;
        selectors[17] = constantAccrualHandler.sameBlockDoubleAccrual.selector;
        selectors[18] = constantAccrualHandler.setProfitMaxUnlockTime.selector;
    }
}
