// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

// Interface to use during testing that implements the 4626 standard the Library functions and the Strategies immutable functions
interface IStrategy is IERC4626, IERC20Permit {
    // errors
    error Unauthorized();

    function isKeeper() external;

    function isManagement() external;

    function initialize(
        address _asset,
        string memory name_,
        string memory symbol_,
        address _management
    ) external;

    function invest(uint256 _assets, bool _reported) external;

    function freeFunds(uint256 _amount) external;

    function totalInvested() external returns (uint256);

    function tendThis(uint256 _totalIdle) external;

    function tend() external;

    // Base Library functions \\

    //function init(address _asset, string memory _name, string memory _symbol, address _management) external;

    function report() external returns (uint256 _profit, uint256 _loss);

    // Getters
    function pricePerShare() external view returns (uint256);

    function totalIdle() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function management() external view returns (address);

    function keeper() external view returns (address);

    function performanceFee() external view returns (uint256);

    function performanceFeeRecipient() external view returns (address);

    function profitMaxUnlockTime() external view returns (uint256);

    function lastReport() external view returns (uint256);

    // Setters
    function setManagement(address) external;

    function setKeeper(address _keeper) external;

    function setPerformanceFee(uint16 _performanceFee) external;

    function setPerformanceFeeRecipient(
        address _performanceFeeRecipient
    ) external;

    function setProfitMaxUnlockTime(uint256 _profitMaxUnlockTime) external;

    // ERC20

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);
}
