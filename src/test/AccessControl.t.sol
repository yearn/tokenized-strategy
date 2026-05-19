// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";

import {BaseStrategy, ERC20} from "../BaseStrategy.sol";
import {ITokenizedStrategy} from "../interfaces/ITokenizedStrategy.sol";

// Minimal strategy that overrides `_initialize` to demonstrate that role
// addresses passed to `super._initialize` land in the correct storage slots.
// The override uses named arguments, so it only compiles when the parent's
// parameter names align with `ITokenizedStrategy.initialize`.
contract CustomInitMockStrategy is BaseStrategy {
    address internal constant CUSTOM_MANAGEMENT =
        0x1111111111111111111111111111111111111111;
    address internal constant CUSTOM_FEE_RECIPIENT =
        0x2222222222222222222222222222222222222222;
    address internal constant CUSTOM_KEEPER =
        0x3333333333333333333333333333333333333333;

    constructor(address _asset) BaseStrategy(_asset, "Custom Init") {}

    function _initialize(
        address _asset,
        string memory _name,
        address,
        address,
        address
    ) internal override {
        super._initialize({
            _asset: _asset,
            _name: _name,
            _management: CUSTOM_MANAGEMENT,
            _performanceFeeRecipient: CUSTOM_FEE_RECIPIENT,
            _keeper: CUSTOM_KEEPER
        });
    }

    function _deployFunds(uint256) internal override {}

    function _freeFunds(uint256) internal override {}

    function _totalAssets() internal view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function _harvestAndReport() internal override returns (uint256) {
        return _totalAssets();
    }
}

