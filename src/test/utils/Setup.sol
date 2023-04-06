// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {ExtendedTest} from "./ExtendedTest.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

import {IMockStrategy} from "../mocks/IMockStrategy.sol";
import {MockStrategy, MockYieldSource} from "../mocks/MockStrategy.sol";
import {MockIlliquidStrategy} from "../mocks/MockIlliquidStrategy.sol";
import {MockFaultyStrategy} from "../mocks/MockFaultyStrategy.sol";
import {MockRegistry} from "../mocks/MockRegistry.sol";
import {MockFactory} from "../mocks/MockFactory.sol";

import {TokenizedLogic} from "../../TokenizedLogic.sol";
import {IEvents} from "../../interfaces/IEvents.sol";

//import {BaseLibrary} from "../../libraries/BaseLibrary.sol";

contract Setup is ExtendedTest, IEvents {
    // Contract instancees that we will use repeatedly.
    ERC20Mock public asset;
    IMockStrategy public strategy;
    MockFactory public mockFactory;
    MockRegistry public mockRegistry;
    MockYieldSource public yieldSource;
    TokenizedLogic public tokenizedLogic;

    // Addresses for different roles we will use repeatedly.
    address public user = address(10);
    address public keeper = address(4);
    address public management = address(1);
    address public protocolFeeRecipient = address(2);
    address public performanceFeeRecipient = address(3);

    // Integer variables that will be used repeatedly.
    uint256 public decimals = 18;
    uint256 public MAX_BPS = 10_000;
    uint256 public wad = 10 ** decimals;
    // Fuzz from $0.01 of 1e6 stable coins up to 1 trillion of a 1e18 coin
    uint256 public maxFuzzAmount = 1e30;
    uint256 public minFuzzAmount = 10_000;
    uint256 public profitMaxUnlockTime = 10 days;

    function setUp() public virtual {
        // deploy the mock factory next for deterministic location
        mockFactory = new MockFactory(0, protocolFeeRecipient);
        //console.log("Mock Factory ", address(mockFactory));

        // Finally deploy the mock registry for deterministic location
        mockRegistry = new MockRegistry();
        //console.log("Registry, ", address(mockRegistry));

        tokenizedLogic = new TokenizedLogic();
        //console.log("Token addy ", address(tokenizedLogic));

        // create asset we will be using as the underlying asset
        asset = new ERC20Mock("Mock asset", "mcAsset", user, 0);

        // create a mock yield source to deposit into
        yieldSource = new MockYieldSource(address(asset));

        // Deploy strategy and set variables
        strategy = IMockStrategy(setUpStrategy());

        // label all the used addresses for traces
        vm.label(keeper, "keeper");
        vm.label(address(asset), "asset");
        vm.label(management, "management");
        vm.label(address(strategy), "strategy");
        vm.label(address(mockFactory), "mock Factory");
        vm.label(address(mockRegistry), "mock registry");
        vm.label(address(yieldSource), "Mock Yield Source");
        vm.label(address(tokenizedLogic), "tokenized Logic");
        vm.label(protocolFeeRecipient, "protocolFeeRecipient");
        vm.label(performanceFeeRecipient, "performanceFeeRecipient");
    }

    function setUpStrategy() public returns (address) {
        // we save the mock base strategy as a IMockStrategy to give it the needed interface
        IMockStrategy _strategy = IMockStrategy(
            address(new MockStrategy(address(asset), address(yieldSource)))
        );

        // set keeper
        _strategy.setKeeper(keeper);
        // set treasury
        _strategy.setPerformanceFeeRecipient(performanceFeeRecipient);
        // set management of the strategy
        _strategy.setManagement(management);

        return address(_strategy);
    }

    function setUpIlliquidStrategy() public returns (address) {
        IMockStrategy _strategy = IMockStrategy(
            address(
                new MockIlliquidStrategy(address(asset), address(yieldSource))
            )
        );

        // set keeper
        _strategy.setKeeper(keeper);
        // set treasury
        _strategy.setPerformanceFeeRecipient(performanceFeeRecipient);
        // set management of the strategy
        _strategy.setManagement(management);

        return address(_strategy);
    }

    function setUpFaultyStrategy() public returns (address) {
        IMockStrategy _strategy = IMockStrategy(
            address(
                new MockFaultyStrategy(address(asset), address(yieldSource))
            )
        );

        // set keeper
        _strategy.setKeeper(keeper);
        // set treasury
        _strategy.setPerformanceFeeRecipient(performanceFeeRecipient);
        // set management of the strategy
        _strategy.setManagement(management);

        return address(_strategy);
    }

    function mintAndDepositIntoStrategy(
        IMockStrategy _strategy,
        address _user,
        uint256 _amount
    ) public {
        asset.mint(_user, _amount);
        vm.prank(_user);
        asset.approve(address(_strategy), _amount);

        vm.prank(_user);
        _strategy.deposit(_amount, _user);
    }

    function checkStrategyTotals(
        IMockStrategy _strategy,
        uint256 _totalAssets,
        uint256 _totalDebt,
        uint256 _totalIdle,
        uint256 _totalSupply
    ) public {
        assertEq(_strategy.totalAssets(), _totalAssets, "!totalAssets");
        assertEq(_strategy.totalDebt(), _totalDebt, "!totalDebt");
        assertEq(_strategy.totalIdle(), _totalIdle, "!totalIdle");
        assertEq(_totalAssets, _totalDebt + _totalIdle, "!Added");
        // We give supply a buffer or 1 wei for rounding
        assertApproxEq(_strategy.totalSupply(), _totalSupply, 1, "!supply");
    }

    // For checks without totalSupply while profit is unlocking
    function checkStrategyTotals(
        IMockStrategy _strategy,
        uint256 _totalAssets,
        uint256 _totalDebt,
        uint256 _totalIdle
    ) public {
        assertEq(_strategy.totalAssets(), _totalAssets, "!totalAssets");
        assertEq(_strategy.totalDebt(), _totalDebt, "!totalDebt");
        assertEq(_strategy.totalIdle(), _totalIdle, "!totalIdle");
        assertEq(_totalAssets, _totalDebt + _totalIdle, "!Added");
    }

    function createAndCheckProfit(
        IMockStrategy _strategy,
        uint256 profit,
        uint256 _protocolFees,
        uint256 _performanceFees
    ) public {
        uint256 startingAssets = _strategy.totalAssets();
        asset.mint(address(_strategy), profit);

        // Check the event matches the expected values
        vm.expectEmit(true, true, true, true, address(_strategy));
        emit Reported(profit, 0, _performanceFees, _protocolFees);

        vm.prank(keeper);
        (uint256 _profit, uint256 _loss) = _strategy.report();

        assertEq(profit, _profit, "profit reported wrong");
        assertEq(_loss, 0, "Reported loss");
        assertEq(
            _strategy.totalAssets(),
            startingAssets + profit,
            "total assets wrong"
        );
    }

    function createAndCheckLoss(
        IMockStrategy _strategy,
        uint256 loss,
        uint256 _protocolFees,
        uint256 _performanceFees
    ) public {
        uint256 startingAssets = _strategy.totalAssets();

        yieldSource.simulateLoss(loss);
        // Check the event matches the expected values
        vm.expectEmit(true, true, false, true, address(_strategy));
        emit Reported(0, loss, _performanceFees, _protocolFees);

        vm.prank(keeper);
        (uint256 _profit, uint256 _loss) = _strategy.report();

        assertEq(0, _profit, "profit reported wrong");
        assertEq(_loss, loss, "Reported loss");
        assertEq(
            _strategy.totalAssets(),
            startingAssets - loss,
            "total assets wrong"
        );
    }

    function increaseTimeAndCheckBuffer(
        IMockStrategy _strategy,
        uint256 _time,
        uint256 _buffer
    ) public {
        skip(_time);
        // We give a buffer or 1 wei for rounding
        assertApproxEq(
            _strategy.balanceOf(address(_strategy)),
            _buffer,
            1,
            "!Buffer"
        );
    }

    function getExpectedProtocolFee(
        uint256 _amount,
        uint16 _fee
    ) public view returns (uint256) {
        uint256 timePassed = Math.min(
            block.timestamp - strategy.lastReport(),
            block.timestamp - mockFactory.lastChange()
        );
        return (_amount * _fee * timePassed) / MAX_BPS / 31_556_952;
    }

    function setFees(uint16 _protocolFee, uint16 _performanceFee) public {
        mockFactory.setFee(_protocolFee);
        vm.prank(management);

        strategy.setPerformanceFee(_performanceFee);
    }

    function setupWhitelist(address _address) public {
        MockIlliquidStrategy _strategy = MockIlliquidStrategy(
            payable(address(strategy))
        );

        _strategy.setWhitelist(true);

        _strategy.allow(_address);
    }

    function configureFaultyStrategy(uint256 _fault, bool _callBack) public {
        MockFaultyStrategy _strategy = MockFaultyStrategy(
            payable(address(strategy))
        );

        _strategy.setFaultAmount(_fault);
        _strategy.setCallBack(_callBack);
    }
}
