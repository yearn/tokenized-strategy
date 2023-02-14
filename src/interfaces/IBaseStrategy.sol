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

    function maxDeposit(address _owner) external view returns (uint256);

    function maxMint(address _owner) external view returns (uint256);

    function maxWithdraw(address _owner) external view returns (uint256);

    function maxRedeem(address _owner) external view returns (uint256);

    function invest(uint256 _assets) external returns (uint256);

    function freeFunds(uint256 _amount) external returns (uint256);

    function totalInvested() external returns (uint256);

    function tend() external;
}
