// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {ITokenizedStrategy} from "../../interfaces/ITokenizedStrategy.sol";

// Interface to use during testing that implements the 4626 standard the implementation functions and the Strategies immutable functions
interface IMockStrategy is ITokenizedStrategy {
    function availableDepositLimit(
        address _owner
    ) external view returns (uint256);

    function availableWithdrawLimit(
        address _owner
    ) external view returns (uint256);

    function deployFunds(uint256 _assets) external;

    function freeFunds(uint256 _amount) external;

    function harvestAndReport() external returns (uint256);

    function tendThis(uint256 _totalIdle) external;

    function shutdownWithdraw(uint256 _amount) external;

    function tendTrigger() external view returns (bool);

    function setTrigger(bool _trigger) external;

    function onlyLetManagers() external;

    function onlyLetKeepersIn() external;

    function onlyLetEmergencyAdminsIn() external;

    function yieldSource() external view returns (address);

    function managed() external view returns (bool);

    function kept() external view returns (bool);

    function emergentizated() external view returns (bool);
    
    function dontTend() external view returns (bool);

    function setDontTend(bool _dontTend) external;
}
