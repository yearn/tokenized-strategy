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

    function initialize(
        address _asset,
        string memory name_,
        address _management
    ) external;

    function maxDeposit(address _owner) external view returns (uint256);

    function maxMint(address _owner) external view returns (uint256);

    function maxWithdraw(address _owner) external view returns (uint256);

    function maxRedeem(address _owner) external view returns (uint256);

    function invest(uint256 _assets, bool _reported) external;

    function freeFunds(uint256 _amount) external;

    function totalInvested() external returns (uint256);

    function tendThis(uint256 _totalIdle) external;

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * This is based off of the decimals of the underlying asset
     */
    function decimals() external view returns (uint8);
}
