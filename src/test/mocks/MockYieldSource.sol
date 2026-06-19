// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockYieldSource {
    address public asset;
    uint256 public pendingRewards;
    uint256 public pendingLoss;
    address internal constant LOSS_SINK =
        0x000000000000000000000000000000000000dEaD;

    constructor(address _asset) {
        asset = _asset;
    }

    function deposit(uint256 _amount) public {
        ERC20(asset).transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) public {
        uint256 _balance = balance();
        _amount = _amount > _balance ? _balance : _amount;
        ERC20(asset).transfer(msg.sender, _amount);
    }

    function balance() public view returns (uint256) {
        uint256 currentBalance = ERC20(asset).balanceOf(address(this));
        return
            currentBalance > pendingRewards
                ? currentBalance - pendingRewards
                : 0;
    }

    function queueRewards(uint256 _amount) public {
        pendingRewards += _amount;
    }

    function queueLoss(uint256 _amount) public {
        pendingLoss += _amount;
    }

    function harvest()
        public
        returns (uint256 harvested, uint256 realizedLoss)
    {
        harvested = pendingRewards;
        realizedLoss = pendingLoss;
        pendingRewards = 0;
        pendingLoss = 0;
        if (realizedLoss > 0) {
            ERC20(asset).transfer(LOSS_SINK, realizedLoss);
        }
    }

    function simulateLoss(uint256 _amount) public {
        ERC20(asset).transfer(msg.sender, _amount);
    }
}
