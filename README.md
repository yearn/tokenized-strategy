
# Yearn Tokenized Strategy

This repository contains the base code for the Yearn V3 tokenized strategy implementation. The V3 strategy implementation utilizes a simplified and immutable proxy pattern to allow for strategies to all use the same `BaseLibrary` for their redundant and high risk code. The library holds all ERC-20, ERC-4626, ERC-2535, profit locking and reporting functionility to make any strategy that uses it a fully permisionless vault without holding any of the logic itself. 

NOTE: The library address that calls are delegated to is inherently stateless and is pre-set to a constant and can never be changed after post deployment.

An `implementation` contract can become a fully ERC-4626 vault by inheriting the `BaseStrategy` contract that uses the fallback function to delegateCall a previously deployed version of `BaseLibrary`. A strategist then only needs to override three simple functions in their specific implementation.

[BaseLibrary](https://github.com/yearn/tokenized-strategy/blob/master/src/libraries/BaseLibrary.sol) - The library that holds all logic for every strategy.

[BaseStrategy](https://github.com/yearn/tokenized-strategy/blob/master/src/BaseStrategy.sol) - Abastract contract to inherit that communicates with the `BaseLibrary`.

## Installation and Setup

1. First you will need to install [Foundry](https://book.getfoundry.sh/getting-started/installation).
NOTE: If you are on a windows machine it is recommended to use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

2. Fork this repository (easier) or create a new repository using it as template. [Create from template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)

3. Clone your newly created repository recursively to include modules.

```sh
git clone --recursive https://github.com/myuser/tokenized-strategy

cd tokenized-strategy
```

NOTE: if you create from template you may need to run the following command to fetch the git submodules (.gitmodules for exact releases) `git submodule init && git submodule update`

4. Build the project.

```sh
make build
```
To print the size of each contract
```sh
make size
```

5. Run tests
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

# Resources

- [Getting help on Foundry](https://github.com/gakonst/foundry#getting-help)
- [Forge Standard Lib](https://github.com/brockelmore/forge-std)
- [Awesome Foundry](https://github.com/crisgarner/awesome-foundry)
- [Foundry Book](https://book.getfoundry.sh/)
- [Learn Foundry Tutorial](https://www.youtube.com/watch?v=Rp_V7bYiTCM)
