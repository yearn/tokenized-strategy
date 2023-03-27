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

import {DiamondHelper} from "../../DiamondHelper.sol";
import {BaseLibrary} from "../../libraries/BaseLibrary.sol";

contract Setup is ExtendedTest {
    // Contract instancees that we will use repeatedly.
    ERC20Mock public asset;
    IMockStrategy public strategy;
    MockRegistry public registry;
    MockFactory public mockFactory;
    MockYieldSource public yieldSource;
    DiamondHelper public diamondHelper;

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
        // deploy the selector helper first to get a deterministic location
        bytes4[] memory selectors = getSelectors();
        diamondHelper = new DiamondHelper(selectors);

        // deploy the mock factory next for deterministic location
        mockFactory = new MockFactory(0, protocolFeeRecipient);

        // Finally deploy the mock registry for deterministic location
        registry = new MockRegistry();

        // Set the address of the library in the diamond Helper
        diamondHelper.setLibrary(address(BaseLibrary));

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
        vm.label(address(BaseLibrary), "library");
        vm.label(address(mockFactory), "mock Factory");
        vm.label(address(mockRegistry), "mock registry");
        vm.label(address(diamondHelper), "Diamond heleper");
        vm.label(address(yieldSource), "Mock Yield Source");
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
        emit BaseLibrary.Reported(profit, 0, _performanceFees, _protocolFees);

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
        emit BaseLibrary.Reported(0, loss, _performanceFees, _protocolFees);

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

    // prettier-ignore
    function getSelectors() public pure returns (bytes4[] memory selectors) {
        string[60] memory _selectors = [
            "0x3644e515",
            "0xdd62ed3e",
            "0x25829410",
            "0x095ea7b3",
            "0x38d52e0f",
            "0x70a08231",
            "0x5e04a4d6",
            "0x07a2d13a",
            "0xc6e6f592",
            "0x313ce567",
            "0xa457c2d7",
            "0x6e553f65",
            "0x1f931c1c",
            "0xcdffacc6",
            "0x52ef6b2c",
            "0xadfca15e",
            "0x7a0ed627",
            "0x2d632692",
            "0x39509351",
            "0x2ecfe315",
            "0x1d3b7227",
            "0xec0c7e28",
            "0xaced1661",
            "0xc3535b52",
            "0x88a8d602",
            "0x402d267d",
            "0xc63d75b6",
            "0xd905777e",
            "0xce96cb77",
            "0x94bf804d",
            "0x06fdde03",
            "0x7ecebe00",
            "0x87788782",
            "0xed27f7c9",
            "0xd505accf",
            "0xef8b30f7",
            "0xb3d7f6b9",
            "0x4cdad506",
            "0x0a28a477",
            "0x99530b06",
            "0x0952864e",
            "0x5141eebb",
            "0xba087652",
            "0x2606a10b",
            "0x748747e6",
            "0xd4a22bde",
            "0xaa290e6d",
            "0x6a5f1aa2",
            "0xdf69b22a",
            "0x95d89b41",
            "0x440368a3",
            "0x01e1d114",
            "0xfc7b9c18",
            "0x9aa7df94",
            "0x18160ddd",
            "0xa9059cbb",
            "0x23b872dd",
            "0xb460af94",
            "0xbf86d690",
            "0xbe8f1668"
        ];
        selectors = new bytes4[](_selectors.length);
        for (uint256 i; i < _selectors.length; ++i) {
            selectors[i] = bytes4(bytes(_selectors[i]));
        }
    }
}
