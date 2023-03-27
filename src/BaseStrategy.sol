// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

// BaseLibrary interface used for internal view delegateCalls.
import {IBaseLibrary} from "./interfaces/IBaseLibrary.sol";

/**
 * @title YearnV3 Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to be a fully
 *  permisionless ERC-4626 compliant Vault. It utilizes a simplified and
 *  immutable version of the ERC-2535 'Diamond Pattern' to keep the BaseStrategy
 *  simple and small. All needed logic is held withen the `BaseLibrary` and
 *  is reused over any n strategies all using the `fallback` function to
 *  delegatecall this library so that strategists can only be concerned
 *  with writing the implementation specific code.
 *
 *  This contract should be inherited and the three main abstract methods
 *  `_invest`, `_freeFunds` and `_totalInvested` implemented to adapt the
 *  Strategy to the particular needs it has to create a return. There are
 *  other optional methods that can be implemented to further customize
 *  the strategy if desired.
 *
 *  All default storage for the implementation wil will controlled and
 *  updated by the `BaseLibrary`. The library holds a storage struct that
 *  contains all needed global variables in a manual storage slot at roughly
 *  1e77. This means strategists can feel free to implement their own storage
 *  variables as they need with no concern of collisions. All global variables
 *  can be viewed within the implementation by a simple call using the
 *  `BaseLibrary` variable. IE: BaseLibrary.globalVariable();.
 */
abstract contract BaseStrategy {
    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Used on library callback function to make sure it is post
     * a delegateCall from this address to the library.
     */
    modifier onlySelf() {
        _onlySelf();
        _;
    }

    /**
     * @dev Use to assure that the call is coming from the strategies mangement.
     */
    modifier onlyManagement() {
        BaseLibrary.isManagement(msg.sender);
        _;
    }

    /**
     * @dev Use to assure that the call is coming from either the strategies
     * management or the keeper.
     */
    modifier onlyKeepers() {
        BaseLibrary.isKeeperOrManagement(msg.sender);
        _;
    }

    function _onlySelf() internal view {
        require(msg.sender == address(this), "!Authorized");
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
    // NOTE: This is a holder address based on expected deterministic location for testing
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

    /**
     * @notice Used to intialize the strategy on deployment or after cloning.
     * @dev This can only be called once. It will be called automatically
     * by the library during a cloning.
     *
     * This will set the `BaseLibrary` variable for easy internal view
     * calls to the library. As well telling the library to initialize the
     * defualt storage variables based on the parameters given.
     *
     * @param _asset Address of the underlying asset.
     * @param _name Name the strategy will use.
     * @param _management Address to set as the strategies `management`.
     * @param _performanceFeeRecipient Address to receive performance fees.
     * @param _keeper Address to set as strategies `keeper`.
     */
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
                NEEDED TO BE OVERRIDDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Should invest up to '_amount' of 'asset'.
     *
     * This function is called at the end of a {deposit} or {mint}
     * call. Meaning that unless a whitelist is implemented it will
     * be entirely permsionless and thus can be sandwhiched or otherwise
     * manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy should attemppt
     * to deposit in the yield source.
     */
    function _invest(uint256 _amount) internal virtual;

    /**
     * @dev Will attempt to free the '_amount' of 'asset'.
     *
     * The amount of 'asset' that is already loose has already
     * been accounted for.
     *
     * This function is called {withdraw} and {redeem} calls.
     * Meaning that unless a whitelist is implemented it will be
     * entirely permsionless and thus can be sandwhiched or otherwise
     * manipulated.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting puroposes.
     *
     * Any difference between `_amount` and what is actually freed will be
     * counted as a loss and passed on to the withdrawer. This means
     * care should be taken in times of illiquidity. It may be better to revert
     * if withdraws are simply illiquid so not to realize incorrect losses.
     *
     * @param _amount, The amount of 'asset' to be freed.
     */
    function _freeFunds(uint256 _amount) internal virtual;

    /**
     * @dev Internal non-view function to harvest all rewards, reinvest
     * and return the accurate amount of funds currently held by the Strategy.
     *
     * This should do any needed harvesting, rewards selling, accrual,
     * reinvesting etc. to get the most accurate view of current assets.
     *
     * All applicable assets including loose assets should be accounted
     * for in this function.
     *
     * Care should be taken when relying on oracles or swap values rather
     * than actual amounts as all Strategy profit/loss accounting will
     * be done based on this returned value.
     *
     * This can still be called post a shutdown, a strategist can check
     * `BaseLibrary.isShutdown()` to decide if funds should be reinvested
     * or simply realize any profits/losses.
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

    /**
     * @notice Gets the max amount of `asset` that an adress can deposit.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overriden by strategists.
     *
     * This function will be called before any deposit or mints to enforce
     * any limits desired by the strategist. This can be used for either a
     * traditional deposit limit or for implementing a whitelist.
     *
     *   EX:
     *      if(isAllowed[_owner]) return super.availableDepositLimit(_owner);
     *
     * This does not need to take into account any conversion rates
     * from shares to assets.
     *
     * @param . The address that is depositing into the strategy.
     * @return . The avialable amount the `_owner can deposit in terms of `asset`
     */
    function availableDepositLimit(
        address /*_owner*/
    ) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Gets the max amount of `asset` that can be withdrawn.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overriden by strategists.
     *
     * This function will be called before any withdraw or redeem to enforce
     * any limits desired by the strategist. This can be used for illiquid
     * or sandwhichable strategies. It should never be lower than `totalIdle`.
     *
     *   EX:
     *       return BaseLibray.totalIdle();
     *
     * This does not need to take into account the `_owner`'s share balance
     * or conversion rates from shares to assets.
     *
     * @param . The address that is withdrawing from the strategy.
     * @return . The avialable amount that can be withdrawn in terms of `asset`
     */
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
     * @dev Callback for the library to call during a {deposit} or {mint}
     * to tell the strategy it can invest funds.
     *
     * Since this can only be called after a {deposit} or {mint}
     * delegateCall to the library msg.sender == address(this).
     *
     * Unless a whitelist is implemented this will be entirely permsionless
     * and thus can be sandwhiched or otherwise manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy should
     * attemppt to deposit in the yield source.
     */
    function invest(uint256 _amount) external onlySelf {
        _invest(_amount);
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
