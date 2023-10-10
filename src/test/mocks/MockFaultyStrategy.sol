// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {MockYieldSource} from "./MockYieldSource.sol";
import {BaseStrategy, ERC20} from "../../BaseStrategy.sol";

interface IPappa {
    function callBack(
        uint256 _pps,
        uint256 _convertAmountToShares,
        uint256 _convertAmountToAssets
    ) external;
}

contract MockFaultyStrategy is BaseStrategy {
    address public yieldSource;
    bool public dontTend;
    address public pappa;
    uint256 public fault;
    bool public doCallBack;

    constructor(
        address _asset,
        address _yieldSource
    ) BaseStrategy(_asset, "Test Strategy") {
        yieldSource = _yieldSource;
        ERC20(_asset).approve(_yieldSource, type(uint256).max);
        pappa = msg.sender;
    }

    function _deployFunds(uint256 _amount) internal override {
        if (doCallBack) {
            callBack(_amount);
        }
        MockYieldSource(yieldSource).deposit(_amount + fault);
    }

    function _freeFunds(uint256 _amount) internal override {
        if (doCallBack) callBack(_amount);
        MockYieldSource(yieldSource).withdraw(_amount + fault);
    }

    function _harvestAndReport() internal override returns (uint256) {
        uint256 balance = ERC20(asset).balanceOf(address(this));
        if (balance > 0) {
            MockYieldSource(yieldSource).deposit(balance);
        }
        uint256 total = MockYieldSource(yieldSource).balance();
        if (doCallBack) callBack(total);
        return total;
    }

    function _tend(uint256 _idle) internal override {
        if (dontTend) return;
        if (doCallBack) callBack(_idle);
        uint256 balance = ERC20(asset).balanceOf(address(this));
        if (balance > 0) {
            MockYieldSource(yieldSource).deposit(balance);
        }
    }

    function setDontTend(bool _dontTend) external {
        dontTend = _dontTend;
    }

    function setFaultAmount(uint256 _fault) public {
        fault = _fault;
    }

    function setCallBack(bool _bool) public {
        doCallBack = _bool;
    }

    // This means we are in the middle of a strategy function.
    // We will simulate a view reentrancy.
    function callBack(uint256 _amount) public {
        IPappa(pappa).callBack(
            TokenizedStrategy.pricePerShare(),
            TokenizedStrategy.convertToShares(_amount),
            TokenizedStrategy.convertToAssets(_amount)
        );
    }
}
