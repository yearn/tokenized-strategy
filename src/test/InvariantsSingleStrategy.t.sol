// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {BaseInvariant} from "./utils/BaseInvariant.sol";
import {StrategyHandler} from "./handlers/StrategyHandler.sol";

contract SingleStrategyInvariantTest is BaseInvariant {
    StrategyHandler public strategyHandler;

    function setUp() public override {
        super.setUp();

        setFees(100, 1_000);

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
        assert_totalAssets(
            strategyHandler.ghost_depositSum(),
            strategyHandler.ghost_withdrawSum(),
            strategyHandler.ghost_profitSum(),
            strategyHandler.ghost_lossSum()
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

    function invariant_unlockingTime() public {
        assert_unlockingTime();
    }

    function invariant_unlockedShares() public {
        assert_unlockedShares();
    }

    function invariant_previewMintAndConvertToAssets() public {
        assert_previewMintAndConvertToAssets();
    }

    function invariant_previewWithdrawAndConvertToShares() public {
        assert_previewWithdrawAndConvertToShares();
    }

    function invariant_balanceAndTotalAssets() public {
        if (!strategyHandler.unreported()) {
            assert_balanceAndTotalAssets();
        }
    }

    function invariant_callSummary() public view {
        strategyHandler.callSummary();
    }

    function getTargetSelectors()
        internal
        view
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](12);
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
        selectors[11] = strategyHandler.unreportedLoss.selector;
    }
}
