# Yearn V3 Tokenized Strategy Specification

## Overview
The Yearn V3 "Tokenized Strategy" goal is to make it as easy as possible for any person or protocol to create and deploy their own ERC-4626 compliant single strategy vault. It uses an immutable proxy pattern to outsource all of the standardized 4626 and other vault logic to one implementation contract that all Strategies deployed on a specific chain use through delegatecall. 

This makes the strategy specific contract as simple and specific to that yield generating task as possible and allows for anyone to simply plug their version into a permissionless, secure and optimized 4626 compliant base that handles all risky and complicated code. 


### Definitions
- Asset: Any ERC20-compliant token
- Shares: ERC20-compliant token that tracks Asset balance in the strategy for every distributor.
- Strategy: ERC4626 compliant smart contract that receives Assets from Depositors (vault or otherwise) to deposit in any external protocol to generate yield.
- Tokenized Strategy: The implementation contract that all strategies delegateCall to for the standard ERC4626 and profit locking functions.
- BaseTokenizedStrategy: The abstract contract that a strategy should inherit from that handles all communication with the Tokenized Strategy contract.
- Strategist: The developer of a specific strategy.
- Depositor: Account that holds Shares
- Vault: Or "Meta Vault" is an ERC4626 compliant Smart contract that receives Assets from Depositors to then distribute them among the different Strategies added to the vault, managing accounting and Assets distribution. 
- Management: The owner of the specific strategy that can set fees, profit unlocking time etc.
- Keeper: the address of a contract allowed to call report() and tend() on a strategy.
- Factory: The factory that all meta vaults of a specific API version are cloned from that also controls the protocol fee amount and recipient.

## Storage
In order to standardize all high risk and complex logic associated with ERC4626, ERC20 and profit locking, all core logic has been moved to the 'TokenizedStrategy.sol' and is used by each strategy through a fallback function that delegatecall's this contract to do all necessary checks, logic and storage updates for the strategy.

The TokenizedStrategy will only need to be deployed once on each chain and can then be used by an unlimited number of strategies. Allowing the BaseTokenizedStrategy.sol to be much smaller, simpler and cheaper to deploy.

Using delegate call the external TokenizedStrategyy will be able read and write to any and all of the strategies specific storage variables during all calls. This does open the strategy up to the possibility of storage collisions due to non-standardized storage calls and means extra precautions need to be taken when reading and writing to storage.

In order to limit the strategists need to think about their storage variables all TokenizedStrategy specific variables are held within and controlled by the TokenizedStrategy. A `StrategyData` struct is held at a custom storage location that is high enough that no normal implementation should be worried about hitting.

This means all high risk storage updates will always be handled by the TokenizedStrategy, should not be able to be overridden by a reckless strategist and will be entirely standardized across every strategy deployed, no matter the chain or specific implementation.

## BaseTokenizedStrategy

The base tokenized strategy is a simple abstract contract to be inherited by the strategist that handles all communication with the TokenizedStrategy.

### Modifiers
`onlySelf`: This modifier is placed on any callback functions for the TokenizedStrategy to call during deposits, withdraws, reports and tends. The modifier should revert if msg.sender is not equal to itself. In order for a call to be forwarded to the TokenizedStrategy it must not be defined in the Strategy and hit the fallback function which will delegatecall the TokenizedStrategy. If within that call, the TokenizedStrategy makes an external static call back to the BaseTokenizedStrategy the msg.sender of that call will be the original caller, which should be the Strategy itself.

`OnlyManagement`: Should be placed on function that only the Strategies specific management address can call. This uses the isManagement(address) function defined in TokenizedStrategy by sending the original msg.sender address.

`onlyKeepers`: Should be placed on functions that only the Strategies specific management or keeper can call. This uses the isManagementOrKeeper(address) defined in TokenizedStrategy sending the original msg.sender address.

### Variables

`tokenizedStrategyAddress`: This is the address the fallback function will use to delegatecall to and is set before deployment to a constant so it can never be changed.

`TokenizedStrategy`: This is an immutable set on deployment setting an ITokenizedStrategy interface to address(this). The variable should be used in a similar manner as a linked library would be to have a simple method to read from the Strategies storage internally. Setting it to address(this) means anything using this variable will static call itself which should hit the fallback and then delegatecall the TokenizedStrategy retrieving the correct variables.

`asset`: The immutable address of the underlying asset being used.

### Functions 

The majority of function in the BaseTokenizedStrategy are either external functions with onlySelf modifiers used for the TokenizedStrategy to call. Or the internal functions that correspond to those external functions that should or can be overridden by a strategist with the strategy specific logic.

`deployFunds(uint256)/_DeployFunds(uint256)`: Called by the TokenizedStrategy during deposits into the strategy to tell the strategy it can deposit up to the amount passed in as a parameter if desired.

`freeFunds(uint256)/_freeFunds(uint256)`: Called by the TokenizedStrategy during withdraws to get the amount of the uint256 parameter freed up in order to process the withdraw.

