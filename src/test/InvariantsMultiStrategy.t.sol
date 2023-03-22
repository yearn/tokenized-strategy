// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {BaseInvariant, StrategyHandler} from "./utils/BaseInvariant.sol";
import {MultiStrategyHandler, IMockStrategy, MockYieldSource, ERC20Mock} from "./handlers/MultiStrategyHandler.sol";

contract MultiStrategyInvariantTest is BaseInvariant {
    MultiStrategyHandler public strategyHandler;

    function setUp() public override {
        super.setUp();

        setFees(0, 0);

        strategyHandler = new MultiStrategyHandler();

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

    function forEach(
        address[] memory _strategies,
        function() external func
    ) internal {
        for (uint256 i; i < _strategies.length; ++i) {
            // set strategy, asset and yieldsource globally
            strategy = IMockStrategy(_strategies[i]);
            asset = ERC20Mock(strategy.asset());
            yieldSource = MockYieldSource(strategy.yieldSource());
            func();
        }
    }

    function invariant_totalAssets() public {
        forEach(strategyHandler.getStrategies(), this.assert_totalAssets);
    }

    function invariant_idle() public {
        forEach(strategyHandler.getStrategies(), this.assert_idle);
    }

    function invariant_maxWithdraw() public {
        forEach(strategyHandler.getStrategies(), this.assert_maxWithdraw);
    }

    function invariant_maxRedeem() public {
        forEach(strategyHandler.getStrategies(), this.assert_maxRedeem);
    }

    function invariant_maxWithdrawEqualsMaxRedeem() public {
        forEach(
            strategyHandler.getStrategies(),
            this.asert_maxRedeemEqualsMaxWithdraw
        );
    }

    function invariant_unlockingTime() public {
        forEach(strategyHandler.getStrategies(), this.assert_unlockingTime);
    }

    function invariant_unlockedShares() public {
        forEach(strategyHandler.getStrategies(), this.assert_unlockedShares);
    }

    function invariant_totalSupplyToUnlockedShares() public {
        forEach(
            strategyHandler.getStrategies(),
            this.assert_totalSupplyToUnlockedShares
        );
    }

    function invariant_balanceToCoverAssets() public {
        forEach(
            strategyHandler.getStrategies(),
            this.assert_balanceToCoverAssets
        );
    }

    function invariant_previewMinAndConvertToAssets() public {
        forEach(
            strategyHandler.getStrategies(),
            this.assert_previewMinAndConvertToAssets
        );
    }

    function invariant_previewWithdrawAndConvertToShares() public {
        forEach(
            strategyHandler.getStrategies(),
            this.assert_previewWithdrawAndConvertToShares
        );
    }

    function invariant_callSummary() public {
        strategyHandler.callSummary();
    }

    function getTargetSelectors()
        internal
        view
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](11);
        selectors[0] = MultiStrategyHandler.deposit.selector;
        selectors[1] = MultiStrategyHandler.withdraw.selector;
        selectors[2] = MultiStrategyHandler.mint.selector;
        selectors[3] = MultiStrategyHandler.redeem.selector;
        selectors[4] = MultiStrategyHandler.reportProfit.selector;
        selectors[5] = MultiStrategyHandler.reportLoss.selector;
        selectors[6] = MultiStrategyHandler.tend.selector;
        selectors[7] = MultiStrategyHandler.approve.selector;
        selectors[8] = MultiStrategyHandler.transfer.selector;
        selectors[9] = MultiStrategyHandler.transferFrom.selector;
        selectors[10] = MultiStrategyHandler.increaseTime.selector;
    }
}
