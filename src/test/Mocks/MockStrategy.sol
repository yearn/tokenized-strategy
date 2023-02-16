// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {BaseStrategy, BaseLibrary} from "../../BaseStrategy.sol";

contract MockStrategy is BaseStrategy {
    constructor(address _asset)
        BaseStrategy(_asset, "Test Strategy", "tsSTGY")
    {}

    function _invest(uint256 _amount) internal override returns (uint256) {
        return _amount;
    }

    function _freeFunds(uint256 _amount) internal override returns (uint256) {
        return _amount;
    }

    function _totalInvested() internal override returns (uint256) {
        return ERC20(asset).balanceOf(address(this));
    }
}
