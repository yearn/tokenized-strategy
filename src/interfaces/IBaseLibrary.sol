// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

import {IDiamond} from "./IDiamond.sol";
import {IDiamondLoupe} from "./IDiamondLoupe.sol";

// Interface to use during testing that implements the 4626 standard the Library functions and the Strategies immutable functions
interface IBaseLibrary is IERC4626, IERC20Permit, IDiamond, IDiamondLoupe {
    
    struct BaseStrategyData {
        // The ERC20 compliant underlying asset that will be
        // used by the implementation contract.
        ERC20 asset;
        

        // These are the corresponding ERC20 variables needed for the
        // token that is issued and burned on each deposit or withdraw.
        uint8 decimals; // The amount of decimals the asset and strategy use
        string name; // The name of the token for the strategy.
        string symbol; // The symbol of the token for the strategy.
        uint256 totalSupply; // The total amount of shares currently issued
        uint256 INITIAL_CHAIN_ID; // The intitial chain id when the strategy was created.
        bytes32 INITIAL_DOMAIN_SEPARATOR; // The domain seperator used for permits on the intitial chain.
        mapping(address => uint256) nonces; // Mapping of nonces used for permit functions.
        mapping(address => uint256) balances; // Mapping to track current balances for each account that holds shares.
        mapping(address => mapping(address => uint256)) allowances; // Mapping to track the allowances for the strategies shares.
        

        // Assets data to track totals the strategy holds.
        uint256 totalIdle; // The total amount of loose `asset` the strategy holds.
        uint256 totalDebt; // The total amount `asset` that is currently deployed by the strategy
        

        // Variables for profit reporting and locking
        uint256 fullProfitUnlockDate; // The timestamp at which all locked shares will unlock.
        uint256 profitUnlockingRate; // The rate at which locked profit is unlocking.
        uint256 profitMaxUnlockTime; // The amount of seconds that the reported profit unlocks over.
        uint256 lastReport; // The last time a {report} was called.
        uint16 performanceFee; // The percent in Basis points of profit that is charged as a fee.
        address performanceFeeRecipient; // The address to pay the `performanceFee` to.
        

        // Access management addressess for permisssioned functions.
        address management; // Main address that can set all configurable variables.
        address keeper; // Address given permission to call {report} and {tend}.
        bool entered; // Bool to prevent reentrancy.
    }

    function init(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external;

    function isKeeperOrManagement(address _sender) external;

    function isManagement(address _sender) external;

    function tend() external;

    // Base Library functions \\

    function report() external returns (uint256 _profit, uint256 _loss);

    // Getters
    function apiVersion() external returns (string memory);

    function pricePerShare() external view returns (uint256);

    function totalIdle() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function management() external view returns (address);

    function keeper() external view returns (address);

    function performanceFee() external view returns (uint256);

    function performanceFeeRecipient() external view returns (address);

    function fullProfitUnlockDate() external view returns (uint256);

    function profitUnlockingRate() external view returns (uint256);

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

    // Cloning
    function clone(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external returns (address newStrategy);
}
