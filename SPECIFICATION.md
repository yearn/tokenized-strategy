# Yearn V3 Strategy Specification

### Definitions
- Asset: Any ERC20-compliant token
- Shares: ERC20-compliant token that tracks Asset balance in the vault for every distributor.
- Depositor: Account that holds Shares
- Strategy: ERC4626 compliant smart contract that recieves Assets from Depositers (vault or otherwise) to deposit in any external protocol to generate yield.
- Vault: ERC4626 compliant Smart contract that receives Assets from Depositors to then distribute them among the different Strategies added to the vault, managing accounting and Assets distribution. 
- Management: The owner of the specific strategy that can set fees, profit unlcoking time etc.
- Keeper: the address of a contract allowed to call report() and tend() on a strategy.
- Factory: The factory that all vaults of a specifi API version are cloned from that also controls the protocol fee amount and recipient.


## Overview
Any person wanting to create and deploy any yield generating strategy can simply inherit the BaseStrategy.sol contract and override 3 simple functions with their specific needs. The base strategy code has been created to make developing and deploying unique yield generating contracts as easy and as cheap as possible. All standard and repeatable code has been completely abstracted out of the BaseStrategy into a external linked library. This 'BaseLibrary' allows for anyone to simply plug their version into a permsionless, secure and optimized 4626 compliant base that handles all risky and complicated code. 

The strategies code has been designed as an unopinionated system to distribute funds of depositors to a single yield generating oppurtunity while managing accounting in a robust way.

The depositors receive shares of the strategy repersenting their relative share that can then be redeemed or used as yield-bearing tokens.

The Strategy does not have a preference on any of the dimensions that should be considered when operating a strategy:
- *Decentralization*: managment and keeper roles can be handled by EOA's, multisigs or any other form of governance.
- *Permisionlessness*: The strategies defualt to be fully permsiossioned. However, any strategist can easily implement whitelists or any other method they desire.
- *Liquidity*: The strategy can be fully liquid at any time or only allow withdraws of idle funds, depending on the strategy implementation.
- *Risk*: Strategy developers can deploy funds into any oppurtunity they desire no matter the expected risks or returns.
- *Automation*: all the required actions to maintain the vault can be called by bots or manually, depending on periphery implementation

The compromises will come with the specific yield generating opportunity and parameters used by the strategies management.

This allows different players to deploy their own version and implement their own constraints (or not use any at all)


Example constraints: 
- Illiquid Strategy: A strategy must join AMM pools, which can be sandwhiched by permisionless deposits/withdraws. So it only deposits during reports or tend calls from a trusted relay and limits withdraws to the amount of asset currently loose within the contract.
- Permissioned Version: A strategy decides to only allow a certain address deposit into the vault by overridding maxDeposit and maxMint.
- Risk: A strategist implements an options strategy that can create large positive gains or potentially loose all deposited funds.
- ...

## Storage
In order to standardize all high risk and complex logic associated with ERC4626, ERC20 and profit locking all core logic has been moved to a 'BaseLibrary.sol' and is used by each strategy through the ERC2535 "Diamond" pattern to do all neccesary checks, logic and storage updates for the strategy.

The BaseLibrary will only need to be deployed once on each chain and can then be used by an unlimited number of strategies. Allowing the BaseStrategy.sol to be much smaller, simpiler and cheaper to deploy.

Using delegate call the external linked library will be able read and write to any and all of the strategies specific storage variables during all calls. This does open the strategy up to the possibility of storage collisions due to non-standardized storage calls and means extra precautions need to be taken when reading and writing to storage.

In order to limit the strategists need to think about their storage variables all extra logic is held within and controlled by the BaseLibrary. Four different structs are defined to hold related variables and each is given a custom storage location that is high enough that no normal implementation should be worried about hitting.

This means all high risk storage updates will always be handled by the library, can not be overriden by a rogue or reckless strategist and will be entirely standardized across every strategy deployed, no matter the chain or specific implementation.

## Development
Strategists should be able to use a pre-built "Strategy Mix" that will contain the imported BaseStrategy.sol as well as standardized tests for any 4626 vault. Developing a strategy can be as simple as overriding three functions, with the potential for any number of other contraints or actions to be built on top of it. The Base implementation will only be 3KB, meaning there is plenty of room for strategists to build complex implementations while not having to be concerned with the generic functionality.

### Needed to Override

*_invest(uint256 _amount, bool _reported)*: This function is called after every deposit or mint as well as every report. Its only job is to deposit up to the '_amount' of 'asset'. The '_reported' bool will always be true when called at the end of a report and false when during a deposit or mint call to signal to the strategist if the call is during a protected function.

*_freeFunds(uint256 _amount)*: This function is called during every withdraw or redeem and shoud attempt to simply withdraw the '_amount' of 'asset'.

