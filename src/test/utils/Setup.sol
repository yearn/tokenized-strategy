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
import {MockFactory} from "../mocks/MockFactory.sol";

import {TokenizedStrategy} from "../../TokenizedStrategy.sol";
import {IEvents} from "../../interfaces/IEvents.sol";

contract Setup is ExtendedTest, IEvents {
    // Contract instancees that we will use repeatedly.
    ERC20Mock public asset;
    IMockStrategy public strategy;
    MockFactory public mockFactory;
    MockYieldSource public yieldSource;
    TokenizedStrategy public tokenizedStrategy;

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

    bytes32 public constant BASE_STRATEGY_STORAGE =
        bytes32(uint256(keccak256("yearn.base.strategy.storage")) - 1);

    function setUp() public virtual {
        // Deploy the mock factory next for deterministic location
        mockFactory = new MockFactory(0, protocolFeeRecipient);

        // Finally deploy the implementation for deterministic location
        tokenizedStrategy = new TokenizedStrategy();

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
        vm.label(address(yieldSource), "Mock Yield Source");
        vm.label(address(tokenizedStrategy), "tokenized Logic");
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
        _strategy.setPendingManagement(management);

        vm.prank(management);
        _strategy.acceptManagement();

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
        _strategy.setPendingManagement(management);

        vm.prank(management);
        _strategy.acceptManagement();

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
        _strategy.setPendingManagement(management);

        vm.prank(management);
        _strategy.acceptManagement();

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
        emit Reported(profit, 0, _protocolFees, _performanceFees);

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
        bool _checkFees
    ) public {
        uint256 startingAssets = _strategy.totalAssets();

        yieldSource.simulateLoss(loss);
        // Check the event matches the expected values
        vm.expectEmit(true, true, true, _checkFees, address(_strategy));
        emit Reported(0, loss, _protocolFees, 0);

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

    function setFees(uint16 _protocolFee, uint16 _performanceFee) public {
        mockFactory.setFee(_protocolFee);

        // If 0 is passed for testing purposes we manually override
        // the minimum set in the TokenizedStrategy.
        if (_performanceFee == 0) {
            setPerformanceFeeToZero(address(strategy));
        } else {
            vm.prank(management);
            strategy.setPerformanceFee(_performanceFee);
        }
    }

    // For easier calculations we may want to set the performance fee
    // to 0 in some tests which is underneath the minimum. So we do it manually.
    function setPerformanceFeeToZero(address _strategy) public {
        bytes32 slot;
        TokenizedStrategy.StrategyData storage S = _strategyStorage();

        assembly {
            // Perf fee is stored in the 12th slot of the Struct.
            slot := add(S.slot, 12)
        }

        // Performance fee is packed in a slot with other variables so we need
        // to maintain the same variables packed in the slot

        // profitMaxUnlock time is a uint32 at the most significant spot.
        bytes32 data = bytes4(
            uint32(IMockStrategy(_strategy).profitMaxUnlockTime())
        );
        // Free up space for the uint16 of performancFee
        data = data >> 16;
        // Store 0 in the performance fee spot.
        data |= bytes2(0);
        // Shit 160 bits for an address
        data = data >> 160;
        // Store the strategies peformance fee recipient
        data |= bytes20(
            uint160(IMockStrategy(_strategy).performanceFeeRecipient())
        );
        // Shift the remainder of padding.
        data = data >> 48;

        // Manually set the storage slot that holds the perfomance fee to 0
        vm.store(_strategy, slot, data);
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

    function _strategyStorage()
        internal
        pure
        returns (TokenizedStrategy.StrategyData storage S)
    {
        // Since STORAGE_SLOT is a constant, we have to put a variable
        // on the stack to access it from an inline assembly block.
        bytes32 slot = BASE_STRATEGY_STORAGE;
        assembly {
            S.slot := slot
        }
    }
}
