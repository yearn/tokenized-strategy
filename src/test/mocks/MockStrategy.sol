// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {MockYieldSource} from "./MockYieldSource.sol";
import {BaseTokenizedStrategy} from "../../BaseTokenizedStrategy.sol";

contract MockStrategy is BaseTokenizedStrategy {
    address public yieldSource;
    bool public trigger;
    bool public managed;
    bool public kept;

    constructor(
        address _asset,
        address _yieldSource
    ) BaseTokenizedStrategy(_asset, "Test Strategy") {
        initialize(_asset, _yieldSource);
    }

    function initialize(address _asset, address _yieldSource) public {
        require(yieldSource == address(0));
        yieldSource = _yieldSource;
        ERC20(_asset).approve(_yieldSource, type(uint256).max);
    }

    function _deployFunds(uint256 _amount) internal override {
        MockYieldSource(yieldSource).deposit(_amount);
    }

    function _freeFunds(uint256 _amount) internal override {
        MockYieldSource(yieldSource).withdraw(_amount);
    }

    function _harvestAndReport() internal override returns (uint256) {
        uint256 balance = ERC20(asset).balanceOf(address(this));
        if (balance > 0) {
            MockYieldSource(yieldSource).deposit(balance);
        }
        return MockYieldSource(yieldSource).balance();
    }

    function _tend(uint256 /*_idle*/) internal override {
        uint256 balance = ERC20(asset).balanceOf(address(this));
        if (balance > 0) {
            MockYieldSource(yieldSource).deposit(balance);
        }
    }

    function tendTrigger() external view override returns (bool) {
        return trigger;
    }

    function setTrigger(bool _trigger) external {
        trigger = _trigger;
    }

    function clone(
        address _asset,
        address _yieldSource
    ) external returns (address) {
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
    ) public returns (address clone_) {
        clone_ = TokenizedStrategy.clone(
            _asset,
            _name,
            _management,
            _pfr,
            _keeper
        );
        MockStrategy(payable(clone_)).initialize(_asset, _yieldSource);
    }

    function onlyLetManagers() public onlyManagement {
        managed = true;
    }

    function onlyLetKeepersIn() public onlyKeepers {
        kept = true;
    }
}