contract AccessControlTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_setManagement(address _address) public {
        vm.assume(_address != management && _address != address(0));

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdatePendingManagement(_address);

        vm.prank(management);
        strategy.setPendingManagement(_address);

        assertEq(strategy.pendingManagement(), _address);
        assertEq(strategy.management(), management);

        vm.prank(_address);
        strategy.acceptManagement();

        assertEq(strategy.pendingManagement(), address(0));
        assertEq(strategy.management(), _address);
    }

    function test_setKeeper(address _address) public {
        vm.assume(_address != keeper);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdateKeeper(_address);

        vm.prank(management);
        strategy.setKeeper(_address);

        assertEq(strategy.keeper(), _address);
    }

    function test_setPerformanceFee(uint16 _amount) public {
        _amount = uint16(bound(_amount, 500, 5_000));

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdatePerformanceFee(_amount);

        vm.prank(management);
        strategy.setPerformanceFee(_amount);

        assertEq(strategy.performanceFee(), _amount);
    }

    function test_setPerformanceFeeRecipient(address _address) public {
        vm.assume(
            _address != performanceFeeRecipient &&
                _address != address(0) &&
                _address != address(strategy)
        );

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdatePerformanceFeeRecipient(_address);

        vm.prank(management);
        strategy.setPerformanceFeeRecipient(_address);

        assertEq(strategy.performanceFeeRecipient(), _address);
    }

    function test_setProfitMaxUnlockTime(uint256 _amount) public {
        uint256 amount = bound(_amount, 1, type(uint32).max - 1);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdateProfitMaxUnlockTime(amount);

        vm.prank(management);
        strategy.setProfitMaxUnlockTime(amount);

        assertEq(strategy.profitMaxUnlockTime(), amount);
    }

    function test_setProfitMaxUnlockTime_clamps(uint256 _amount) public {
        uint256 amount = bound(_amount, type(uint32).max, type(uint256).max);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdateProfitMaxUnlockTime(amount);

        vm.prank(management);
        strategy.setProfitMaxUnlockTime(amount);

        assertEq(strategy.profitMaxUnlockTime(), type(uint256).max);
    }

    function test_shutdown() public {
        assertTrue(!strategy.isShutdown());

        vm.expectEmit(true, true, true, true, address(strategy));
        emit StrategyShutdown();

        vm.prank(management);
        strategy.shutdownStrategy();

        assertTrue(strategy.isShutdown());
    }

    function test_emergencyWithdraw() public {
        vm.prank(management);
        strategy.shutdownStrategy();

        assertTrue(strategy.isShutdown());

        vm.prank(management);
        strategy.emergencyWithdraw(0);
    }

    function test_setManagement_reverts(address _address) public {
        vm.assume(_address != management && _address != address(0));

        address _management = strategy.management();

        vm.prank(_address);
        vm.expectRevert("!management");
        strategy.setPendingManagement(address(69));

        assertEq(strategy.management(), _management);
        assertEq(strategy.pendingManagement(), address(0));

        vm.prank(management);
        strategy.setPendingManagement(_address);

        assertEq(strategy.management(), _management);
        assertEq(strategy.pendingManagement(), _address);

        vm.expectRevert("!pending");
        vm.prank(management);
        strategy.acceptManagement();
    }

    function test_setKeeper_reverts(address _address) public {
        vm.assume(_address != management);

        address _keeper = strategy.keeper();

        vm.prank(_address);
        vm.expectRevert("!management");
        strategy.setKeeper(address(69));

        assertEq(strategy.keeper(), _keeper);
    }

    function test_settingPerformanceFee_reverts(
        address _address,
        uint16 _amount
    ) public {
        _amount = uint16(bound(_amount, 500, 5_000));
        vm.assume(_address != management);

        uint256 _performanceFee = strategy.performanceFee();

        vm.prank(_address);
        vm.expectRevert("!management");
        strategy.setPerformanceFee(_amount);

        assertEq(strategy.performanceFee(), _performanceFee);

        vm.prank(management);
        vm.expectRevert("MAX FEE");
        strategy.setPerformanceFee(uint16(_amount + 5_001));
    }

    function test_settingPerformanceFeeRecipient_reverts(
        address _address
    ) public {
        vm.assume(_address != management && _address != address(strategy));

        address _performanceFeeRecipient = strategy.performanceFeeRecipient();

        vm.prank(_address);
        vm.expectRevert("!management");
        strategy.setPerformanceFeeRecipient(address(69));

        vm.prank(management);
        vm.expectRevert("Cannot be self");
        strategy.setPerformanceFeeRecipient(address(strategy));

        assertEq(strategy.performanceFeeRecipient(), _performanceFeeRecipient);
    }

    function test_settingProfitMaxUnlockTime_reverts(
        address _address,
        uint256 _amount
    ) public {
        uint256 amount = bound(_amount, 1, type(uint32).max - 1);
        vm.assume(_address != management);

        uint256 profitMaxUnlockTime = strategy.profitMaxUnlockTime();

        vm.prank(_address);
        vm.expectRevert("!management");
        strategy.setProfitMaxUnlockTime(amount);

        assertEq(strategy.profitMaxUnlockTime(), profitMaxUnlockTime);
    }

    function test_shutdown_reverts(address _address) public {
        vm.assume(_address != management && _address != emergencyAdmin);
        assertTrue(!strategy.isShutdown());

        vm.prank(_address);
        vm.expectRevert("!emergency authorized");
        strategy.shutdownStrategy();

        assertTrue(!strategy.isShutdown());
    }

    function test_emergencyWithdraw_reverts(address _address) public {
        vm.assume(_address != management && _address != emergencyAdmin);

        vm.prank(management);
        strategy.shutdownStrategy();

        assertTrue(strategy.isShutdown());

        vm.prank(_address);
        vm.expectRevert("!emergency authorized");
        strategy.emergencyWithdraw(0);
    }

    function test_initializeTokenizedStrategy_reverts(
        address _address,
        string memory name_
    ) public {
        vm.assume(_address != address(0));

        assertEq(tokenizedStrategy.management(), address(0));
        assertEq(tokenizedStrategy.keeper(), address(0));

        vm.expectRevert("initialized");
        tokenizedStrategy.initialize(
            address(asset),
            name_,
            _address,
            _address,
            _address
        );

        assertEq(tokenizedStrategy.management(), address(0));
        assertEq(tokenizedStrategy.keeper(), address(0));
    }

    function test_accessControl_deployFunds(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(strategy));

        asset.mint(address(strategy), _amount);

        // doesn't work from random address
        vm.prank(_address);
        vm.expectRevert("!self");
        strategy.deployFunds(_amount);

        vm.prank(management);
        vm.expectRevert("!self");
        strategy.deployFunds(_amount);

        assertEq(asset.balanceOf(address(yieldSource)), 0);

        vm.prank(address(strategy));
        strategy.deployFunds(_amount);

        // make sure we deposited into the funds
        assertEq(asset.balanceOf(address(yieldSource)), _amount, "!out");
    }

    function test_accessControl_freeFunds(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(strategy));

        // deposit into the vault and should deploy funds
        mintAndDepositIntoStrategy(strategy, user, _amount);

        // assure the deposit worked correctly
        assertEq(asset.balanceOf(address(yieldSource)), _amount);
        assertEq(asset.balanceOf(address(strategy)), 0);

        // doesn't work from random address
        vm.prank(_address);
        vm.expectRevert("!self");
        strategy.freeFunds(_amount);
        (_amount);

        // doesn't work from management either
        vm.prank(management);
        vm.expectRevert("!self");
        strategy.freeFunds(_amount);

        assertEq(asset.balanceOf(address(strategy)), 0);

        vm.prank(address(strategy));
        strategy.freeFunds(_amount);

        assertEq(asset.balanceOf(address(yieldSource)), 0);
        assertEq(asset.balanceOf(address(strategy)), _amount, "!out");
    }

    function test_accessControl_strategyTotalAssets(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(0) && _address != address(strategy));

        // deposit into the vault and should deploy funds
        mintAndDepositIntoStrategy(strategy, user, _amount);
        asset.mint(address(strategy), _amount);

        // works from random address
        vm.prank(_address);
        assertEq(strategy.strategyTotalAssets(), _amount * 2, "!random");

        // works from management
        vm.prank(management);
        assertEq(strategy.strategyTotalAssets(), _amount * 2, "!management");
    }

    function test_accessControl_harvestAndReport(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(strategy));

        // deposit into the vault and should deploy funds
        mintAndDepositIntoStrategy(strategy, user, _amount);

        // assure the deposit worked correctly
        assertEq(asset.balanceOf(address(yieldSource)), _amount);
        assertEq(asset.balanceOf(address(strategy)), 0);

        // doesn't work from random address
        vm.prank(_address);
        vm.expectRevert("!self");
        strategy.harvestAndReport();

        // doesn't work from management either
        vm.prank(management);
        vm.expectRevert("!self");
        strategy.harvestAndReport();

        vm.prank(address(strategy));
        uint256 amountOut = strategy.harvestAndReport();

        assertEq(amountOut, _amount, "!out");
    }

    function test_accessControl_tendThis(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != address(strategy));

        // doesn't work from random address
        vm.prank(_address);
        vm.expectRevert("!self");
        strategy.tendThis(_amount);

        vm.prank(address(strategy));
        strategy.tendThis(_amount);
    }

    function test_accessControl_tend(address _address, uint256 _amount) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(_address != keeper && _address != management);

        asset.mint(address(strategy), _amount);

        // doesn't work from random address
        vm.prank(_address);
        vm.expectRevert("!keeper");
        strategy.tend();

        vm.prank(keeper);
        strategy.tend();
    }

    function test_initializeOverride_routesAddressesToCorrectSlots() public {
        CustomInitMockStrategy custom = new CustomInitMockStrategy(
            address(asset)
        );
        ITokenizedStrategy s = ITokenizedStrategy(address(custom));

        assertEq(
            s.management(),
            0x1111111111111111111111111111111111111111,
            "!management"
        );
        assertEq(
            s.performanceFeeRecipient(),
            0x2222222222222222222222222222222222222222,
            "!performanceFeeRecipient"
        );
        assertEq(
            s.keeper(),
            0x3333333333333333333333333333333333333333,
            "!keeper"
        );
    }

    function test_setName(address _address) public {
        vm.assume(_address != address(strategy) && _address != management);

        string memory newName = "New Strategy Name";

        vm.prank(_address);
        vm.expectRevert("!management");
        strategy.setName(newName);

        vm.prank(management);
        strategy.setName(newName);

        assertEq(strategy.name(), newName);
    }
}
