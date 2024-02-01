// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {ExtendedTest} from "../utils/ExtendedTest.sol";
import {Setup, IMockStrategy, ERC20Mock} from "../utils/Setup.sol";
import {LibAddressSet, AddressSet} from "../utils/LibAddressSet.sol";

contract StrategyHandler is ExtendedTest {
    using LibAddressSet for AddressSet;

    Setup public setup;
    IMockStrategy public strategy;
    ERC20Mock public asset;

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

    bool public unreported;

    mapping(bytes32 => uint256) public calls;

    AddressSet internal _actors;
    address internal actor;

    modifier createActor() {
        actor = msg.sender;
        _actors.add(msg.sender);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        actor = _actors.rand(actorIndexSeed);
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
        skip(10);
    }

    function deposit(uint256 _amount) public createActor countCall("deposit") {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);

        asset.mint(actor, _amount);
        vm.prank(actor);
        asset.approve(address(strategy), _amount);

        vm.prank(actor);
        strategy.deposit(_amount, actor);

        ghost_depositSum += _amount;
    }

    function mint(uint256 _amount) public createActor countCall("mint") {
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
        uint256 actorSeed,
        uint256 _amount
    ) public useActor(actorSeed) countCall("withdraw") {
        if (strategy.maxWithdraw(address(actor)) == 0) {
            unchecked {
                deposit(_amount * 2);
            }
        }
        _amount = bound(_amount, 0, strategy.maxWithdraw(address(actor)));
        if (_amount == 0) ghost_zeroWithdrawals++;

        vm.prank(actor);
        strategy.withdraw(_amount, actor, actor, 0);

        ghost_withdrawSum += _amount;
    }

    function redeem(
        uint256 actorSeed,
        uint256 _amount
    ) public useActor(actorSeed) countCall("redeem") {
        if (strategy.balanceOf(address(actor)) == 0) {
            unchecked {
                mint(_amount * 2);
            }
        }
        _amount = bound(_amount, 0, strategy.balanceOf(address(actor)));
        if (_amount == 0) ghost_zeroWithdrawals++;

        vm.prank(actor);
        uint256 assets = strategy.redeem(_amount, actor, actor, 0);

        ghost_withdrawSum += assets;
    }

    function reportProfit(uint256 _amount) public countCall("reportProfit") {
        _amount = bound(_amount, 1, strategy.totalAssets() / 2);

        // Simulate earning interest
        asset.mint(address(strategy), _amount);

        vm.prank(setup.keeper());
        (uint256 profit, uint256 loss) = strategy.report();

        ghost_profitSum += profit;
        ghost_lossSum += loss;
        unreported = false;
    }

    function reportLoss(uint256 _amount) public countCall("reportLoss") {
        _amount = bound(_amount, 0, strategy.totalAssets() / 2);

        // Simulate losing money
        vm.prank(address(setup.yieldSource()));
        asset.transfer(address(69), _amount);

        vm.prank(setup.keeper());
        (uint256 profit, uint256 loss) = strategy.report();

        ghost_profitSum += profit;
        ghost_lossSum += loss;
        unreported = false;
    }

    function tend(uint256 _amount) public countCall("tend") {
        _amount = bound(_amount, 1, strategy.totalAssets() / 2);
        asset.mint(address(strategy), _amount);

        vm.prank(setup.keeper());
        strategy.tend();
    }

    function approve(
        uint256 actorSeed,
        uint256 spenderSeed,
        uint256 amount
    ) public useActor(actorSeed) countCall("approve") {
        address spender = _actors.rand(spenderSeed);

        vm.prank(actor);
        strategy.approve(spender, amount);
    }

    function transfer(
        uint256 actorSeed,
        uint256 toSeed,
        uint256 amount
    ) public useActor(actorSeed) countCall("transfer") {
        address to = _actors.rand(toSeed);

        amount = bound(amount, 0, strategy.balanceOf(actor));
        if (amount == 0) ghost_zeroTransfers++;

        vm.prank(actor);
        strategy.transfer(to, amount);
    }

    function transferFrom(
        uint256 actorSeed,
        uint256 fromSeed,
        uint256 amount
    ) public useActor(actorSeed) countCall("transferFrom") {
        address from = _actors.rand(fromSeed);
        address to = msg.sender;
        _actors.add(msg.sender);

        amount = bound(amount, 0, strategy.balanceOf(from));
        uint256 allowance = strategy.allowance(actor, from);
        if (allowance != 0) {
            vm.prank(from);
            strategy.approve(actor, 0);
        }

        vm.prank(from);
        strategy.approve(actor, amount);

        if (amount == 0) ghost_zeroTransferFroms++;

        vm.prank(actor);
        strategy.transferFrom(from, to, amount);
    }

    function unreportedLoss(
        uint256 _amount
    ) public countCall("unreportedLoss") {
        _amount = bound(_amount, 0, strategy.totalAssets() / 10);

        // Simulate losing money
        vm.prank(address(setup.yieldSource()));
        asset.transfer(address(69), _amount);

        ghost_unreportedLossSum += _amount;
        unreported = true;
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
        console.log("unreportedLoss", calls["unreportedLoss"]);
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
}
