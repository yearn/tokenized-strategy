
# Yearn V3 Base Strategy

This repository contains the code for the Yearn V3 BaseStrategy implementation. The V3 strategy implementation utilizes a simplified and immutable version of the ERC-2535 'Diamond Pattern' to allow for strategies to all use them same `BaseLibrary` for their redundant high risk code. The library holds all ERC-20, ERC-4626, ERC-2535 and profit locking and reporting functionility to make any strategy that uses it a fully permisionless vault without holding any of the logic itself. Each Strategy simply needs to utilize a fallback function that delegateCalls the library as seen in `BaseLibrary` and can become a fully funciton vault with only overriding three simple function in the implementation.

[BaseStrategy](https://github.com/Schlagonia/yearn-base-strategy/blob/master/src/BaseStrategy.sol) Abastract contract to inherit that communicates with the `BaseLibrary`.
[DiamondHelper](https://github.com/Schlagonia/yearn-base-strategy/blob/master/src/DiamondHelper.sol) Helper contract for the Library to use for all ERC-2535 'Diamond' functionality.
[BaseLibrary](https://github.com/Schlagonia/yearn-base-strategy/blob/master/src/libraries/BaseLibrary.sol) The library that holds all logic for every strategy.

## Installation and Setup

1. To install with [Foundry](https://github.com/gakonst/foundry).

2. Fork this repository (easier) or create a new repository using it as template. [Create from template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)

3. Clone your newly created repository recursively to include modules.

```sh
git clone --recursive https://github.com/myuser/yearn-base-strategy

cd yearn-base-strategy
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
