// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {BaseInvariant, StrategyHandler} from "./utils/BaseInvariant.sol";
import {MultiStrategyHandler, IMockStrategy, MockYieldSource, ERC20Mock} from "./handlers/MultiStrategyHandler.sol";

contract MultiStrategyInvariantTest is BaseInvariant {
    MultiStrategyHandler public multiStrategyHandler;

    function setUp() public override {
        super.setUp();

        setFees(0, 0);

        multiStrategyHandler = new MultiStrategyHandler();

        excludeSender(address(0));
        excludeSender(address(strategy));
        excludeSender(address(asset));
        excludeSender(address(yieldSource));

        targetContract(address(multiStrategyHandler));

        targetSelector(
            FuzzSelector({
                addr: address(multiStrategyHandler),
                selectors: getMultiTargetSelectors()
            })
        );
    }

    function forEach(
        address[] memory _strategies,
        function() external func
    ) internal {
        console.log("Length", _strategies.length);
        for (uint256 i; i < _strategies.length; ++i) {
            // set strategy, asset and yieldsource globally
            strategy = IMockStrategy(_strategies[i]);
            asset = ERC20Mock(strategy.asset());
            yieldSource = MockYieldSource(strategy.yieldSource());
            func();
        }
    }

    function invariant_multi_totalAssets() public {
        console.log("Length", multiStrategyHandler.getStrategies().length);
        forEach(multiStrategyHandler.getStrategies(), this.assert_totalAssets);
    }

    function invariant_multi_idle() public {
        forEach(multiStrategyHandler.getStrategies(), this.assert_idle);
    }

    function invariant_multi_maxWithdraw() public {
        forEach(multiStrategyHandler.getStrategies(), this.assert_maxWithdraw);
    }

    function invariant_multi_maxRedeem() public {
        forEach(multiStrategyHandler.getStrategies(), this.assert_maxRedeem);
    }

    function invariant_multi_maxWithdrawEqualsMaxRedeem() public {
        forEach(
            multiStrategyHandler.getStrategies(),
            this.asert_maxRedeemEqualsMaxWithdraw
        );
    }

    function invariant_multi_unlockingTime() public {
        forEach(multiStrategyHandler.getStrategies(), this.assert_unlockingTime);
    }

    function invariant_multi_unlockedShares() public {
        forEach(multiStrategyHandler.getStrategies(), this.assert_unlockedShares);
    }

    function invariant_multi_totalSupplyToUnlockedShares() public {
        forEach(
            multiStrategyHandler.getStrategies(),
            this.assert_totalSupplyToUnlockedShares
        );
    }

    function invariant_multi_previewMinAndConvertToAssets() public {
        forEach(
            multiStrategyHandler.getStrategies(),
            this.assert_previewMinAndConvertToAssets
        );
    }

    function invariant_multi_previewWithdrawAndConvertToShares() public {
        forEach(
            multiStrategyHandler.getStrategies(),
            this.assert_previewWithdrawAndConvertToShares
        );
    }

    //function invariant_multi_balanceToCoverAssets() public {
    //    forEach(
    //        multiStrategyHandler.getStrategies(),
    //        this.assert_balanceToCoverAssets
    //    );
    //}

    function invariant_multi_callSummary() public {
        multiStrategyHandler.callSummary();
    }

    function getMultiTargetSelectors()
        internal
        view
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](11);
        selectors[0] = multiStrategyHandler.deposit.selector;
        selectors[1] = multiStrategyHandler.withdraw.selector;
        selectors[2] = multiStrategyHandler.mint.selector;
        selectors[3] = multiStrategyHandler.redeem.selector;
        selectors[4] = multiStrategyHandler.reportProfit.selector;
        selectors[5] = multiStrategyHandler.reportLoss.selector;
        selectors[6] = multiStrategyHandler.tend.selector;
        selectors[7] = multiStrategyHandler.approve.selector;
        selectors[8] = multiStrategyHandler.transfer.selector;
        selectors[9] = multiStrategyHandler.transferFrom.selector;
        selectors[10] = multiStrategyHandler.increaseTime.selector;
    }
}
