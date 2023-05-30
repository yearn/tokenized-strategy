// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

// Interface that implements the 4626 standard and the implementation functions
interface ITokenizedStrategy is IERC4626, IERC20Permit {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UpdateManagement(address indexed newManagement);

    event UpdateKeeper(address indexed newKeeper);

    event UpdatePerformanceFee(uint16 newPerformanceFee);

    event UpdatePerformanceFeeRecipient(
        address indexed newPerformanceFeeRecipient
    );

    event UpdateProfitMaxUnlockTime(uint256 newProfitMaxUnlockTime);

    event StrategyShutdown();

    event Reported(
        uint256 profit,
        uint256 loss,
        uint256 performanceFees,
        uint256 protocolFees
    );

    event Cloned(address indexed clone, address indexed original);

    /*//////////////////////////////////////////////////////////////
                           INITILIZATION
    //////////////////////////////////////////////////////////////*/

    function init(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external;

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    function isKeeperOrManagement(address _sender) external view;

    function isManagement(address _sender) external view;

    function isShutdown() external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                        KEEPERS FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function tend() external;

    function report() external returns (uint256 _profit, uint256 _loss);

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    function apiVersion() external view returns (string memory);

    function pricePerShare() external view returns (uint256);

    function totalIdle() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function management() external view returns (address);

    function keeper() external view returns (address);

    function performanceFee() external view returns (uint16);

    function performanceFeeRecipient() external view returns (address);

    function fullProfitUnlockDate() external view returns (uint256);

    function profitUnlockingRate() external view returns (uint256);

    function profitMaxUnlockTime() external view returns (uint256);

    function lastReport() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/
    function setManagement(address) external;

    function setKeeper(address _keeper) external;

    function setPerformanceFee(uint16 _performanceFee) external;

    function setPerformanceFeeRecipient(
        address _performanceFeeRecipient
    ) external;

    function setProfitMaxUnlockTime(uint256 _profitMaxUnlockTime) external;

    function shutdownStrategy() external;

    /*//////////////////////////////////////////////////////////////
                           ERC20 ADD ONS
    //////////////////////////////////////////////////////////////*/

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    /*//////////////////////////////////////////////////////////////
                            CLONING
    //////////////////////////////////////////////////////////////*/

    function clone(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external returns (address newStrategy);
}
