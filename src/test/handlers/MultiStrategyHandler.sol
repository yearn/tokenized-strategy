// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {ExtendedTest} from "../utils/ExtendedTest.sol";
import {Setup, IMockStrategy, MockStrategy, MockYieldSource, ERC20Mock} from "../utils/Setup.sol";
import {LibAddressSet, AddressSet} from "../utils/LibAddressSet.sol";

contract MultiStrategyHandler is ExtendedTest {
    using LibAddressSet for AddressSet;

    Setup public setup;

    uint256 public maxFuzzAmount = 1e30;
    uint256 public minFuzzAmount = 10_000;

    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;
    uint256 public ghost_profitSum;
    uint256 public ghost_lossSum;
    uint256 public ghost_unreportedLossSum;

    uint256 public ghost_zeroDeposits;
    uint256 public ghost_zeroWithdrawals;
    uint256 public ghost_zeroTransfers;
    uint256 public ghost_zeroTransferFroms;

    mapping(bytes32 => uint256) public calls;

    AddressSet internal _actors;
    address internal actor;

    AddressSet internal _strategies;
    IMockStrategy public strategy;
    ERC20Mock public asset;

    modifier createActor() {
        actor = msg.sender;
        _actors.add(msg.sender);
        _;
    }

    modifier createStrategy() {
        strategy = createNewStrategy();
        asset = ERC20Mock(strategy.asset());
        _strategies.add(address(strategy));
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        actor = _actors.rand(actorIndexSeed);
        _;
    }

    modifier useStrategy(uint256 strategyIndexSeed) {
        strategy = IMockStrategy(_strategies.rand(strategyIndexSeed));
        asset = ERC20Mock(strategy.asset());
        _;
    }

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    constructor() {
        setup = Setup(msg.sender);

        asset = setup.asset();
        strategy = setup.strategy();
        _strategies.add(address(strategy));
    }

    function deposit(
        uint256 _amount
    ) public createStrategy createActor countCall("deposit") {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        asset.mint(actor, _amount);
        vm.prank(actor);
        asset.approve(address(strategy), _amount);

        vm.prank(actor);
        strategy.deposit(_amount, actor);

        ghost_depositSum += _amount;
    }

    function mint(
        uint256 _amount
    ) public createStrategy createActor countCall("mint") {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        uint256 toMint = strategy.previewMint(_amount);
        asset.mint(actor, toMint);

        vm.prank(actor);
        asset.approve(address(strategy), toMint);

        vm.prank(actor);
        uint256 assets = strategy.mint(_amount, actor);

        ghost_depositSum += assets;
    }

    function withdraw(
        uint256 strategySeed,
        uint256 actorSeed,
        uint256 _amount
    )
        public
        useStrategy(strategySeed)
        useActor(actorSeed)
        countCall("withdraw")
    {
        if (strategy.maxWithdraw(address(actor)) == 0) {
            actor = msg.sender;
            _actors.add(msg.sender);
            unchecked {
                deposit(_amount * 2);
            }
        }
        _amount = bound(_amount, 0, strategy.maxWithdraw(address(actor)));
        if (_amount == 0) ghost_zeroWithdrawals++;

        vm.prank(actor);
        strategy.withdraw(_amount, actor, actor);

        ghost_withdrawSum += _amount;
    }

    function redeem(
        uint256 strategySeed,
        uint256 actorSeed,
        uint256 _amount
    ) public useStrategy(strategySeed) useActor(actorSeed) countCall("redeem") {
        if (strategy.balanceOf(address(actor)) == 0) {
            actor = msg.sender;
            _actors.add(msg.sender);
            unchecked {
                mint(_amount * 2);
            }
        }
        _amount = bound(_amount, 0, strategy.balanceOf(address(actor)));
        if (_amount == 0) ghost_zeroWithdrawals++;

        vm.prank(actor);
        uint256 assets = strategy.redeem(_amount, actor, actor);

        ghost_withdrawSum += assets;
    }

    function reportProfit(
        uint256 strategySeed,
        uint256 _amount
    ) public useStrategy(strategySeed) countCall("reportProfit") {
        _amount = bound(_amount, 1, strategy.totalAssets() / 2);

        // Simulate earning interest
        asset.mint(address(strategy), _amount);

        vm.prank(setup.keeper());
        strategy.report();

        ghost_profitSum += _amount;
    }

    function reportLoss(
        uint256 strategySeed,
        uint256 _amount
    ) public useStrategy(strategySeed) countCall("reportLoss") {
        _amount = bound(_amount, 0, strategy.totalAssets() / 2);

        // Simulate lossing money
        vm.prank(address(setup.yieldSource()));
        asset.transfer(address(69), _amount);

        vm.prank(setup.keeper());
        strategy.report();

        ghost_lossSum += _amount;
    }

    function tend(
        uint256 strategySeed,
        uint256 _amount
    ) public useStrategy(strategySeed) countCall("tend") {
        _amount = bound(_amount, 1, strategy.totalAssets() / 2);
        asset.mint(address(strategy), _amount);

        vm.prank(setup.keeper());
        strategy.tend();
    }

    function approve(
        uint256 strategySeed,
        uint256 actorSeed,
        uint256 spenderSeed,
        uint256 amount
    )
        public
        useStrategy(strategySeed)
        useActor(actorSeed)
        countCall("approve")
    {
        address spender = _actors.rand(spenderSeed);

        vm.prank(actor);
        strategy.approve(spender, amount);
    }

    function transfer(
        uint256 strategySeed,
        uint256 actorSeed,
        uint256 toSeed,
        uint256 amount
    )
        public
        useStrategy(strategySeed)
        useActor(actorSeed)
        countCall("transfer")
    {
        if (strategy.balanceOf(address(actor)) == 0) {
            actor = msg.sender;
            _actors.add(msg.sender);
            unchecked {
                mint(amount);
            }
        }

        address to = _actors.rand(toSeed);

        amount = bound(amount, 0, strategy.balanceOf(actor));
        if (amount == 0) ghost_zeroTransfers++;

        vm.prank(actor);
        strategy.transfer(to, amount);
    }

    function transferFrom(
        uint256 strategySeed,
        uint256 actorSeed,
        uint256 transfererSeed,
        uint256 toSeed,
        uint256 amount
    )
        public
        useStrategy(strategySeed)
        useActor(actorSeed)
        countCall("transferFrom")
    {
        if (strategy.balanceOf(address(actor)) == 0) {
            actor = msg.sender;
            _actors.add(msg.sender);
            unchecked {
                mint(amount);
            }
        }
        address transferer = _actors.rand(transfererSeed);
        if (actor == transferer) transferer = address(5969);
        address to = _actors.rand(toSeed);
        if (to == actor || to == transferer) to = address(696969);

        amount = bound(amount, 0, strategy.balanceOf(actor));
        uint256 allowance = strategy.allowance(transferer, actor);
        if (allowance == 0) {
            vm.prank(actor);
            strategy.approve(transferer, amount);
        } else if (allowance < amount) {
            strategy.increaseAllowance(transferer, amount - allowance);
        }
        if (amount == 0) ghost_zeroTransferFroms++;

        vm.prank(transferer);
        strategy.transferFrom(actor, to, amount);
    }

    function increaseTime() public countCall("skip") {
        skip(1 days);
    }

    function callSummary() external view {
        console.log("Call summary:");
        console.log("-------------------");
        console.log("deposit", calls["deposit"]);
        console.log("mint", calls["mint"]);
        console.log("withdraw", calls["withdraw"]);
        console.log("redeem", calls["redeem"]);
        console.log("report profit", calls["reportProfit"]);
        console.log("report loss", calls["reportLoss"]);
        console.log("tend", calls["tend"]);
        console.log("approve", calls["approve"]);
        console.log("transfer", calls["transfer"]);
        console.log("transferFrom", calls["transferFrom"]);
        console.log("skip", calls["skip"]);
        console.log("-------------------");
        console.log("Total Deposit sum", ghost_depositSum);
        console.log("Total withdraw sum", ghost_withdrawSum);
        console.log("Total Profit", ghost_profitSum);
        console.log("Total Loss", ghost_lossSum);
        console.log("Total unreported Loss", ghost_unreportedLossSum);
        console.log("-------------------");
        console.log("Amount of actors", _actors.count());
        console.log("Zero Deposits:", ghost_zeroDeposits);
        console.log("Zero withdrawals:", ghost_zeroWithdrawals);
        console.log("Zero transferFroms:", ghost_zeroTransferFroms);
        console.log("Zero transfers:", ghost_zeroTransfers);
    }

    function getStrategies() external view returns (address[] memory _addrs) {
        return _strategies.addresses();
    }

    function createNewStrategy() internal returns (IMockStrategy _strategy) {
        // create asset we will be using as the underlying asset
        ERC20Mock _asset = new ERC20Mock();

        // create a mock yield source to deposit into
        MockYieldSource yieldSource = new MockYieldSource(address(asset));

        _strategy = IMockStrategy(
            address(new MockStrategy(address(asset), address(yieldSource)))
        );

        // set keeper
        _strategy.setKeeper(setup.keeper());
        // set treasury
        _strategy.setPerformanceFeeRecipient(setup.performanceFeeRecipient());
        // set management of the strategy
        _strategy.setManagement(setup.management());
    }
}
