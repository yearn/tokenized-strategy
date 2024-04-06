// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18;

import {IStrategy} from "../../interfaces/IStrategy.sol";

// Interface to use during testing that implements the 4626 standard
// the implementation functions, the Strategies immutable functions
// as well as the added functions for the Mock Strategy.
interface IMockStrategy is IStrategy {
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