`harvestAndReport()/_harvestAndReport()`: Called during reports to tell the strategy a trusted address has called it and to harvest any rewards re-deploy any loose funds and return the actual amount of funds the strategy holds.

`tendThis(uint256)/_tend(uint256)`: Called by the TokenizedStrategy during tend calls to tell the strategy a trusted address has called tend and it has the uint256 parameter of loose asset available to deposit. NOTE: we use `tendThis` to avoid function signature collisions so that `tend` will be forwarded to the TokenizedStrategy.

`tendTrigger()`: View function to return if a tend call is needed.

`availableDepositLimt(address)/availableWithdrawLimit(address)`: Optional functions a strategist can override that default to uint256 max to implement any deposit or withdraw limits.

`shutdownWithdraw(uint256)/_emergencyWithdraw(uint256)`: Optional function for a strategist to implement that will allow management to manually withdraw a specified amount from the yield source if a strategy is shutdown in the case of emergencies.

`_init(...)`: Used only once during initialization to manually delegatecall the TokenizedStrategy to tell it to set up the storage for a new strategy.

## TokenizedStrategy

The tokenized strategy contract should implement all ERC-4626, ERC-20, ERC-2612 and custom TokenizedStrategy specific report and tending logic within it.

For deposits, withdraws, report, tend and emergency withdraw calls it casts address(this) into a custom IBaseTokenizedStrategy() interface to static call back the initial calling contract when it needs to interact with the Strategy.

### Normal Operation
 The TokenizedStrategy is responsible for handling the logic associated with all the following functionality.
 
#### Deposits / Mints
Users can deposit ASSET tokens to receive shares.

Deposits are limited by the maxAvailableDeposit function that can be changed by the strategist if non uint256.max values are desired.

#### Withdrawals / Redeems
Users can redeem their shares at any point in time if there is liquidity available. 

The amount of a withdraw or redeem can be limited by the strategist by overriding the maxAvailableWithdraw function.

In order to properly comply with the ERC-4626 standard and still allow losses, both withdraw and redeem have an additional optional parameter of 'maxLoss' that can be used. The default for 'maxLoss' is 0 (i.e. revert if any loss) for withdraws, and 10_000 (100%) for redeems.

#### Strategy Shares
The strategy issues shares to each depositor to track their relative share of assets. Shares are ERC20 transferable yield-bearing tokens.

