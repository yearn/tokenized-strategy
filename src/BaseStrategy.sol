// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.14;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {BaseLibrary} from "./libraries/BaseLibrary.sol";

interface IBaseFee {
    function isCurrentBaseFeeAcceptable() external view returns (bool);
}

abstract contract BaseStrategy {
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Reported(
        uint256 indexed profit,
        uint256 indexed loss,
        uint256 indexed fees
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // storage slot to use for asset amount variables
    bytes32 internal constant ASSETS_STRATEGY_STORAGE = 
        bytes32(uint256(keccak256("yearn.assets.strategy.storage")) - 1);

    // storage slot to use for report/ profit locking variables
    bytes32 internal constant PROFIT_LOCKING_STORAGE =
        bytes32(uint256(keccak256("yearn.profit.locking.storage")) - 1);

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    struct AssetsData {
        uint256 totalIdle;
        uint256 totalDebt;
    }

    struct ProfitData {
        uint256 fullProfitUnlockDate;
        uint256 profitUnlockingRate;
        uint256 profitMaxUnlockTime;
        uint256 lastReport;
        uint256 performanceFee;
        address treasury;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public management;

    modifier onlyManagement() {
        _onlyManagement();
        _;
    }

    function _onlyManagement() internal view {
        require(msg.sender == management, "not vault");
    }

    constructor(
        ERC20 _asset,
        string memory name_,
        string memory symbol_
    ) { 
        asset = _asset;
        _name = name_;
        _symbol = symbol_;
        _decimals = IERC20Metadata(address(_asset)).decimals();
        management = msg.sender;

        _profitStorage().profitMaxUnlockTime = 10 days;
        _profitStorage().lastReport = block.timestamp;
    }

    function totalAssets() public view returns (uint256) {
        return BaseLibrary.totalAssets();
    }

    // TODO: Make non-reentrant for all 4 deposit/withdraw functions

    function deposit(uint256 assets, address receiver)
        public
        returns (uint256 shares)
    {
        // check lower than max
        require(
            assets <= _maxDeposit(receiver),
            "ERC4626: deposit more than max"
        );

        // allow library to handle deposit
        shares = BaseLibrary.deposit(asset, assets, receiver);

        _depositFunds(assets);
    }

    function mint(uint256 shares, address receiver)
        public
        returns (uint256 assets)
    {
        require(shares <= _maxMint(receiver), "ERC4626: mint more than max");

        assets = BaseLibrary.mint(asset, shares, receiver);

        _depositFunds(assets);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public returns (uint256 shares) {
        require(
            assets <= _maxWithdraw(owner),
            "ERC4626: withdraw more than max"
        );

        // pre withdraw hook
        shares = BaseLibrary.beforeWithdraw(assets, owner);

        // free up the funds needed
        _freeFunds(assets);

        // post withdraw library hook
        BaseLibrary.afterWithdraw(asset, assets, shares, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public returns (uint256 assets) {
        require(shares <= _maxRedeem(owner), "ERC4626: redeem more than max");

        // pre redeem hook
        assets = BaseLibrary.beforeRedeem(shares, owner);

        // free up the funds needed
        _freeFunds(assets);

        // post withdraw library hook
        BaseLibrary.afterWithdraw(asset, assets, shares, receiver, owner);
    }

    function reportTrigger() external view returns (bool) {
        return _reportTrigger();
    }

    /*//////////////////////////////////////////////////////////////
                        STORAGE GETTERS
    //////////////////////////////////////////////////////////////*/

    function _assetsStorage() private pure returns (AssetsData storage s) {
        // Since STORAGE_SLOT is a constant, we have to put a variable
        // on the stack to access it from an inline assembly block.
        bytes32 slot = PROFIT_LOCKING_STORAGE;
        assembly {
            s.slot := slot
        }
    }

    function _profitStorage() private pure returns (ProfitData storage s) {
        // Since STORAGE_SLOT is a constant, we have to put a variable
        // on the stack to access it from an inline assembly block.
        bytes32 slot = PROFIT_LOCKING_STORAGE;
        assembly {
            s.slot := slot
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function report() external onlyManagement returns (uint256 profit, uint256 loss) {
        uint256 invested = _totalInvested();

        (profit, loss) = BaseLibrary.report(invested);

        // invest any idle funds
        _depositFunds(0);
    }

    // post deposit/report hook to deposit any loose funds
    function _depositFunds(uint256 _newAmount) internal {
        AssetsData storage a = _assetsStorage();

        // invest if applicable
        uint256 toInvest = a.totalIdle + _newAmount;
        uint256 invested = _invest(toInvest);

        // adjust total Assets
        a.totalDebt += invested;
        // check if we invested all the loose asset
        a.totalIdle = invested >= toInvest ? 0 : toInvest - invested;
    }

    function _freeFunds(uint256 _amount) internal {
        AssetsData storage a = _assetsStorage();

        // withdraw if we dont have enough idle
        uint256 idle = a.totalIdle;
        uint256 withdrawn = idle >= _amount ? _withdraw(_amount) : 0;

        // adjust state variables
        a.totalIdle -= idle > _amount ? _amount : idle;
        a.totalDebt -= withdrawn;
    }

    // TODO: These should probably not be virtual?

    function convertToShares(uint256 assets)
        public
        view
        returns (uint256)
    {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply() is non-zero.

        return
            supply == 0
                ? assets
                : assets.mulDiv(supply, totalAssets(), Math.Rounding.Down);
    }

    function convertToAssets(uint256 shares)
        public
        view
        returns (uint256)
    {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply() is non-zero.

        return
            supply == 0
                ? shares
                : shares.mulDiv(totalAssets(), supply, Math.Rounding.Down);
    }

    function previewDeposit(uint256 assets)
        public
        view
        returns (uint256)
    {
        return BaseLibrary.previewDeposit(assets);
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        return BaseLibrary.previewMint(shares);
    }

    function previewWithdraw(uint256 assets)
        public
        view
        returns (uint256)
    {
        return BaseLibrary.previewRedeem(assets);
    }

    function previewRedeem(uint256 shares)
        public
        view
        returns (uint256)
    {
        return BaseLibrary.previewRedeem(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

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
                    NEEDED TO OVERRIDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    // Will attempt to free the 'amount' of assets and return the acutal amount
    function _withdraw(uint256 amount)
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
        if (!_isBaseFeeAcceptable()) {
            return block.timestamp - _profitStorage().lastReport > _profitStorage().profitMaxUnlockTime;
        }
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
        return convertToAssets(balanceOf(owner));
    }

    function _maxRedeem(address owner) internal view virtual returns (uint256) {
        return balanceOf(owner);
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

    function totalSupply() public view returns (uint256) {
        return BaseLibrary.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return BaseLibrary.balanceOf(_owner);
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return BaseLibrary.allowance(_owner, _spender);
    }

    function transfer(address to, uint256 amount)
        public
        returns (bool)
    {
        return BaseLibrary.transfer(to, amount);
    }

    function approve(address spender, uint256 amount)
        public
        returns (bool)
    {
        return BaseLibrary.approve(spender, amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        return BaseLibrary.transferFrom(from, to, amount);
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        return BaseLibrary.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        return BaseLibrary.decreaseAllowance(spender, subtractedValue);
    }
}
