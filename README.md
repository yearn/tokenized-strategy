
# Yearn V3 Base Strategy


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
Run specific test contract (e.g. `test/StrategyOperation.t.sol`)

```sh
make test-contract contract=StrategyOperationsTest
```
Run specific test contract with traces (e.g. `test/StrategyOperation.t.sol`)

```sh
make trace-contract contract=StrategyOperationsTest
```
Run specific test contract with gas report (e.g. `test/StrategyOperation.t.sol`)

```sh
make test-contract-gas contract=StrategyOperationsTest
```
Run specific test (e.g. `test/StrategyOperation.t.sol::testStrategy`)

```sh
make test-test test=testStrategy
```
Run specific test with traces (e.g. `test/StrategyOperation.t.sol::testStrategy`)

```sh
make trace-test test=testStrategy
```

See here for some tips on testing [`Testing Tips`](https://book.getfoundry.sh/forge/tests.html)


# Resources

- [Getting help on Foundry](https://github.com/gakonst/foundry#getting-help)
- [Forge Standard Lib](https://github.com/brockelmore/forge-std)
- [Awesome Foundry](https://github.com/crisgarner/awesome-foundry)
- [Foundry Book](https://book.getfoundry.sh/)
- [Learn Foundry Tutorial](https://www.youtube.com/watch?v=Rp_V7bYiTCM)
