// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {MockYieldSource} from "./MockYieldSource.sol";
import {BaseStrategy} from "../../BaseStrategy.sol";

contract MockStrategy is BaseStrategy {
    
    address public yieldSource;

    constructor(address _asset, address _yieldSource)
        BaseStrategy(_asset, "Test Strategy", "tsSTGY")
    {
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
        return MockYieldSource(yieldSource).balance() + ERC20(asset).balanceOf(address(this));
    }
}
