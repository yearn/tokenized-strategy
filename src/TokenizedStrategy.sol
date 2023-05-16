// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IFactory} from "./interfaces/IFactory.sol";
import {IBaseTokenizedStrategy} from "./interfaces/IBaseTokenizedStrategy.sol";

import "forge-std/console.sol";

/**
 * @title YearnV3 Tokenized Strategy
 * @author yearn.finance
 * @notice
 *  This TokenizedStrategy can be used by anyone wishing to easily build
 *  and deploy their own custom ERC4626 compliant single strategy Vault.
 *  This TokenizedStrategy contract is meant to be used as a proxy type
 *  implementation contract that will hanle all logic, storage and
 *  mangement for a custom strategy that inherits the `BaseTokenizedStrategy.
 *  Any function calls to the strategy that are not defined would be forwarded
 *  through a delegateCall to this contract. Any strategy only needs to override
 *  a few simple functions that are focused entirely on the strategy specific
 *  needs to easily and cheaply deploy their own permisionless vault.
 */
contract TokenizedStrategy {
    using Math for uint256;
    using SafeERC20 for ERC20;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted whent the 'mangement' address is updtaed to 'newManagement'.
     */
    event UpdateManagement(address indexed newManagement);

    /**
     * @notice Emitted whent the 'keeper' address is updtaed to 'newKeeper'.
     */
    event UpdateKeeper(address indexed newKeeper);

    /**
     * @notice Emitted whent the 'performaneFee' is updtaed to 'newPerformanceFee'.
     */
    event UpdatePerformanceFee(uint16 newPerformanceFee);

    /**
     * @notice Emitted whent the 'performanceFeeRecipient' address is
     * updtaed to 'newPerformanceFeeRecipient'.
     */
    event UpdatePerformanceFeeRecipient(
        address indexed newPerformanceFeeRecipient
    );

    /**
     * @notice Emitted whent the 'profitMaxUnlockTime' is updtaed to 'newProfitMaxUnlockTime'.
     */
    event UpdateProfitMaxUnlockTime(uint256 newProfitMaxUnlockTime);

    /**
     * @notice Emitted when a strategy is shutdown.
     */
    event StrategyShutdown();

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

    /**
     * @dev Emitted when the `caller` has exchanged `assets` for `shares`,
     * and transferred those `shares` to `owner`.
     */
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Emitted when the `caller` has exchanged `owner`s `shares` for `assets`,
     * and transferred those `assets` to `receiver`.
     */
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Emitted when the strategy reports `profit` or `loss` and
     * `performanceFees` and `protocolFees` are paid out.
     */
    event Reported(
        uint256 profit,
        uint256 loss,
        uint256 protocolFees,
        uint256 performanceFees
    );

    /**
     * @dev Emitted on the initialization of any new `strategy` that uses `asset`
     * with this specific `apiVersion`.
     */
    event NewTokenizedStrategy(
        address indexed strategy,
        address indexed asset,
        string apiVersion
    );

    /**
     * @dev Emitted when a new `clone` is created from an `original`.
     */
    event Cloned(address indexed clone, address indexed original);

    /*//////////////////////////////////////////////////////////////
                        STORAGE STRUCT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev The struct that will hold all the data for each strategy that
     * uses this implementation.
     *
     * This replaces all state variables for a traditional contract. This
     * full struct will be initiliazed on the createion of the strategy
     * and continually updated and read from for the life of the contract.
     *
     * We combine all the variables into one struct to limit the amount of
     * times the custom storage slots need to be loaded during complex functions.
     *
     * Loading the corresponding storage slot for the struct does not
     * load any of the contents of the struct into memory. So the size
     * has no effect on gas usage.
     */
    // prettier-ignore
    struct StrategyData {
        // The ERC20 compliant underlying asset that will be
        // used by the Strategy. We can keep this as and ERC20 
        // instance because the `BaseTokenizedStrategy` holds the
        // addres of `asset` as an immutable variable to be 4626 compliant.
        ERC20 asset;
        

        // These are the corresponding ERC20 variables needed for the
        // strategies token that is issued and burned on each deposit or withdraw.
        uint8 decimals; // The amount of decimals that `asset` and strategy use
        bytes11 symbol; // The symbol of the token for the strategy.
        string name; // The name of the token for the strategy.
        uint256 totalSupply; // The total amount of shares currently issued
        uint256 INITIAL_CHAIN_ID; // The intitial chain id when the strategy was created.
        bytes32 INITIAL_DOMAIN_SEPARATOR; // The domain seperator used for permits on the intitial chain.
        mapping(address => uint256) nonces; // Mapping of nonces used for permit functions.
        mapping(address => uint256) balances; // Mapping to track current balances for each account that holds shares.
        mapping(address => mapping(address => uint256)) allowances; // Mapping to track the allowances for the strategies shares.
        

        // Assets data to track totals the strategy holds.
        // We manually track idle instead of relying on asset.balanceOf(address(this))
        // to prevent PPS manipulation through airdrops.
        uint256 totalIdle; // The total amount of loose `asset` the strategy holds.
        uint256 totalDebt; // The total amount `asset` that is currently deployed by the strategy
        

        // Variables for profit reporting and locking
        // We use uint128 for time stamps which is 1,025 years in the future.
        uint256 profitUnlockingRate; // The rate at which locked profit is unlocking.
        uint128 fullProfitUnlockDate; // The timestamp at which all locked shares will unlock.
        uint128 lastReport; // The last time a {report} was called.
        uint32 profitMaxUnlockTime; // The amount of seconds that the reported profit unlocks over.
        uint16 performanceFee; // The percent in basis points of profit that is charged as a fee.
        address performanceFeeRecipient; // The address to pay the `performanceFee` to.


        // Access management variables.
        address management; // Main address that can set all configurable variables.
        address keeper; // Address given permission to call {report} and {tend}.
        bool entered; // Bool to prevent reentrancy.
        bool shutdown; // Bool that can be used to stop deposits into the strategy.
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Require that the call is coming from the strategies mangement.
     */
    modifier onlyManagement() {
        isManagement(msg.sender);
        _;
    }

    /**
     * @dev Require that the call is coming from either the strategies
     * management or the keeper.
     */
    modifier onlyKeepers() {
        isKeeperOrManagement(msg.sender);
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Placed over all state changing functions for increased safety.
     */
    modifier nonReentrant() {
        StrategyData storage S = _strategyStorage();
        // On the first call to nonReentrant, `entered` will be false
        require(!S.entered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        S.entered = true;

        _;

        // Reset to false once call has finished
        S.entered = false;
    }

    /**
     * @dev Will stop new deposits if the strategy has been shutdown.
     * This will not effect withdraws which can never be paused or stopped.
     */
    modifier notShutdown() {
        require(!isShutdown(), "shutdown");
        _;
    }

    /**
     * @notice To check if a sender is the management for a specific strategy.
     * @dev Is left public so that it can be used by the Strategy.
     *
     * When the Strategy calls this the msg.sender would be the
     * address of the strategy so we need to specify the sender.
     */
    function isManagement(address _sender) public view {
        require(_sender == _strategyStorage().management, "!Authorized");
    }

    /**
     * @notice To check if a sender is the keeper or management
     * for a specific strategy.
     * @dev Is left public so that it can be used by the Strategy.
     *
     * When the Strategy calls this the msg.sender would be the
     * address of the strategy so we need to specify the sender.
     */
    function isKeeperOrManagement(address _sender) public view {
        StrategyData storage S = _strategyStorage();
        require(_sender == S.keeper || _sender == S.management, "!Authorized");
    }

    /**
     * @notice To check if the strategy has been shutdown.
     * @dev Is left public so that it can be used by the Strategy.
     *
     * We don't revert here so this can be used for the external getter
     * for the `shutdown` variable as well.
     */
    function isShutdown() public view returns (bool) {
        return _strategyStorage().shutdown;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // Api version this TokenizedStrategy implements.
    string private constant API_VERSION = "3.1.0";

    // Used for fee calculations.
    uint256 private constant MAX_BPS = 10_000;
    // Used for profit unlocking rate calculations.
    uint256 private constant MAX_BPS_EXTENDED = 1_000_000_000_000;

    // Address of the previously deployed Vault factory that the
    // protocl fee config is retrieved from.
    // NOTE: This will be set to deployed factory. deterministic address for testing is used now
    address private constant FACTORY =
        0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;

    /**
     * @dev Custom storgage slot that will be used to store the
     * `StrategyData` struct that holds each strategies
     * specific storage variables.
     *
     * Any storage updates done by the TokenizedStrategy actually update
     * the storage of the calling contract. This variable points
     * to the specic location that will be used to store the
     * struct that holds all that data.
     *
     * We use a custom string in order to get a random
     * storage slot that will allow for stratgists to use any
     * amount of storage in their strategy without worrying
     * about collisions.
     */
    bytes32 private constant BASE_STRATEGY_STORAGE =
        bytes32(uint256(keccak256("yearn.base.strategy.storage")) - 1);

    /*//////////////////////////////////////////////////////////////
                    STORAGE GETTER FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev will return the actaul storage slot where the strategy
     * sepcific `StrategyData` struct is stored for both read
     * and write operations.
     *
     * This loads just the slot location, not the full struct
     * so it can be used in a gas effecient manner.
     */
    function _strategyStorage() private pure returns (StrategyData storage S) {
        // Since STORAGE_SLOT is a constant, we have to put a variable
        // on the stack to access it from an inline assembly block.
        bytes32 slot = BASE_STRATEGY_STORAGE;
        assembly {
            S.slot := slot
        }
    }

    /*//////////////////////////////////////////////////////////////
                INITILIZATION OF DEFAULT STORAGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Used to initialize storage for a newly deployed strategy.
     * @dev This should be called atomically whenever a new strategy is
     * deployed or cloned, and can only be called once for each strategy.
     *
     * This will set all the default storage that must be set for a
     * strategy to function. Any changes can be made post deployment
     * through external calls from `management`.
     *
     * The function will also emit an event that off chain indexers can
     * look for to track any new deployments using this TokenizedStrategy.
     *
     * This is called through a lowelevel call in the BaseTokenizedStrategy
     * so any reverts will return the "init failed" string.
     *
     * @param _asset Address of the underlying asset.
     * @param _name Name the strategy will use.
     * @param _management Address to set as the strategies `management`.
     * @param _performanceFeeRecipient Address to receive performance fees.
     * @param _keeper Address to set as strategies `keeper`.
     */
    function init(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external {
        // Cache storage pointer
        StrategyData storage S = _strategyStorage();

        // Make sure we aren't initiliazed.
        require(address(S.asset) == address(0));
        // Cache the asset instance for multiple uses
        ERC20 a = ERC20(_asset);
        // Set the strategys underlying asset
        S.asset = a;
        // Set the Strategy Tokens name.
        S.name = _name;
        // Set the symbol and decimals based off the `asset`.
        // This stores the symbol as bytes11 so it can be
        // packed in the struct with `asset` and `decimals`
        S.symbol = bytes11(abi.encodePacked("ys", a.symbol()));
        S.decimals = a.decimals();
        // Set initial chain id for permit replay protection
        S.INITIAL_CHAIN_ID = block.chainid;
        // Set the inital domain seperator for permit functions
        S.INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();

        // Default to a 10 day profit unlock period
        S.profitMaxUnlockTime = 10 days;
        // Set address to receive performance fees.
        // Can't be address(0) or we will be burning fees.
        require(_performanceFeeRecipient != address(0));
        // Can't mint shares to its self because of profit locking.
        require(_performanceFeeRecipient != address(this));
        S.performanceFeeRecipient = _performanceFeeRecipient;
        // Default to a 10% performance fee.
        S.performanceFee = 1_000;
        // Set last report to this block.
        S.lastReport = uint128(block.timestamp);

        // Set the default management address. Can't be 0.
        require(_management != address(0));
        S.management = _management;
        // Set the keeper address
        S.keeper = _keeper;

        // Emit event to signal a new strategy has been initialized.
        emit NewTokenizedStrategy(address(this), _asset, API_VERSION);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 FUNCIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints `shares` of strategy shares to `receiver` by
     * depositing exactly `assets` of underlying tokens.
     * @param assets The amount of underlying to deposit in.
     * @param receiver The address to receive the `shares`.
     * @return shares The actual amount of shares issued.
     */
    function deposit(
        uint256 assets,
        address receiver
    ) external notShutdown nonReentrant returns (uint256 shares) {
        // Check for rounding error.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        _deposit(receiver, assets, shares);
    }

    /**
     * @notice Mints exactly `shares` of strategy shares to
     * `receiver` by depositing `assets` of underlying tokens.
     * @param shares The amount of strategy shares mint.
     * @param receiver The address to receive the `shares`.
     * @return assets The actual amount of asset deposited.
     */
    function mint(
        uint256 shares,
        address receiver
    ) external notShutdown nonReentrant returns (uint256 assets) {
        // Check for rounding error.
        require((assets = previewMint(shares)) != 0, "ZERO_ASSETS");

        _deposit(receiver, assets, shares);
    }

    /**
     * @notice Redeems `shares` from `owner` and sends `assets`
     * of underlying tokens to `receiver`.
     * @param assets The amount of underlying to withdraw.
     * @param receiver The address to receive `assets`.
     * @param owner The address whose shares are burnt.
     * @return shares The actual amount of shares burnt.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256 shares) {
        // Check for rounding error.
        require((shares = previewWithdraw(assets)) != 0, "ZERO_SHARES");

        _withdraw(receiver, owner, assets, shares);
    }

    /**
     * @notice Redeems exactly `shares` from `owner` and
     * sends `assets` of underlying tokens to `receiver`.
     * @param shares The amount of shares burnt.
     * @param receiver The address to receive `assets`.
     * @param owner The address whose shares are burnt.
     * @return assets The actual amount of underlying withdrawn.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256 assets) {
        // Check for rounding error.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        _withdraw(receiver, owner, assets, shares);
    }

    /**
     * @notice The amount of shares that the strategy would
     *  exchange for the amount of assets provided, in an
     * ideal scenario where all the conditions are met.
     *
     * @param assets The amount of underlying.
     * @return . Expected shares that `assets` repersents.
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        // Saves an extra SLOAD if totalAssets() is non-zero.
        uint256 _totalAssets = totalAssets();
        uint256 _totalSupply = totalSupply();

        // If assets are 0 but supply is not PPS = 0.
        if (_totalAssets == 0) return _totalSupply == 0 ? assets : 0;

        return assets.mulDiv(_totalSupply, _totalAssets, Math.Rounding.Down);
    }

    /**
     * @notice The amount of assets that the strategy would
     * exchange for the amount of shares provided, in an
     * ideal scenario where all the conditions are met.
     *
     * @param shares The amount of the strategies shares.
     * @return . Expected amount of `asset` the shares repersent.
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        // Saves an extra SLOAD if totalSupply() is non-zero.
        uint256 supply = totalSupply();

        return
            supply == 0
                ? shares
                : shares.mulDiv(totalAssets(), supply, Math.Rounding.Down);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their deposit at the current block, given
     * current on-chain conditions.
     * @dev This will round down.
     */
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their mint at the current block, given
     * current on-chain conditions.
     * @dev This is used instead of convertToAssets so that it can
     * round up for safer mints.
     */
    function previewMint(uint256 shares) public view returns (uint256) {
        // Saves an extra SLOAD if totalSupply() is non-zero.
        uint256 supply = totalSupply();

        return
            supply == 0
                ? shares
                : shares.mulDiv(totalAssets(), supply, Math.Rounding.Up);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     * @dev This is used instead of convertToShares so that it can
     * round up for safer withdraws.
     */
    function previewWithdraw(uint256 assets) public view returns (uint256) {
        // Saves an extra SLOAD if totalAssets() is non-zero.
        uint256 _totalAssets = totalAssets();
        uint256 _totalSupply = totalSupply();

        // If assets are 0 but supply is not, then PPS = 0.
        if (_totalAssets == 0) return _totalSupply == 0 ? assets : 0;

        return assets.mulDiv(_totalSupply, _totalAssets, Math.Rounding.Up);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their redeemption at the current block,
     * given current on-chain conditions.
     * @dev This will round down.
     */
    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }

    /**
     * @notice Total number of underlying assets that can
     * be deposited by `_owner` into the strategy, where `_owner`
     * corresponds to the msg.sender of a {deposit} call.
     */
    function maxDeposit(address _owner) public view returns (uint256) {
        if (_strategyStorage().shutdown) return 0;

        return
            IBaseTokenizedStrategy(address(this)).availableDepositLimit(_owner);
    }

    /**
     * @notice Total number of shares that can be minted by `_owner`
     * into the strategy, where `_owner` corresponds to the msg.sender
     * of a {mint} call.
     */
    function maxMint(address _owner) public view returns (uint256 _maxMint) {
        if (_strategyStorage().shutdown) return 0;

        _maxMint = IBaseTokenizedStrategy(address(this)).availableDepositLimit(
            _owner
        );
        if (_maxMint != type(uint256).max) {
            _maxMint = convertToShares(_maxMint);
        }
    }

    /**
     * @notice Total number of underlying assets that can be
     * withdrawn from the strategy by `owner`, where `owner`
     * corresponds to the msg.sender of a {redeem} call.
     */
    function maxWithdraw(
        address _owner
    ) public view returns (uint256 _maxWithdraw) {
        _maxWithdraw = IBaseTokenizedStrategy(address(this))
            .availableWithdrawLimit(_owner);
        if (_maxWithdraw == type(uint256).max) {
            // Saves a min check if there is no withdrawal limit.
            _maxWithdraw = convertToAssets(balanceOf(_owner));
        } else {
            _maxWithdraw = Math.min(
                convertToAssets(balanceOf(_owner)),
                _maxWithdraw
            );
        }
    }

    /**
     * @notice Total number of strategy shares that can be
     * redeemed from the strategy by `owner`, where `owner`
     * corresponds to the msg.sender of a {redeem} call.
     */
    function maxRedeem(
        address _owner
    ) public view returns (uint256 _maxRedeem) {
        _maxRedeem = IBaseTokenizedStrategy(address(this))
            .availableWithdrawLimit(_owner);
        // Conversion would overflow and saves a min check if there is no withdrawal limit.
        if (_maxRedeem == type(uint256).max) {
            _maxRedeem = balanceOf(_owner);
        } else {
            _maxRedeem = Math.min(
                // Use preview withdraw to round up
                previewWithdraw(_maxRedeem),
                balanceOf(_owner)
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view returns (uint256) {
        StrategyData storage S = _strategyStorage();
        unchecked {
            return S.totalIdle + S.totalDebt;
        }
    }

    function totalSupply() public view returns (uint256) {
        return _strategyStorage().totalSupply - _unlockedShares();
    }

    /**
     * @dev Function to be called during {deposit} and {mint}.
     *
     * This function handles all logic including transfers,
     * minting and accounting.
     *
     * We do all external calls before updating any internal
     * values to prevent view re-entrancy issues from the token
     * transfers or the _deployFunds() calls.
     */
    function _deposit(
        address receiver,
        uint256 assets,
        uint256 shares
    ) private {
        require(receiver != address(this), "ERC4626: mint to self");
        // Saves a redundant "shutdown" check to manually retreive deposit limit.
        require(
            assets <=
                IBaseTokenizedStrategy(address(this)).availableDepositLimit(
                    msg.sender
                ),
            "ERC4626: deposit more than max"
        );

        // Cache storage variables used more than once.
        StrategyData storage S = _strategyStorage();
        ERC20 _asset = S.asset;

        // Need to transfer before minting or ERC777s could reenter.
        _asset.safeTransferFrom(msg.sender, address(this), assets);

        // We will deposit up to current idle plus the new amount added
        uint256 toDeploy = S.totalIdle + assets;

        // Cache for post {deployFunds} checks.
        uint256 beforeBalance = _asset.balanceOf(address(this));

        // Deploy up to all loose funds.
        IBaseTokenizedStrategy(address(this)).deployFunds(toDeploy);

        // Always get the actual amount deployed. We double check the
        // diff agianst toDeploy for complete accuracy.
        uint256 deployed = Math.min(
            beforeBalance - _asset.balanceOf(address(this)),
            toDeploy
        );

        // Adjust total Assets.
        S.totalDebt += deployed;
        unchecked {
            // Cant't underflow due to previous min check.
            S.totalIdle = toDeploy - deployed;
        }

        // mint shares
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @dev To be called during {redeem} and {withdraw}.
     *
     * This will handle all logic, transfers and accounting
     * in order to service the withdraw request.
     *
     * If we are not able to withdraw the full amount needed, it will
     * be counted as a loss and passed on to the user.
     */
    function _withdraw(
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) private {
        require(shares <= maxRedeem(owner), "ERC4626: withdraw more than max");

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        StrategyData storage S = _strategyStorage();
        // Expected beharvior is to need to free funds so we cache `_asset`.
        ERC20 _asset = S.asset;

        uint256 idle = S.totalIdle;

        // Check if we need to withdraw funds.
        if (idle < assets) {
            // Cache before balance for diff checks.
            uint256 before = _asset.balanceOf(address(this));

            // Tell Strategy to free what we need.
            unchecked {
                IBaseTokenizedStrategy(address(this)).freeFunds(assets - idle);
            }

            // Return the actual amount withdrawn. Adjust for potential overwithdraws.
            uint256 withdrawn = Math.min(
                _asset.balanceOf(address(this)) - before,
                S.totalDebt
            );

            unchecked {
                idle += withdrawn;
            }

            uint256 loss;
            // If we didn't get enough out then we have a loss.
            if (idle < assets) {
                unchecked {
                    loss = assets - idle;
                }
                // Lower the amount to be withdrawn.
                assets = idle;
            }

            // Update debt storage.
            S.totalDebt -= (withdrawn + loss);
        }

        // Update idle based on how much we took.
        S.totalIdle = idle - assets;

        _burn(owner, shares);

        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                        PROFIT LOCKING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function for keepers to call to harvest and record all
     * profits accrued.
     *
     * @dev This should be called through protected relays if swaps
     * are likely occur.
     *
     * This will account for any gains/losses since the last report
     * and charge fees accordingly.
     *
     * Any profit over the fees charged will be immediatly locked
     * so there is no change in PricePerShare. Then slowly unlocked
     * over the `maxProfitUnlockTime` each second based on the
     * calculated `profitUnlockingRate`.
     *
     * Any 'loss' or fees greater than 'profit' will attempted to be
     * offset with any remaining locked shares from the last report
     * in order to reduce any negative impact to PPS.
     *
     * Will then recalculate the new time to unlock profits over and the
     * rate based on a weighted average of any remaining time from the
     * last report and the new amount of shares to be locked.
     *
     * @return profit The notional amount of gain if any since the last
     * report in terms of `asset`.
     * @return loss The notional amount of loss if any since the last
     * report in terms of `asset`.
     */
    function report()
        external
        nonReentrant
        onlyKeepers
        returns (uint256 profit, uint256 loss)
    {
        // Cache storage pointer since its used repeatedly.
        StrategyData storage S = _strategyStorage();

        uint256 oldTotalAssets;
        unchecked {
            // Manuaully calculate totalAssets to save a SLOAD.
            oldTotalAssets = S.totalIdle + S.totalDebt;
        }

        // Calculate protocol fees before we burn shares and
        // potentially update lastReport.
        (
            uint256 totalFees,
            address protocolFeesRecipient
        ) = _assessProtocolFees(oldTotalAssets);

        // Burn unlocked shares.
        _burnUnlockedShares();

        // Tell the strategy to report the real total assets it has.
        // It should do all reward selling and redepositing now and
        // account for deployed and loose `asset` so we can accuratly
        // account for all funds including those potentially airdropped
        // by a trade factory. It is safe here to use asset.balanceOf()
        // instead of totalIdle because any profits are immediatly locked.
        uint256 newTotalAssets = IBaseTokenizedStrategy(address(this))
            .harvestAndReport();

        uint256 performanceFees;
        unchecked {
            // Calculate profit/loss.
            if (newTotalAssets > oldTotalAssets) {
                // We have a profit
                profit = newTotalAssets - oldTotalAssets;

                // Asses performance fees.
                performanceFees = (profit * S.performanceFee) / MAX_BPS;
                totalFees += performanceFees;
            } else {
                // We have a loss.
                loss = oldTotalAssets - newTotalAssets;
            }
        }

        // We need to get the shares to issue for the fees at
        // current PPS before any minting or burning.
        uint256 performanceFeeShares = convertToShares(performanceFees);
        uint256 protocolFeeShares;
        unchecked {
            protocolFeeShares = convertToShares(totalFees - performanceFees);
        }
        uint256 sharesToLock;
        if (loss + totalFees >= profit) {
            // We have a net loss.
            // Will try and unlock the difference between between the gain and the loss
            // to prevent any PPS decline post report.
            uint256 sharesToBurn = Math.min(
                convertToShares((loss + totalFees) - profit),
                S.balances[address(this)]
            );

            if (sharesToBurn > 0) {
                _burn(address(this), sharesToBurn);
            }
        } else {
            // we have a net profit
            // lock (profit - fees)
            unchecked {
                sharesToLock = convertToShares(profit - totalFees);
            }
            _mint(address(this), sharesToLock);
        }

        // Mint fees shares.
        if (performanceFeeShares > 0) {
            _mint(S.performanceFeeRecipient, performanceFeeShares);
        }

        if (protocolFeeShares > 0) {
            _mint(protocolFeesRecipient, protocolFeeShares);
        }

        // Update unlocking rate and time to fully unlocked
        {
            // Scoped to avoid stack to deep errors
            uint256 totalLockedShares = S.balances[address(this)];
            if (totalLockedShares > 0) {
                uint32 _profitMaxUnlockTime = S.profitMaxUnlockTime;
                uint256 remainingTime;
                uint128 _fullProfitUnlockDate = S.fullProfitUnlockDate;
                if (_fullProfitUnlockDate > block.timestamp) {
                    unchecked {
                        remainingTime = _fullProfitUnlockDate - block.timestamp;
                    }
                }

                uint256 previouslyLockedShares = totalLockedShares -
                    sharesToLock;

                // new_profit_locking_period is a weighted average between the remaining
                // time of the previously locked shares and the PROFIT_MAX_UNLOCK_TIME
                uint256 newProfitLockingPeriod = (previouslyLockedShares *
                    remainingTime +
                    sharesToLock *
                    _profitMaxUnlockTime) / totalLockedShares;

                S.profitUnlockingRate =
                    (totalLockedShares * MAX_BPS_EXTENDED) /
                    newProfitLockingPeriod;

                S.fullProfitUnlockDate = uint128(
                    block.timestamp + newProfitLockingPeriod
                );
            } else {
                // Only setting this to 0 will turn in the desired effect,
                // no need to update fullProfitUnlockDate
                S.profitUnlockingRate = 0;
            }
        }

        // Update storage we use the actual loose here since it should have
        // been accounted for in `harvestAndReport` and any airdropped amounts
        // would have been locked to prevent PPS manipulation.
        uint256 newIdle = S.asset.balanceOf(address(this));
        S.totalIdle = newIdle;
        S.totalDebt = newTotalAssets - newIdle;

        S.lastReport = uint128(block.timestamp);

        // If we had an overall loss we need to adjust the actual fees issued
        // based on new PPS post all minting and locking.
        if (loss + totalFees >= profit) {
            totalFees = convertToAssets(
                performanceFeeShares + protocolFeeShares
            );
            performanceFees = convertToAssets(performanceFeeShares);
        }

        // Emit event with info
        emit Reported(
            profit,
            loss,
            totalFees - performanceFees, // Protocol fees
            performanceFees
        );
    }

    function _assessProtocolFees(
        uint256 _oldTotalAssets
    )
        private
        view
        returns (uint256 protocolFees, address protocolFeesRecipient)
    {
        (
            uint16 protocolFeeBps,
            uint32 protocolFeeLastChange,
            address _protocolFeesRecipient
        ) = IFactory(FACTORY).protocol_fee_config();

        if (protocolFeeBps > 0) {
            protocolFeesRecipient = _protocolFeesRecipient;
            // Charge fees since last report OR last fee change
            // (this will mean less fees are charged after a change
            // in protocol_fees, but fees should not change frequently).
            uint256 secondsSinceLastReport = Math.min(
                block.timestamp - _strategyStorage().lastReport,
                block.timestamp - uint256(protocolFeeLastChange)
            );

            protocolFees =
                (_oldTotalAssets *
                    uint256(protocolFeeBps) *
                    secondsSinceLastReport) /
                31_556_952 / // Seconds per year
                MAX_BPS;
        }
    }

    function _burnUnlockedShares() private {
        uint256 unlcokdedShares = _unlockedShares();
        if (unlcokdedShares == 0) {
            return;
        }

        // update variables (done here to keep _unlcokdedShares() as a view function)
        if (_strategyStorage().fullProfitUnlockDate > block.timestamp) {
            _strategyStorage().lastReport = uint128(block.timestamp);
        }

        _burn(address(this), unlcokdedShares);
    }

    function _unlockedShares() private view returns (uint256 unlockedShares) {
        // should save 2 extra calls for most scenarios.
        StrategyData storage S = _strategyStorage();
        uint128 _fullProfitUnlockDate = S.fullProfitUnlockDate;
        if (_fullProfitUnlockDate > block.timestamp) {
            unchecked {
                unlockedShares =
                    (S.profitUnlockingRate * (block.timestamp - S.lastReport)) /
                    MAX_BPS_EXTENDED;
            }
        } else if (_fullProfitUnlockDate != 0) {
            // All shares have been unlocked.
            unlockedShares = S.balances[address(this)];
        }
    }

    /*//////////////////////////////////////////////////////////////
                        TENDING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice For a 'keeper' to 'tend' the strategy if a custom
     * tendTrigger() is implemented.
     *
     * @dev Both 'tendTrigger' and '_tend' will need to be overridden
     * for this to be used.
     *
     * This will callback the internal '_tend' call in the BaseTokenizedStrategy
     * with the total current amount available to the strategy to deploy.
     *
     * Keepers are expected to use protected relays in tend calls so this
     * can be used for illiquid or manipulatable strategies to compound
     * rewards, perform maintence or deposit/withdraw funds.
     *
     * All accounting for totalDebt and totalIdle updates will be done
     * here post '_tend'.
     *
     * This should never cause an increase in PPS. Total assets should
     * be the same before and after
     *
     * A report() call will be needed to record the profit.
     */
    function tend() external nonReentrant onlyKeepers {
        StrategyData storage S = _strategyStorage();
        // Expected Behavior is this will get used twice so we cache it
        uint256 _totalIdle = S.totalIdle;
        ERC20 _asset = S.asset;

        uint256 beforeBalance = _asset.balanceOf(address(this));
        IBaseTokenizedStrategy(address(this)).tendThis(_totalIdle);
        uint256 afterBalance = _asset.balanceOf(address(this));

        // Adjust storage according to the changes without adjusting totalAssets().
        if (beforeBalance > afterBalance) {
            // Idle funds were deposited.
            uint256 deposited = Math.min(
                beforeBalance - afterBalance,
                _totalIdle
            );

            unchecked {
                S.totalIdle -= deposited;
                S.totalDebt += deposited;
            }
        } else if (afterBalance > beforeBalance) {
            // We default to use any funds freed as idle for cheaper withdraw/redeems.
            uint256 harvested = Math.min(
                afterBalance - beforeBalance,
                S.totalDebt
            );

            unchecked {
                S.totalIdle += harvested;
                S.totalDebt -= harvested;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        Getter FUNCIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the api version for this TokenizedStrategy.
     * @return . The api version for this TokenizedStrategy
     */
    function apiVersion() external pure returns (string memory) {
        return API_VERSION;
    }

    /**
     * @notice Get the current total idle for a strategy.
     * @return . The current amount of idle funds.
     */
    function totalIdle() external view returns (uint256) {
        return _strategyStorage().totalIdle;
    }

    /**
     * @notice Get the current total debt for a strategy.
     * @return . The current amount of debt.
     */
    function totalDebt() external view returns (uint256) {
        return _strategyStorage().totalDebt;
    }

    /**
     * @notice Get the current address that controls the strategy.
     * @return . Address of management
     */
    function management() external view returns (address) {
        return _strategyStorage().management;
    }

    /**
     * @notice Get the current address that can call tend and report.
     * @return . Address of the keeper
     */
    function keeper() external view returns (address) {
        return _strategyStorage().keeper;
    }

    /**
     * @notice Get the current performance fee charged on profits.
     * denominated in Basis Points wehere 10_000 == 100%
     * @return . Current performance fee.
     */
    function performanceFee() external view returns (uint16) {
        return _strategyStorage().performanceFee;
    }

    /**
     * @notice Get the current address that receives the performance fees.
     * @return . Address of performanceFeeRecipient
     */
    function performanceFeeRecipient() external view returns (address) {
        return _strategyStorage().performanceFeeRecipient;
    }

    /**
     * @notice Gets the timestamp at which all profits will be unlocked.
     * @return . The full profit unlocking timestamp
     */
    function fullProfitUnlockDate() external view returns (uint256) {
        return uint256(_strategyStorage().fullProfitUnlockDate);
    }

    /**
     * @notice The per second rate at which profits are unlocking.
     * @dev This is denominated in EXTENDED_BPS decimals.
     * @return . The current profit unlocking rate.
     */
    function profitUnlockingRate() external view returns (uint256) {
        return _strategyStorage().profitUnlockingRate;
    }

    /**
     * @notice Gets the current time profits are set to unlock over.
     * @return . The current profit max unlock time.
     */
    function profitMaxUnlockTime() external view returns (uint256) {
        return _strategyStorage().profitMaxUnlockTime;
    }

    /**
     * @notice The timestamp of the last time protocol fees were charged.
     * @return . The last report.
     */
    function lastReport() external view returns (uint256) {
        return uint256(_strategyStorage().lastReport);
    }

    /**
     * @notice Get the price per share.
     * @dev This value offers limited precision. Integrations that require
     * exact precision should use convertToAssets or convertToShares instead.
     *
     * @return . The price per share.
     */
    function pricePerShare() external view returns (uint256) {
        return convertToAssets(10 ** _strategyStorage().decimals);
    }

    /*//////////////////////////////////////////////////////////////
                        SETTER FUNCIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets a new address to be in charge of the stategy.
     * @dev Can only be called by the current `management`.
     *
     * Cannot set `management` to address(0).
     *
     * @param _management New address to set `management` to.
     */
    function setManagement(address _management) external onlyManagement {
        require(_management != address(0), "ZERO ADDRESS");
        _strategyStorage().management = _management;

        emit UpdateManagement(_management);
    }

    /**
     * @notice Sets a new address to be in charge of tend and reports.
     * @dev Can only be called by the current `management`.
     *
     * @param _keeper New address to set `keeper` to.
     */
    function setKeeper(address _keeper) external onlyManagement {
        _strategyStorage().keeper = _keeper;

        emit UpdateKeeper(_keeper);
    }

    /**
     * @notice Sets the performance fee to be charged on a reported gains.
     * @dev Can only be called by the current `management`.
     *
     * Denominated in Baseis Points. So 100% == 10_000.
     * Cannot set greateer or equal to 10_000.
     *
     * @param _performanceFee New performance fee.
     */
    function setPerformanceFee(uint16 _performanceFee) external onlyManagement {
        require(_performanceFee < MAX_BPS, "MAX BPS");
        _strategyStorage().performanceFee = _performanceFee;

        emit UpdatePerformanceFee(_performanceFee);
    }

    /**
     * @notice Sets a new address to recieve performance fees.
     * @dev Can only be called by the current `management`.
     *
     * Cannot set to address(0).
     *
     * @param _performanceFeeRecipient New address to set `management` to.
     */
    function setPerformanceFeeRecipient(
        address _performanceFeeRecipient
    ) external onlyManagement {
        require(_performanceFeeRecipient != address(0), "ZERO ADDRESS");
        require(_performanceFeeRecipient != address(this), "Can't be self");
        _strategyStorage().performanceFeeRecipient = _performanceFeeRecipient;

        emit UpdatePerformanceFeeRecipient(_performanceFeeRecipient);
    }

    /**
     * @notice Sets the time for profits to be unlocked over.
     * @dev Can only be called by the current `management`.
     *
     * Denominated in seconds and cannot be greater than 1 year.
     *
     * `profitMaxUnlockTime` is stored as a uint32 for packing but can
     * be passed in as uint256 for simplicity.
     *
     * @param _profitMaxUnlockTime New `profitMaxUnlockTime`.
     */
    function setProfitMaxUnlockTime(
        uint256 _profitMaxUnlockTime
    ) external onlyManagement {
        require(_profitMaxUnlockTime > 0, "to short");
        require(_profitMaxUnlockTime <= 31_556_952, "to long");
        _strategyStorage().profitMaxUnlockTime = uint32(_profitMaxUnlockTime);

        emit UpdateProfitMaxUnlockTime(_profitMaxUnlockTime);
    }

    /**
     * @notice Used to shutdown the strategy preventing any further deposits.
     * @dev Can only be called by the current `management`.
     *
     * This will stop any new {deposit} or {mint} calls but will
     * not prevent {withdraw} or {redeem}. It will also still allow for
     * {tend} and {report} so that management can report any last losses
     * in an emergency as well as provide any maintence to allow for full
     * withdraw.
     *
     * This is a one way switch and can never be set back once shutdown.
     */
    function shutdownStrategy() external onlyManagement {
        _strategyStorage().shutdown = true;

        emit StrategyShutdown();
    }

    /*//////////////////////////////////////////////////////////////
                        ERC20 FUNCIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the name of the token.
     * @return . The name the strategy is using for its token.
     */
    function name() public view returns (string memory) {
        return _strategyStorage().name;
    }

    /**
     * @notice Returns the symbol of the token.
     * @dev Should be some iteration of 'ys + asset symbol'
     * @return . The symbol the strategy is using for its tokens.
     */
    function symbol() public view returns (string memory) {
        return string(abi.encodePacked((_strategyStorage().symbol)));
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * @return . The decimals used for the strategy and `asset`.
     */
    function decimals() public view returns (uint8) {
        return _strategyStorage().decimals;
    }

    /**
     * @notice Returns the current balance for a given '_account'.
     * @dev If the '_account` is the strategy then this will subtract
     * the amount of shares that have been unlocked since the last profit first.
     * @param account the address to return the balance for.
     * @return . The current balance in y shares of the '_account'.
     */
    function balanceOf(address account) public view returns (uint256) {
        if (account == address(this)) {
            return _strategyStorage().balances[account] - _unlockedShares();
        }
        return _strategyStorage().balances[account];
    }

    /**
     * @notice Transfer '_amount` of shares from `msg.sender` to `to`.
     * @dev
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` cannot be the address of the strategy.
     * - the caller must have a balance of at least `_amount`.
     *
     * @param to The address shares will be transferred to.
     * @param amount The amount of shares to be transferred from sender.
     * @return . a boolean value indicating whether the operation succeeded.
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     * @param owner The address who owns the shares.
     * @param spender The address who would be moving the owners shares.
     * @return . The remaining amount of shares of `owner` that could be moved by `spender`.
     */
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _strategyStorage().allowances[owner][spender];
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @dev
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     *
     * @param spender the address to allow the shares to be moved by.
     * @param amount the amount of shares to allow `spender` to move.
     * @return . a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * @dev
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `to` cannot be the address of the strategy.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     *
     * Emits a {Transfer} event.
     *
     * @param from the address to be moving shares from.
     * @param to the address to be moving shares to.
     * @param amount the quantity of shares to move.
     * @return . a boolean value indicating whether the operation succeeded.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - cannot give spender over uint256.max allowance
     *
     * @param spender the account that will be able to move the senders shares.
     * @param addedValue the extra amount to add to the current allowance.
     * @return . a boolean value indicating whether the operation succeeded.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     *
     * @param spender the account that will be able to move less of the senders shares.
     * @param subtractedValue the amount to decrease the current allowance by.
     * @return . a boolean value indicating whether the operation succeeded.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) - subtractedValue);
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `to` cannot be the strategies address
     * - `from` must have a balance of at least `amount`.
     *
     */
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(to != address(this), "ERC20 transfer to strategy");
        StrategyData storage S = _strategyStorage();

        S.balances[from] -= amount;
        unchecked {
            S.balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     *
     */
    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");
        StrategyData storage S = _strategyStorage();

        S.totalSupply += amount;
        unchecked {
            S.balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");
        StrategyData storage S = _strategyStorage();

        S.balances[account] -= amount;
        unchecked {
            S.totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _strategyStorage().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * @dev Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * @param _owner the address of the account to return the nonce for.
     * @return . the current nonce for the account.
     */
    function nonces(address _owner) external view returns (uint256) {
        return _strategyStorage().nonces[_owner];
    }

    /**
     * @notice Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * @dev IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "ERC20: PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                _strategyStorage().nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "ERC20: INVALID_SIGNER"
            );

            _approve(recoveredAddress, spender, value);
        }
    }

    /**
     * @notice Returns the domain separator used in the encoding of the signature
     * for {permit}, as defined by {EIP712}.
     *
     * @dev This checks that the current chain id is the same as when the contract was deployed to
     * prevent replay attacks. If false it will calculate a new domain seperator based on the new chain id.
     *
     * @return . The domain seperator that will be used for any {permit} calls.
     */
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        StrategyData storage S = _strategyStorage();
        return
            block.chainid == S.INITIAL_CHAIN_ID
                ? S.INITIAL_DOMAIN_SEPARATOR
                : _computeDomainSeparator();
    }

    /**
     * @dev Calculates and returns the domain seperator to be used in any
     * permit functions for the strategies {permit} calls.
     *
     * This will be used at the initilization of each new strategies storage.
     * It would then be used in the future in the case of any forks in which
     * the current chain id is not the same as the origin al.
     *
     */
    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(_strategyStorage().name)),
                    keccak256(bytes(API_VERSION)),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                            CLONING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Used to create a new clone of the calling stategy.
     * @dev This can be called through a normal delegate call directly
     * to the TokenizedStrategy however that will leave all Strategy
     * sepcific setup uncompleted.
     *
     * The recommended use for strategies that wish to utilize cloning
     * is to declare a strategy specific {clone} that will then call
     * `TokenizedStrategy.clone(data)` so it can implement its own
     * initiliaztion.
     *
     * This can't be called through a strategy that is a clone. All
     * cloning must come through the original contract that can be
     * viewed by the `isOriginal` variable in all strategies.
     *
     * @param _asset Address of the underlying asset.
     * @param _name Name the strategy will use.
     * @param _management Address to set as the strategies `management`.
     * @param _performanceFeeRecipient Address to receive performance fees.
     * @param _keeper Address to set as strategies `keeper`.
     * @return newStrategy The address of the new clone.
     */
    function clone(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external returns (address newStrategy) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        //address _target = address(this);
        bytes memory code = address(this).code;

        assembly {
            // Memory location to store the bytecode
            //let code := mload(0x40)
            // new "memory end" including padding
            //mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            //mstore(code, size)
            // actually retrieve the code, this needs assembly
            //extcodecopy(_target, add(code, 0x20), 0, size)
            // Create the new instance
            newStrategy := create(0, add(code, 0x20), mload(code))
        }

        IBaseTokenizedStrategy(newStrategy).initialize(
            _asset,
            _name,
            _management,
            _performanceFeeRecipient,
            _keeper
        );

        emit Cloned(newStrategy, address(this));
    }

    /**
     * @notice Used to create a new clone of the calling stategy.
     * @dev This can be called through a normal delegate call directly
     * to the TokenizedStrategy however that will leave all Strategy
     * sepcific setup uncompleted.
     *
     * The recommended use for strategies that wish to utilize cloning
     * is to declare a strategy specific {clone} that will then call
     * `TokenizedStrategy.clone(data)` so it can implement its own
     * initiliaztion.
     *
     * This can't be called through a strategy that is a clone. All
     * cloning must come through the original contract that can be
     * viewed by the `isOriginal` variable in all strategies.
     *
     * @param _asset Address of the underlying asset.
     * @param _name Name the strategy will use.
     * @param _management Address to set as the strategies `management`.
     * @param _performanceFeeRecipient Address to receive performance fees.
     * @param _keeper Address to set as strategies `keeper`.
     * @return newStrategy The address of the new clone.
     */
    function clones(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external returns (address newStrategy) {
        require(IBaseTokenizedStrategy(address(this)).isOriginal(), "!clone");
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        IBaseTokenizedStrategy(newStrategy).initialize(
            _asset,
            _name,
            _management,
            _performanceFeeRecipient,
            _keeper
        );

        emit Cloned(newStrategy, address(this));
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev On contract creation we set `asset` for this contract to address(1).
     * This prevents it from ever being intialized in the future.
     */
    constructor() {
        _strategyStorage().asset = ERC20(address(1));
    }

    event Data(bytes4 sig, bytes data, uint256 value);

    fallback() external payable {
        console.log("Hit the fallback");
        uint256 value = msg.value;
        bytes4 selector = msg.sig;
        bytes memory data = msg.data;
        emit Data(selector, data, value);
    }
}
