
# Yearn Tokenized Strategy

This repository contains the base code for the Yearn V3 "Tokenized Strategy" implementation. The V3 strategy implementation utilizes an immutable proxy pattern to allow anyone to easily create their own single strategy 4626 vault. All Tokenized Strategies will use the logic held within the `TokenizedStrategy` for their redundant and high risk code. The implementation holds all ERC-20, ERC-4626, profit locking and reporting functionality to make any strategy that uses it a fully permissionless vault without holding any of this logic itself. 

The implementation address that calls are delegated to is pre-set to a constant and can never be changed post deployment. The implementation contract itself is ownerless and can never be updated in any way.

NOTE: The master branch has these pre-set addresses set based on the deterministic address that testing on a local device will render. These contracts should NOT be used in production and any live versions should use an official [release](https://github.com/yearn/tokenized-strategy/releases).

A Strategy contract can become a fully ERC-4626 compliant vault by inheriting the `BaseStrategy` contract, that uses the fallback function to delegateCall the previously deployed version of `TokenizedStrategy`. A strategist then only needs to override three simple functions in their specific strategy.

[TokenizedStrategy](https://github.com/yearn/tokenized-strategy/blob/master/src/TokenizedStrategy.sol) - The implementation contract that holds all logic for every strategy.

[BaseStrategy](https://github.com/yearn/tokenized-strategy/blob/master/src/BaseStrategy.sol) - Abstract contract to inherit that communicates with the `TokenizedStrategy`.

Full tech spech can be found [here](https://github.com/yearn/tokenized-strategy/blob/master/SPECIFICATION.md)

## Installation and Setup

1. First you will need to install [Foundry](https://book.getfoundry.sh/getting-started/installation).
NOTE: If you are on a windows machine it is recommended to use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

2. Fork this repository (easier) or create a new repository using it as template. [Create from template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)

3. Clone your newly created repository recursively to include modules.

```sh
git clone --recursive https://github.com/myuser/tokenized-strategy

cd tokenized-strategy
```

NOTE: if you create from template you may need to run the following command to fetch the git sub modules (.gitmodules for exact releases) `git submodule init && git submodule update`

4. Build the project.

```sh
make build
```
To print the size of each contract
```sh
make size
```

5. Run tests
NOTE: Tests will take a significant period of time since the fuzzer is set to 10,000 runs.
```sh
make test
```

## Testing

Run all tests run on a local chain

```sh
make test
```
Run all tests with traces (very useful)

```sh
make trace
```
Run all tests with gas outputs

```sh
make gas
```
Run specific test contract with traces (e.g. `test/StrategyOperation.t.sol`)

```sh
make trace-contract contract=StrategyOperationsTest
```
Run specific test with traces (e.g. `test/StrategyOperation.t.sol::testStrategy`)

```sh
make trace-test test=testStrategy
```

See here for some tips on testing [`Testing Tips`](https://book.getfoundry.sh/forge/tests.html)

## Storage Layout

To print out the storage layout of any contract (e.g 'test/MockStrategy.sol')

```sh
make inspect contract=MockStrategy
```

## Deployment

Deployments of the TokenizedStrategy are done using create2 to be at a deterministic address on any EVM chain.

Check the [docs](https://docs.yearn.fi/developers/v3/overview) for the most updated deployment address.

Deployments on new chains can be done permissionlessly by anyone using the included script. First follow the steps to deploy the vault factory from the [Vaults V3](https://github.com/yearn/yearn-vaults-v3/tree/3.0.2) repo.

You can then deploy the TokenizedStrategy using the provided scipt.

```
forge script script/Deploy.s.sol:Deploy --rpc-url YOUR_RPC_URL
```

### To make contributions please follow the [Contribution Guidelines](https://github.com/yearn/tokenized-strategy/blob/master/CONTRIBUTING.md)

# Resources

- [Getting help on Foundry](https://github.com/gakonst/foundry#getting-help)
- [Forge Standard Lib](https://github.com/brockelmore/forge-std)
- [Awesome Foundry](https://github.com/crisgarner/awesome-foundry)
- [Foundry Book](https://book.getfoundry.sh/)
- [Learn Foundry Tutorial](https://www.youtube.com/watch?v=Rp_V7bYiTCM)
