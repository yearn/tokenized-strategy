// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

// Generic OpenZeppelin Dependencies
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Custom Base Strategy interfacies
import {IBaseStrategy} from "./interfaces/IBaseStrategy.sol";
import {BaseLibrary} from "./libraries/BaseLibrary.sol";

abstract contract BaseStrategy is IBaseStrategy {
    modifier onlySelf() {
        _onlySelf();
        _;
    }

    modifier onlyManagement() {
        BaseLibrary.isManagement();
        _;
    }

    modifier onlyKeepers() {
        BaseLibrary.isKeeper();
        _;
    }

    function _onlySelf() internal view {
        if (msg.sender != address(this)) revert Unauthorized();
    }

    // NOTE: This will be set to internal constants once the library has actually been deployed
    address public baseLibrary;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    // Underlying asset the Strategy is earning yield on
    address public asset;

    // TODO: Should these all be moved to the library to save bytecode

    // The decimals of the underlying asset we will use.
    // Keep this private with a getter function so it can be easily accessed by strategists but not updated
    uint8 private _decimals;

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) {
        _initialize(_asset, _name, _symbol, msg.sender);
    }

    function initialize(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _management
    ) external {
        _initialize(_asset, _name, _symbol, _management);
    }

    // TODO: ADD additional variables for keeper performance fee etc?
    function _initialize(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _management
    ) internal {
        // make sure we have not been initialized
        require(asset == address(0), "!init");

        // set ERC20 variables
        asset = _asset;
        _decimals = IERC20Metadata(_asset).decimals();

        // initilize the strategies storage variables
        BaseLibrary.init(_asset, _name, _symbol, _management);
    }

    /*//////////////////////////////////////////////////////////////
                        BASELIBRARY HOOKS
    //////////////////////////////////////////////////////////////*/

      // These function are left external so they can be called by the BaseLibrary post a delegateCall.   \\
     //  If the library calls an external function of another contract the msg.sender will be the original \\
    //   contract that delegate called the library. Therefore msg.sender will be the strategy itself.       \\

    /**
    * @notice This can only be called after a 'deposit', 'mint' or 'report' delegateCall to the library so msg.sender == address(this).
    * @dev Callback for the library to call during a deposit, mint or report to tell the strategy it can invest funds.
    *
    * Both permisionless deposits and permissioned reports will lead to this function being called with all currently idle funds sent as '_assets'.
    * The '_reported' bool is how to differeniate between the two. If true this means it was called at the end of a report with the expectation of coming
    * through a trusted relay and therefore safe to perform otherwise manipulatable transactions.
    *
    * @param _assets The amount of 'asset' that the strategy should attemppt to deposit in the yield source.
    * @param _reported Bool repersenting if this is part of a permissined 'report'.
    */
    function invest(uint256 _assets, bool _reported) external onlySelf {
        _invest(_assets, _reported);
    }

    /**
    * @notice This can only be called after a 'withdraw' or 'redeem' delegateCall to the library so msg.sender == address(this).
    * @dev Callback for the library to call during a withdraw or redeem to free the needed funds to service the withdraw.
    * @param _amount The amount of 'asset' that the strategy should attemppt to free up.
    */
    function freeFunds(uint256 _amount) external onlySelf {
        _freeFunds(_amount);
    }

    /**
    * @notice This can only be called after a report() delegateCall to the library so msg.sender == address(this).
    * @dev Callback for the library to call during a report to get an accurate accounting of assets the strategy controls.
    * @return . A trusted and accurate account for the total amount of 'asset' the strategy currently holds.
    */
    function totalInvested() external onlySelf returns (uint256) {
        return _totalInvested();
    }

    /**
    * @notice This can only be called after a tend() delegateCall to the library so msg.sender == address(this).
    * @dev Callback for the library to initiate a _tend call in the strategy.
    * @param _totalIdle The amount of current idle funds that can be invested during the tend
     */
    function tendThis(uint256 _totalIdle) external onlySelf {
        _tend(_totalIdle);
    }

    /*//////////////////////////////////////////////////////////////
                    NEEDED TO OVERRIDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    // will invest up to the amount of 'assets' and return the actual amount that was invested
    // TODO: this should be able to invest asset.balnceOf(address(this)) since its always post report/deposit
    //      depositing donated want wont reflect in pps until the next report cycle.
    // Should do any needed param checks, 0 will get passed in as 'assets'
    function _invest(uint256 assets, bool _reported) internal virtual;

    // Will attempt to free the 'amount' of assets and return the acutal amount
    function _freeFunds(uint256 amount) internal virtual;

    /**
    * @dev Internal non-view function to return the accurate amount of funds currently held by the Strategy
    *
    * This shouldo do any needed harvesting, rewards selling, accrual etc. to get the most accurate view of current assets.
    *
    * This can leave any or all assets uninvested if desired as there will always be a _invest() call at the end of the report
    * with '_reported' set as true to differentiate between a normal deposit.
    *
    * Care should be taken when relying on oracles or swap values rather than actual amounts as all Strategy profit/loss accounting
    * will be done based on this returned value.
    *
    * All applicable assets including loose assets should be accounted for in this function.
    *
    * @return . A trusted and accurate account for the total amount of 'asset' the strategy currently holds.
    */
    function _totalInvested() internal virtual returns (uint256);

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
    * @dev Optional trigger to override if tend() will be used by the strategy.
    * This must be implemented if the strategy hopes to invoke _tend().
    *
    * @return . Should return true if tend() should be called by keeper or false if not.
    */
    function tendTrigger() external view virtual returns (bool) {
        return false;
    }

    /**
    @dev Optional function for strategist to override that can be called in between reports
    *
    * This call can only be called by a persionned role so can be trusted to be through protected relays.
    *
    * This can be used to harvest and compound rewards, deposit idle funds, perform needed
    * poisition maintence or anything else that doesn't need a full report for.
    *
    *   EX: A strategy that can not deposit funds without getting sandwhiched
    *   can use the tend when a certain threshold of idle to totalAssets has been reached.
    *
    * The library will do all needed debt and idle updates after this has finished
    * and will have no effect on PPS of the strategy till report() is called.
    *
    * @param _totalIdle The current amount of idle funds that are available to invest.
    */
    function _tend(uint256 _totalIdle) internal virtual {}

    // NOTE: these functions are kept in the Base to give strategists
    //      the ability to override them for illiquid strategies.
    // Made public to allow for the override function to use super.function() for min check

    function maxDeposit(
        address /*_owner*/
    ) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(
        address /*_owner*/
    ) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address _owner)
        public
        view
        virtual
        returns (uint256)
    {
        return BaseLibrary.convertToAssets(BaseLibrary.balanceOf(_owner));
    }

    function maxRedeem(address _owner) public view virtual returns (uint256) {
        return BaseLibrary.balanceOf(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC20 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // NOTE: Do We keep these simple read only function in the Base since they are immutable or move them to the library

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // exeute a function on the baseLibrary and return any value.
    fallback() external payable {
        // load our target address
        // IF needed this could call the helper contract based on the sig to make external library functions unavailable
        address _baseLibrary = baseLibrary;
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(
                gas(),
                _baseLibrary,
                0,
                calldatasize(),
                0,
                0
            )
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
