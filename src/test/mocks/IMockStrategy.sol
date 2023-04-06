// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {ITokenizedStrategy} from "../../interfaces/ITokenizedStrategy.sol";

// Interface to use during testing that implements the 4626 standard the implementation functions and the Strategies immutable functions
interface IMockStrategy is ITokenizedStrategy {
    function initialize(
        address _asset,
        string memory name_,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external;

    function clone(
        address _asset,
        address _yieldSource
    ) external returns (address clone);

    function _clone(
        address _asset,
        string memory _name,
        address _management,
        address _pfr,
        address _keeper,
        address _yieldSource
    ) external returns (address clone);

    function isOriginal() external view returns (bool);

    function availableDepositLimit(
        address _owner
    ) external view returns (uint256);

    function availableWithdrawLimit(
        address _owner
    ) external view returns (uint256);

    function invest(uint256 _assets) external;

    function freeFunds(uint256 _amount) external;

    function totalInvested() external returns (uint256);

    function tendThis(uint256 _totalIdle) external;

    function tendTrigger() external view returns (bool);

    function setTrigger(bool _trigger) external;

    function onlyLetManagers() external;

    function onlyLetKeepersIn() external;

    function yieldSource() external view returns (address);

    function managed() external view returns (bool);

    function kept() external view returns (bool);
}
