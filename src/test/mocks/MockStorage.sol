// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// use `make inspect contract=MockStorage` to easy view the structs storage layout.
// prettier-ignore
contract MockStorage {
        // The ERC20 compliant underlying asset that will be
        // used by the Strategy
        ERC20 asset;


        // These are the corresponding ERC20 variables needed for the
        // strategies token that is issued and burned on each deposit or withdraw.
        uint8 decimals; // The amount of decimals that `asset` and strategy use.
        uint88 INITIAL_CHAIN_ID; // The initial chain id when the strategy was created.

        string name; // The name of the token for the strategy.
        uint256 totalSupply; // The total amount of shares currently issued.
        bytes32 INITIAL_DOMAIN_SEPARATOR; // The domain separator used for permits on the initial chain.
        mapping(address => uint256) nonces; // Mapping of nonces used for permit functions.
        mapping(address => uint256) balances; // Mapping to track current balances for each account that holds shares.
        mapping(address => mapping(address => uint256)) allowances; // Mapping to track the allowances for the strategies shares.


        // Assets data to track total the strategy holds.
        // We manually track `totalAssets` to prevent PPS manipulation through airdrops.
        uint256 totalAssets;


        // Variables for profit reporting and locking.
        // We use uint96 for time stamps to fit in the same slot as an address.
        // We will surely all be dead by the time the slot overflows.
        uint256 profitUnlockingRate; // The rate at which locked profit is unlocking.
        uint96 fullProfitUnlockDate; // The timestamp at which all locked shares will unlock.
        address keeper; // Address given permission to call {report} and {tend}.
        uint32 profitMaxUnlockTime; // The amount of seconds that the reported profit unlocks over.
        uint16 performanceFee; // The percent in basis points of profit that is charged as a fee.
        address performanceFeeRecipient; // The address to pay the `performanceFee` to.
        uint96 lastReport; // The last time a {report} was called.


        // Access management variables.
        address management; // Main address that can set all configurable variables.
        address pendingManagement; // Address that is pending to take over `management`.
        address emergencyAdmin; // Address to act in emergencies as well as `management`.

     
        // Strategy status checks.
        bool entered; // Bool to prevent reentrancy.
        bool shutdown; // Bool that can be used to stop deposits into the strategy. 
}
