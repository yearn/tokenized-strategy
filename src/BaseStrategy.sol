// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

// Generic OpenZeppelin Dependencies
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Custom Base Strategy interfacies
import {IBaseStrategy} from "./interfaces/IBaseStrategy.sol";
import {BaseLibrary} from "./libraries/BaseLibrary.sol";

// The base contract to inherit from that provides the diamond functionality
import {Diamond} from "./Diamond.sol";

interface IBaseFee {
    function isCurrentBaseFeeAcceptable() external view returns (bool);
}

abstract contract BaseStrategy is Diamond {

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public asset;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // TODO: initialize all variables with the library
    constructor(
        ERC20 _asset,
        string memory name_,
        string memory symbol_
    ) { 
        _initialize(_asset, name_, symbol_, msg.sender);
    }

    function initialize(
        ERC20 _asset,
        string memory name_,
        string memory symbol_,  
        address _management
    ) external {
         _initialize(_asset, name_, symbol_, _management);
    }

    function _initialize(
        ERC20 _asset,
        string memory name_,
        string memory symbol_, 
        address _management
    ) internal {
        // make sure we have not been initialized
        require(address(asset) == address(0), "!init");
        // set up the diamond
        //_diamondSetup();

        // set ERC20 variables
        asset = _asset;
        _name = name_;
        _symbol = symbol_;
        _decimals = IERC20Metadata(address(_asset)).decimals();

        // initilize the strategies storage variables
        BaseLibrary.init(_asset, _management);
    }

    /*//////////////////////////////////////////////////////////////
                   DEPOSIT WITHDRAW HOOKS
    //////////////////////////////////////////////////////////////*/

    // These function are left external so they can be called by the lbrary after deposits and 
    // during withdraws. If the library was delegateCalled from this address then msg.sender will be this address

    function invest(uint256 _assets) external returns (uint256) {
        require(msg.sender == address(this), "!Auth");
        return _invest(_assets);
    }

    function freeFunds(uint256 _amount) external returns (uint256) {
        require(msg.sender == address(this), "!Auth");
        return _freeFunds(_amount);
    }

    /*//////////////////////////////////////////////////////////////
                    NEEDED TO OVERRIDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    // Will attempt to free the 'amount' of assets and return the acutal amount
    function _freeFunds(uint256 amount)
        internal
        virtual
        returns (uint256 withdrawnAmount);

    // will invest up to the amount of 'assets' and return the actual amount that was invested
    // TODO: this should be able to invest asset.balnceOf(address(this)) since its always post report/deposit
    //      depositing donated want wont reflect in pps until the next report cycle.    
    function _invest(uint256 assets)
        internal
        virtual
        returns (uint256 invested);

    // internal non-view function to return the accurate amount of funds currently invested
    // should do any needed accrual etc. before returning the the amount invested
    function _totalInvested() internal virtual returns (uint256);

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/
    
    function _reportTrigger() internal view virtual returns (bool) {
        return false;
        // TODO: should this default to a library reportTrigger ?
        //if (!_isBaseFeeAcceptable()) {
        //    return block.timestamp - _profitStorage().lastReport > _profitStorage().profitMaxUnlockTime;
        //}
    }

    function _tend() internal virtual {}

    function _maxDeposit(address) internal view virtual returns (uint256) {
        return type(uint256).max;
    }

    function _maxMint(address) internal view virtual returns (uint256) {
        return type(uint256).max;
    }

    function _maxWithdraw(address owner)
        internal
        view
        virtual
        returns (uint256)
    {
        return BaseLibrary.convertToAssets(BaseLibrary.balanceOf(owner));
    }

    function _maxRedeem(address owner) internal view virtual returns (uint256) {
        return BaseLibrary.balanceOf(owner);
    }

    /*//////////////////////////////////////////////////////////////
                   EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // TODO: Make non-reentrant for all 4 deposit/withdraw functions

    function reportTrigger() external view returns (bool) {
        return _reportTrigger();
    }

    // NOTE: these functions are kept in the Base due to the simple nature and to give strategist 
    //      the ability to override the internal version for illiquid strategies

    function maxDeposit(address _owner)
        external
        view
        returns (uint256)
    {
        return _maxDeposit(_owner);
    }

    function maxMint(address _owner) external view returns (uint256) {
        return _maxMint(_owner);
    }

    function maxWithdraw(address _owner)
        external
        view
        returns (uint256)
    {
        return _maxWithdraw(_owner);
    }

    function maxRedeem(address _owner) external view returns (uint256) {
        return _maxRedeem(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _isBaseFeeAcceptable() internal view returns (bool) {
        return
            IBaseFee(0xb5e1CAcB567d98faaDB60a1fD4820720141f064F)
                .isCurrentBaseFeeAcceptable();
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
