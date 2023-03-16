// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {MockYieldSource} from "./MockYieldSource.sol";
import {BaseStrategy} from "../../BaseStrategy.sol";

contract MockStrategy is BaseStrategy {
    address public yieldSource;

    constructor(
        address _asset,
        address _yieldSource
    ) BaseStrategy(_asset, "Test Strategy") {
        initialize(_asset, _yieldSource);
    }

    function initialize(address _asset, address _yieldSource) public {
        require(yieldSource == address(0));
        yieldSource = _yieldSource;
        ERC20(_asset).approve(_yieldSource, type(uint256).max);
    }

    function _invest(uint256 _amount, bool _reported) internal override {
        MockYieldSource(yieldSource).deposit(_amount);
    }

    function _freeFunds(uint256 _amount) internal override {
        MockYieldSource(yieldSource).withdraw(_amount);
    }

    function _totalInvested() internal override returns (uint256) {
        return
            MockYieldSource(yieldSource).balance() +
            ERC20(asset).balanceOf(address(this));
    }

    function _tend(uint256 /*_idle*/) internal override {
        uint256 balance = ERC20(asset).balanceOf(address(this));
        if (balance > 0) {
            MockYieldSource(yieldSource).deposit(balance);
        }
    }

    function clone(
        address _asset,
        address _yieldSource
    ) external returns (address clone) {
        return
            _clone(
                _asset,
                "Test Clone",
                msg.sender,
                msg.sender,
                msg.sender,
                _yieldSource
            );
    }

    function _clone(
        address _asset,
        string memory _name,
        address _management,
        address _pfr,
        address _keeper,
        address _yieldSource
    ) public returns (address clone) {
        clone = BaseLibrary.clone(_asset, _name, _management, _pfr, _keeper);
        MockStrategy(payable(clone)).initialize(_asset, _yieldSource);
    }
}
