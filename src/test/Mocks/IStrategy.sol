// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

// Interface to use during testing that implements the 4626 standard the Library functions and the Strategies immutable functions
interface IStrategy is IERC4626 {
    // errors
    error Unauthorized();

    function initialize(
        address _asset,
        string memory name_,
        string memory symbol_,
        address _management
    ) external;

    function invest(uint256 _assets) external returns (uint256);

    function freeFunds(uint256 _amount) external returns (uint256);

    function totalInvested() external returns (uint256);

    function tend() external;

    // Base Library functions \\

    function init(address _asset, address _management) external;

    function report() external returns (uint256 _profit, uint256 _loss);

    // Getters
    function pricePerShare() external view returns (uint256);

    function totalIdle() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function management() external view returns (address);

    function keeper() external view returns (address);

    function performanceFee() external view returns (uint256);

    function treasury() external view returns (address);

    function profitMaxUnlockTime() external view returns (uint256);

    // Setters
    function setManagement(address) external;

    function setKeeper(address _keeper) external;

    function setPerformanceFee(uint256 _performanceFee) external;

    function setTreasury(address _treasury) external;

    function setProfitMaxUnlockTime(uint256 _profitMaxUnlockTime) external;
}
