// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

// Generic OpenZeppelin Dependencies
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Custom Base Strategy interfacies
import {IBaseStrategy} from "./interfaces/IBaseStrategy.sol";
import {BaseLibrary} from "./libraries/BaseLibrary.sol";

// The base contract to inherit from that provides the diamond functionality
import {Diamond} from "./Diamond.sol";

abstract contract BaseStrategy is Diamond, IBaseStrategy {
    modifier onlySelf() {
        _onlySelf();
        _;
    }

    function _onlySelf() internal view {
        if (msg.sender != address(this)) revert Unauthorized();
    }

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    // Underlying asset the Strategy is earning yield on
    address public asset;

    // TODO: Should these all be moved to the library to save bytecode

    // The decimals of the underlying asset we will use as well
    uint8 private _decimals;
    // The Name  of the strategy
    string private _name;
    // The symbol used for the ERC20 implementation
    string private _symbol;

    constructor(
        address _asset,
        string memory name_,
        string memory symbol_
    ) {
        _initialize(_asset, name_, symbol_, msg.sender);
    }

    function initialize(
        address _asset,
        string memory name_,
        string memory symbol_,
        address _management
    ) external {
        _initialize(_asset, name_, symbol_, _management);
    }

    // TODO: ADD additional variables for keeper performance fee etc?
    function _initialize(
        address _asset,
        string memory name_,
        string memory symbol_,
        address _management
    ) internal {
        // make sure we have not been initialized
        require(asset == address(0), "!init");
        // set up the diamond
        _diamondSetup();

        // set ERC20 variables
        asset = _asset;
        _name = name_;
        _symbol = symbol_;
        _decimals = IERC20Metadata(_asset).decimals();

        // initilize the strategies storage variables
        BaseLibrary.init(_asset, _management);
    }

    /*//////////////////////////////////////////////////////////////
                   DEPOSIT WITHDRAW HOOKS
    //////////////////////////////////////////////////////////////*/

    // These function are left external so they can be called by the lbrary after deposits and
    // during withdraws. If the library was delegateCalled from this address then msg.sender will be this address

    function invest(uint256 _assets) external onlySelf returns (uint256) {
        return _invest(_assets);
    }

    function freeFunds(uint256 _amount) external onlySelf returns (uint256) {
        return _freeFunds(_amount);
    }

    function totalInvested() external onlySelf returns (uint256) {
        return _totalInvested();
    }

    function tend() external {
        // call the library modifier?
        BaseLibrary._onlyKeepers();
        _tend();
    }

    /*//////////////////////////////////////////////////////////////
                    NEEDED TO OVERRIDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    // will invest up to the amount of 'assets' and return the actual amount that was invested
    // TODO: this should be able to invest asset.balnceOf(address(this)) since its always post report/deposit
    //      depositing donated want wont reflect in pps until the next report cycle.
    // Should do any needed param checks, 0 will get passed in as 'assets'
    function _invest(uint256 assets)
        internal
        virtual
        returns (uint256 invested);

    // Will attempt to free the 'amount' of assets and return the acutal amount
    function _freeFunds(uint256 amount)
        internal
        virtual
        returns (uint256 withdrawnAmount);

    // internal non-view function to return the accurate amount of funds currently invested
    // should do any needed accrual etc. before returning the the amount invested
    // This can leave all assets uninvested if desired as there will always be a _invest() call at the end of the report
    function _totalInvested() internal virtual returns (uint256);

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    // TODO: Decide if we want to leave these commented out and default to library to save bytecod
    //      Could then be implemented in the inherited version if desired
    //      Saves ~ .22KB of size

    /*
    // The trigger used to determine when a keeper should have the strategy report profit
    function reportTrigger() external view virtual returns (bool) {
        return BaseLibrary.reportTrigger();
    }

    // Optional trigger if tend() will be used to reinvest profit between reports
    function tendTrigger() external view virtual returns (bool) {
        return false;
    }
    **/

    // Optional function that should simply realize profits to compound between reports
    // This will do no accounting and no effect any pps of the vault till report() is called
    function _tend() internal virtual {}

    // NOTE: these functions are kept in the Base to give strategists
    //      the ability to override them for illiquid strategies

    function maxDeposit(
        address /*_owner*/
    ) external view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(
        address /*_owner*/
    ) external view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address _owner)
        external
        view
        virtual
        returns (uint256)
    {
        return BaseLibrary.convertToAssets(BaseLibrary.balanceOf(_owner));
    }

    function maxRedeem(address _owner) external view virtual returns (uint256) {
        return BaseLibrary.balanceOf(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC20 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // NOTE: We keep these simple read only function in the Base since they are immutable

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