*_totalInvested()*: This function is used during a report and should accrue all rewards and return the total amount of 'asset' the strategy currently has in its control.

### Optional to Override

While it can be possible to deploy a completely ERC-4626 compliant vault with just those three functions it does allow for further customizations if the strategist desires.

*_tend* and *tendTrigger* can be overriden to signal to keepers the need for any sort of maintence or reward selling inbetwween reports.

*maxDeposit(address _owner)* and *maxMint(address _owner)* can be overridden to implement permissioned strategies.

*maxWithdraw(address _owner)* and *maxRedeem(address _owner)* can be used for illiquid strategies.

## Deployment
All strategies deployed will have the address of the deployed 'BaseLibrary' library set as a constant to be used as the address to forward all external calls to that are not defined in the implementation.

When deploying a new Strategy, it requires the following parameters:
- asset: address of the ERC20 token that can be deposited in the strategy
- name: name of Shares as described in ERC20

All other parameters will default to generic values and can be adjusted post deployment by the deployer if desired.

## Normal Operation

### Deposits / Mints
Users can deposit ASSET tokens to receive shares.

Deposits are limited by maxDeposit and maxMint functions that can be changed by the strategist if non uint256.max values are not desired.

### Withdrawals / Redeems
Users can redeem their shares at any point in time if there is liquidity available. 

The amount of a withdraw or redeem can be limited by the strategist by overridding the maxWithdraw and maxRedeem functions.

If not enough funds have been recovered to honor the full request, the transaction will revert.

### Strategy Shares
The strategy issues shares to each depositer to track their relative share of assets. Shares are ERC20 transferable yield-bearing tokens.

They are ERC4626 compliant. Please read [ERC4626 compliance](https://hackmd.io/cOFvpyR-SxWArfthhLJb5g#ERC4626-compliance) to understand the implications. 

### Accounting
The strategy will evaluate profit and losses from the yield generating activities. 

This is done comparing the current totalAssets of the strategy with the amount returned from _totalInvested()

If totalAssets < _invested: the vault will record a loss
If totalAssets > _invested: the vault will record a profit

Both loss and profit will impact strategy's totalAssets, increasing the if there are profits, decreasing  if there are losses.

#### Fees
Fee assessment and distribution is handled during each report call after profits or losses are recorded. 

It will report the amount of fees that need to be charged and the strategy will issue shares for that amount of fees.

There are two potential fees. Performance fees and protocol fees. Performance fees are configurable by management of the strategy and payed based on the reported profit during each report. Protocol fees are configured by Yearn governance and span across all strategies and all vaults. It is charged as a fee over the full amount of assets the strategy controls.

### Profit distribution 
Profit from report calls will accumulate in a buffer. This buffer will be linearly unlocked over the locking period seconds at profitUnlockingRate. 

Profits will be locked for a max period of time of profitMaxUnlockTime seconds and will be gradually distributed. To avoid spending too much gas for profit unlock, the amount of time a profit will be locked is a weighted average between the new profit and the previous profit. 

new_locking_period = locked_profit * pending_time_to_unlock + new_profit * PROFIT_MAX_UNLOCK_TIME / (locked_profit + new_profit)
new_profit_unlocking_rate = (locked_profit + new_profit) / new_locking_period

Losses will be offset by locked profit, if possible.

Issue of new shares due to fees will also unlock profit so that pps does not go down. 

Both of this offsets will prevent frontrunning (as the profit was already earned and was not distributed yet)

## Strategy Management
Strategy management is held by the 'management' address that can be updated at any time by the current 'managment'

Management has the ability to set all the configurable variables for their specific implemenation.

The base strategy has purposely been written to limit the actual control management has over any important functionality. Meaning they are not capable of stealing any funds from the strategy or otherwise tampering with deposited funds, unless purposefully written in within their specific implementation.

The configurable variables within managements control are: 

### Setting Management
This allows the current management to set a new non-zero address as the management of the strategy.

#### Setting the keeper
Setting the address that is also allowed to call reporting functions such as report and tend.

#### Setting Performance Fee
Setting the percent in terms of Basis points for the amount of profit to be charged as a fee.

The max this can be 99.99%.

#### Setting performance fee recpient
Setting the non-zero address that will receive any shares issued as a result of the perforamnce fee.

#### Setting the profit unlock period
Sets the time in seconds that controls how fast profits will unlock.

This can be customized based on the strategy. Based on aspects such as TVL, expected returns etc.

## ERC4626 compliance
Strategy Shares are ERC4626 compliant. 

## Emergency Operation

There is no default emergency setting built into the strategy. Each individual developer will have to consider its own risks and can implement their owne emergency withdraw functionality if desired.

### Withdrawals
Withdrawals can't be paused under any circumstance unless built in a specific implementation.