They are ERC4626 compliant. Please read [ERC4626 compliance](https://hackmd.io/cOFvpyR-SxWArfthhLJb5g#ERC4626-compliance) to understand the implications. 

#### Accounting
The strategy will evaluate profit and losses from the yield generating activities. 

This is done comparing the current totalAssets of the strategy with the amount returned from _harvestAndReport()

If totalAssets < newTotalAssets: the vault will record a profit
If totalAssets > newTotalAssets: the vault will record a loss

Both loss and profit will impact strategy's totalAssets, increasing if there are profits, decreasing  if there are losses.

#### Fees
Fee assessment and distribution is handled during each `report` call after profits or losses are recorded. 

It will report the amount of fees that need to be charged and the strategy will issue shares for that amount of fees.

There are two potential fees. Performance fees and protocol fees. Performance fees are configurable by management of the strategy and payed based on the reported profit during each report with a min of 5% and a max of 50%. 

Protocol fees are configured by Yearn governance through the Factory and are taken as a percent of the performanceFees charged. I.E. profit = 100, performance fees = 20% protocol fees = 10%. Then total fees charged = 100 * .2 = 20 of which 10% is sent to the protocol fee recipient (2) and 90% (18) is sent the strategy specific `performanceFeeRecipient`.

### Profit distribution 
Profit from report calls will accumulate in a buffer. This buffer will be linearly unlocked over the locking period seconds at profitUnlockingRate. 

Profits will be locked for a max period of time of profitMaxUnlockTime seconds and will be gradually distributed. To avoid spending too much gas for profit unlock, the amount of time a profit will be locked is a weighted average between the new profit and the previous profit. 

new_locking_period = current_locked_profit * pending_time_to_unlock + new_profit * PROFIT_MAX_UNLOCK_TIME / (current_locked_profit + new_profit)
new_profit_unlocking_rate = (locked_profit + new_profit) / new_locking_period

Losses will be offset by locked profit, if possible.

Issue of new shares due to fees will also unlock profit so that PPS does not go down. 

Both of this offsets will prevent front running (as the profit was already earned and was not distributed yet)

### Strategy Management
Strategy management is held by the 'management' address that can be updated by the current 'managment'. Changing 'management' is a two step process, so first the current management will have to set 'pendingManagement' then that pending management will need to accept the role.

Management has the ability to set all the configurable variables for their specific Strategy.

The base strategy has purposely been written to limit the actual control management has over any important functionality. Meaning they are not capable of stealing any funds from the strategy or otherwise tampering with deposited funds, unless purposefully written in within their specific Strategy.

The configurable variables within managements control are: 

#### Setting Pending Management
This allows the current management to set a new non-zero address to take over as the management of the strategy.

#### Accepting Management
This allows the current 'pendingManagement' to accept the ownership of the contract.

#### Setting the keeper
Setting the address that is also allowed to call report and tend functions.

#### Setting Performance Fee
Setting the percent in terms of basis points for the amount of profit to be charged as a fee.

This has a minimum of 5% and a maximum of 50%.

#### Setting performance fee recipient
Setting the non-zero address that will receive any shares issued as a result of the performance fee.

#### Setting the profit unlock period
Sets the time in seconds that controls how fast profits will unlock.

This can be customized based on the strategy. Based on aspects such as TVL, expected returns etc.

## ERC4626 compliance
Strategy Shares are ERC4626 compliant. 

## Emergency Operation
There is default emergency functions built in. First of which is `shutdownStrategy`. This can only ever be called by the management address and is non-reversible.

Once this is called it will stop any further deposit or mints but will have no effect on any other functionality including withdraw, redeem, report and tend. This is to allow management to continue potentially recording profits or losses and users to withdraw even post shutdown.

This can be used in an emergency or simply to retire a vault.

Once a strategy is shutdown management can also call `emergencyWithdraw(amount)`. Which will tell the strategy to withdraw a specified `amount` from the yield source and keep it as idle in the vault. This function will also do any needed updates to totalDebt and totalIdle, based on amounts withdrawn to assure withdraws continue to function properly.

All other emergency functionality is left up to the individual strategist.

### Withdrawals
Withdrawals can't be paused under any circumstance unless built in a specific implementation.


## Use
A strategist can simply inherit the BaseTokenizedStrategy.sol contract and override 3 simple functions with their specific needs. 

The strategies code has been designed as a non-opinionated system to distribute funds of depositors to a single yield generating opportunity while managing accounting in a robust way.

The depositors receive shares of the strategy representing their relative share that can then be redeemed or used as yield-bearing tokens.

The Strategy does not have a preference on any of the dimensions that should be considered when operating a strategy:
- *Decentralization*: management and keeper roles can be handled by EOA's, multi-sigs or any other form of governance.
- *Permissionlessness*: The strategies default to be fully permissioned. However, any strategist can easily implement white lists or any other method they desire.
- *Liquidity*: The strategy can be fully liquid at any time or only allow withdraws of idle funds, depending on the strategy implementation.
- *Risk*: Strategy developers can deploy funds into any opportunity they desire no matter the expected risks or returns.
- *Automation*: all the required actions to maintain the vault can be called by bots or manually, depending on periphery implementation

The compromises will come with the specific yield generating opportunity and parameters used by the strategies management.

This allows different players to deploy their own version and implement their own constraints (or not use any at all)


Example constraints: 
- Illiquid Strategy: A strategy must join AMM pools, which can be sandwiched by permissionless deposits/withdraws. So it only deposits during reports or tend calls from a trusted relay and limits withdraws to the amount of asset currently loose within the contract.
- Permissioned Version: A strategy decides to only allow a certain address deposit into the vault by overriding maxAvailableDeposit.
- Risk: A strategist implements an options strategy that can create large positive gains or potentially loose all deposited funds.
- ...

## Development
Strategists should be able to use a pre-built "Strategy Mix" that will contain the imported BaseTokenizedStrategy.sol as well as standardized tests for any 4626 vault. Developing a strategy can be as simple as overriding three functions, with the potential for any number of other constraints or actions to be built on top of it. The Base implementation is only ~2KB, meaning there is plenty of room for strategists to build complex implementations while not having to be concerned with the generic functionality.


### Needed to Override

*_deployFunds(uint256 _amount)*: This function is called after every deposit or mint. Its only job is to deposit up to the '_amount' of 'asset'.

*_freeFunds(uint256 _amount)*: This function is called during every withdraw or redeem and should attempt to simply withdraw the '_amount' of 'asset'. Any difference between _amount and whats actually withdrawn will be counted as a loss

*_harvestandReport()*: This function is used during a report and should accrue all rewards and return the total amount of 'asset' the strategy currently has in its control.

### Optional to Override

While it can be possible to deploy a completely ERC-4626 compliant vault with just those three functions it does allow for further customization if the strategist desires.

*_tend* and *tendTrigger* can be overridden to signal to keepers the need for any sort of maintenance or reward selling between reports.

*maxAvailableDeposit(address _owner)* can be overridden to implement any type of deposit limit.

*maxAvailableWithdraw(address _owner)* can be used to limit the amount that a user can withdraw at any given moment.

*_emergencyWithdraw(uint256 _amount)* can be overridden to provide a manual method for management to pull funds from a yield source in an emergency when the vault is shutdown.

## Deployment
All strategies deployed will have the address of the deployed 'TokenizedStrategy' set as a constant to be used as the address to forward all external calls to that are not defined in the Strategy.

When deploying a new Strategy, it requires the following parameters:
- asset: address of the ERC20 token that can be deposited in the strategy
- name: name of Shares as described in ERC20

All other parameters will default to generic values and can be adjusted post deployment by the deployer if desired.