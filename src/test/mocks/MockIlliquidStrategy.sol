// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {MockYieldSource} from "./MockYieldSource.sol";
import {BaseTokenizedStrategy, ERC20} from "../../BaseTokenizedStrategy.sol";

contract MockIlliquidStrategy is BaseTokenizedStrategy {
    address public yieldSource;
    bool public whitelist;
    mapping(address => bool) public allowed;

    constructor(
        address _asset,
        address _yieldSource
    ) BaseTokenizedStrategy(_asset, "Test Strategy") {
        yieldSource = _yieldSource;
        ERC20(_asset).approve(_yieldSource, type(uint256).max);
    }

    function _deployFunds(uint256 _amount) internal override {
        MockYieldSource(yieldSource).deposit(_amount / 2);
    }

    function _freeFunds(uint256 _amount) internal override {
        //MockYieldSource(yieldSource).withdraw(_amount);
    }

    function _harvestAndReport() internal override returns (uint256) {
        uint256 balance = ERC20(asset).balanceOf(address(this));
        if (balance > 0) {
            MockYieldSource(yieldSource).deposit(balance / 2);
        }
        return
            MockYieldSource(yieldSource).balance() +
            ERC20(asset).balanceOf(address(this));
    }

    function _tend(uint256 /*_idle*/) internal override {
        uint256 balance = MockYieldSource(yieldSource).balance();
        if (balance > 0) {
            MockYieldSource(yieldSource).withdraw(balance);
        }
    }

    function availableDepositLimit(
        address _owner
    ) public view override returns (uint256) {
        if (whitelist && !allowed[_owner]) {
            return 0;
        } else {
            return super.availableDepositLimit(_owner);
        }
    }

    function availableWithdrawLimit(
        address /*_owner*/
    ) public view override returns (uint256) {
        return TokenizedStrategy.totalIdle();
    }

    function setWhitelist(bool _bool) external {
        whitelist = _bool;
    }

    function allow(address _address) external {
        allowed[_address] = true;
    }
}
