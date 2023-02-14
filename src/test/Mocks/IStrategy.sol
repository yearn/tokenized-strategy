// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IStrategy is IERC4626 {
    function initialize(
        ERC20 _asset,
        string memory name_,
        string memory symbol_,
        address _management
    ) external;

    // Getters
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