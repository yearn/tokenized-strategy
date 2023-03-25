// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {IBaseLibrary} from ".//IBaseLibrary.sol";

interface IStrategy is IBaseLibrary {
    /*//////////////////////////////////////////////////////////////
                            IMMUTABLE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function isOriginal() external view returns (bool);

    function initialize(
        address _asset,
        string memory name_,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external;

    function availableDepositLimit(
        address _owner
    ) external view returns (uint256);

    function availableWithdrawLimit(
        address _owner
    ) external view returns (uint256);

    function tendTrigger() external view returns (bool);
}