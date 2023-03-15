// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

interface IBaseStrategy {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Reported(
        uint256 indexed profit,
        uint256 indexed loss,
        uint256 indexed fees
    );

    /*//////////////////////////////////////////////////////////////
                                Errors
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

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

    function invest(uint256 _assets, bool _reported) external;

    function freeFunds(uint256 _amount) external;

    function totalInvested() external returns (uint256);

    function tendThis(uint256 _totalIdle) external;
}
