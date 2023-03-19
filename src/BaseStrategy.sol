// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

// Custom Base Strategy interfacies
import {IBaseStrategy} from "./interfaces/IBaseStrategy.sol";
import {IBaseLibrary} from "./interfaces/IBaseLibrary.sol";

import "forge-std/console.sol";

abstract contract BaseStrategy is IBaseStrategy {
    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlySelf() {
        _onlySelf();
        _;
    }

    modifier onlyManagement() {
        BaseLibrary.isManagement(msg.sender);
        _;
    }

    modifier onlyKeepers() {
        BaseLibrary.isKeeperOrManagement(msg.sender);
        _;
    }

    function _onlySelf() internal view {
        if (msg.sender != address(this)) revert Unauthorized();
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS /IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * This is the address of the BaseLibrary that will be used by all
     * strategies to handle the accounting, logic, storage etc.
     *
     * Any external calls to the strategy that don't hit one of the functions
     * defined in the implementation will end up going to the fallback
     * function, which will delegateCall this address.
     *
     * This address should be the same for every strategy, never be adjusted
     * and always be checked before any integration with the implementation.
     */
    // NOTE: This will be set to internal constants once the library has actually been deployed
    address public constant baseLibraryAddress =
        0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;

    /**
     * This variable is set to address(this) during initialization of each strategy.
     *
     * This can be used to retrieve storage data within the implementation
     * contract as if it were a linked library.
     *
     *       i.e. uint256 totalAssets = BaseLibrary.totalAssets()
     *
     * We use this so that there does not have to be a library actually linked
     * to the strategy when deployed that would rarely be used and only for
     * reading storage. It also standardizies all Base Library interaction.
     *
     * Using address(this) will mean any calls using this variable will lead
     * to a static call to itself. Which will hit the fallback function and
     * delegateCall that to the actual BaseLibrary.
     */
    IBaseLibrary internal BaseLibrary;

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    // Bool for cloning that will only be true for non-clones.
    bool public isOriginal = true;

    // Underlying asset the Strategy is earning yield on.
    address public asset;

    constructor(address _asset, string memory _name) {
        initialize(_asset, _name, msg.sender, msg.sender, msg.sender);
    }

    function initialize(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) public {
        // make sure we have not been initialized
        require(asset == address(0), "!init");

        // Set instance of the library for internal use.
        BaseLibrary = IBaseLibrary(address(this));

        // Set the asset we are using.
        asset = _asset;

        // initilize the strategies storage variables
        _init(_asset, _name, _management, _performanceFeeRecipient, _keeper);
    }

    /*//////////////////////////////////////////////////////////////
                    NEEDED TO OVERRIDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Should invest up to '_amount' of 'asset'.
     *
     * Should do any needed parameter checks. 0 may be passed in as '_amount'.
     *
     * Both permisionless deposits and permissioned reports will lead to
     * this function being called with all currently idle funds sent as
     * '_amount'. The '_reported' bool is how to differeniate between the two.
     * If true this means it was called at the end of a report with the
     * potential of coming through a trusted relay and therefore safe to
     * perform otherwise manipulatable transactions.
     *
     * @param _amount The amount of 'asset' that the strategy should attemppt
     * to deposit in the yield source.
     * @param _reported Bool repersenting if this is part of a permissined 'report'.
     */
    function _invest(uint256 _amount, bool _reported) internal virtual;

    /**
     * @dev Will attempt to free the '_amount' of 'asset'.
     *
     * The amount of 'asset' that is already loose has already
     * been accounted for.
     *
     * Should do any needed parameter checks, '_amount' may be more than
     * is actually available.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting puroposes.
     *
     * @param _amount, The amount of 'asset' to be freed.
     */
    function _freeFunds(uint256 _amount) internal virtual;

    /**
     * @dev Internal non-view function to return the accurate amount
     * of funds currently held by the Strategy
     *
     * This should do any needed harvesting, rewards selling, accrual
     * etc. to get the most accurate view of current assets.
     *
     * This can leave any or all assets uninvested if desired as there
     * will always be a _invest() call at the end of the report with
     * '_reported' set as true to differentiate between a normal deposit.
     *
     * Care should be taken when relying on oracles or swap values rather
     * than actual amounts as all Strategy profit/loss accounting will
     * be done based on this returned value.
     *
     * All applicable assets including loose assets should be accounted
     * for in this function.
     *
     * @return _invested A trusted and accurate account for the total
     * amount of 'asset' the strategy currently holds.
     */
    function _totalInvested() internal virtual returns (uint256 _invested);

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Optional function for strategist to override that can
     *  be called in between reports.
     *
     * If '_tend' is used tendTrigger() will also need to be overridden.
     *
     * This call can only be called by a persionned role so may be
     * through protected relays.
     *
     * This can be used to harvest and compound rewards, deposit idle funds,
     * perform needed poisition maintence or anything else that doesn't need
     * a full report for.
     *
     *   EX: A strategy that can not deposit funds without getting
     *       sandwhiched can use the tend when a certain threshold
     *       of idle to totalAssets has been reached.
     *
     * The library will do all needed debt and idle updates after this
     * has finished and will have no effect on PPS of the strategy till
     * report() is called.
     *
     * @param _totalIdle The current amount of idle funds that are available to invest.
     */
    function _tend(uint256 _totalIdle) internal virtual {}

    /**
     * @notice Returns wether or not tend() should be called by a keeper.
     * @dev Optional trigger to override if tend() will be used by the strategy.
     * This must be implemented if the strategy hopes to invoke _tend().
     *
     * @return . Should return true if tend() should be called by keeper or false if not.
     */
    function tendTrigger() external view virtual returns (bool) {
        return false;
    }

    // NOTE: these functions are kept in the Base to give strategists
    // the ability to override them to limit deposit or withdraws for
    // andy strategies that want to implement deposit limts, whitelists, illiquid strategies etc.

    function availableDepositLimit(
        address /*_owner*/
    ) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function availableWithdrawLimit(
        address /*_owner*/
    ) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /*//////////////////////////////////////////////////////////////
                        BASELIBRARY HOOKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Should invest up to '_amount' of 'asset'.
     * @dev Callback for the library to call during a deposit, mint
     * or report to tell the strategy it can invest funds.
     *
     * This can only be called after a 'deposit', 'mint' or 'report'
     * delegateCall to the library so msg.sender == address(this).
     *
     * Both permisionless deposits and permissioned reports will lead
     * to this function being called with all currently idle funds sent
     * as '_assets'. The '_reported' bool is how to differeniate between
     * the two. If true this means it was called at the end of a report
     * with the expectation of coming through a trusted relay and therefore
     * safe to perform otherwise manipulatable transactions.
     *
     * @param _amount The amount of 'asset' that the strategy should
     * attemppt to deposit in the yield source.
     * @param _reported Bool repersenting if this is part of a `report`.
     */
    function invest(uint256 _amount, bool _reported) external onlySelf {
        _invest(_amount, _reported);
    }

    /**
     * @notice Will attempt to free the '_amount' of 'asset'.
     * @dev Callback for the library to call during a withdraw or redeem
     * to free the needed funds to service the withdraw.
     *
     * This can only be called after a 'withdraw' or 'redeem' delegateCall
     * to the library so msg.sender == address(this).
     *
     * @param _amount The amount of 'asset' that the strategy should attemppt to free up.
     */
    function freeFunds(uint256 _amount) external onlySelf {
        _freeFunds(_amount);
    }

    /**
     * @notice Returns the accurate amount of all funds currently
     * held by the Strategy.
     * @dev Callback for the library to call during a report to
     * get an accurate accounting of assets the strategy controls.
     *
     * This can only be called after a report() delegateCall to the
     * library so msg.sender == address(this).
     *
     * @return _invested A trusted and accurate account for the total
     * amount of 'asset' the strategy currently holds.
     */
    function totalInvested() external onlySelf returns (uint256 _invested) {
        return _totalInvested();
    }

    /**
     * @notice Will call the internal '_tend' when a keeper tends the strategy.
     * @dev Callback for the library to initiate a _tend call in the strategy.
     *
     * This can only be called after a tend() delegateCall to the library 
     * so msg.sender == address(this).
     *
     * We name the function `tendThis` so that `tend` calls are forwarded to 
     * the library so it can do the neccesary accounting.

     * @param _totalIdle The amount of current idle funds that can be 
     * invested during the tend
     */
    function tendThis(uint256 _totalIdle) external onlySelf {
        _tend(_totalIdle);
    }

    /**
     * @dev Funciton used on initilization to delegate call the
     * library to setup the default storage for the strategy.
     *
     * We cannot use the `BaseLibrary` variable call since this
     * contract is not deployed fully yet. So we need to manually
     * delegateCall the library.
     *
     * This is the only time an internal delegateCall should not
     * be for a view function
     */
    function _init(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) private {
        (bool success, ) = baseLibraryAddress.delegatecall(
            abi.encodeWithSignature(
                "init(address,string,address,address,address)",
                _asset,
                _name,
                _management,
                _performanceFeeRecipient,
                _keeper
            )
        );

        require(success, "init failed");
    }

    // exeute a function on the baseLibrary and return any value.
    fallback() external payable {
        // load our target address
        address _baseLibraryAddress = baseLibraryAddress;
        // Execute external function using delegatecall and return any value.
        assembly {
            // Copy function selector and any arguments.
            calldatacopy(0, 0, calldatasize())
            // Execute function delegatecall.
            let result := delegatecall(
                gas(),
                _baseLibraryAddress,
                0,
                calldatasize(),
                0,
                0
            )
            // Get any return value
            returndatacopy(0, 0, returndatasize())
            // Return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * We are forced to have a receive function do to
     * implementing a fallback function.
     *
     * NOTE: ETH should not be sent to the strategy unless
     * designed for within the implementation
     */
    receive() external payable {}
}
