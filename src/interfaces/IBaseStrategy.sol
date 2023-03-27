// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

interface IBaseStrategy {
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

    function invest(uint256 _assets) external;

    function freeFunds(uint256 _amount) external;

    function totalInvested() external returns (uint256);

    function tendThis(uint256 _totalIdle) external;

    function tendTrigger() external view returns (bool);
}
