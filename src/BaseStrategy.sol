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
                   DEPOSIT WITHDRAW HOOKS
    //////////////////////////////////////////////////////////////*/

    // These function are left external so they can be called by the lbrary after deposits and
    // during withdraws. If the library was delegateCalled from this address then msg.sender will be this address

    function invest(uint256 _assets, bool _reported) external onlySelf {
        _invest(_assets, _reported);
    }

    function freeFunds(uint256 _amount) external onlySelf {
        _freeFunds(_amount);
    }

    function totalInvested() external onlySelf returns (uint256) {
        return _totalInvested();
    }

    function tend() external onlyKeepers {
        _tend();
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

    // internal non-view function to return the accurate amount of funds currently invested
    // should do any needed accrual etc. before returning the the amount invested
    // This can leave all assets uninvested if desired as there will always be a _invest() call at the end of the report
    function _totalInvested() internal virtual returns (uint256);

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    // Optional trigger if tend() will be used to reinvest profit between reports
    function tendTrigger() external view virtual returns (bool) {
        return false;
    }

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
