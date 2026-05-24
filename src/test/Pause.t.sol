// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import {Setup} from "./utils/Setup.sol";

contract PauseTest is Setup {
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    function setUp() public override {
        super.setUp();
    }

    function test_pauseAccessControl(address _address) public {
        vm.assume(_address != management && _address != emergencyAdmin);

        assertTrue(!strategy.isPaused());

        vm.prank(_address);
        vm.expectRevert("!emergency authorized");
        strategy.setPaused(true);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdatePaused(true);

        vm.prank(management);
        strategy.setPaused(true);

        assertTrue(strategy.isPaused());

        vm.prank(_address);
        vm.expectRevert("!management");
        strategy.setPaused(false);

        vm.prank(emergencyAdmin);
        vm.expectRevert("!management");
        strategy.setPaused(false);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdatePaused(false);

        vm.prank(management);
        strategy.setPaused(false);

        assertTrue(!strategy.isPaused());

        vm.expectEmit(true, true, true, true, address(strategy));
        emit UpdatePaused(true);

        vm.prank(emergencyAdmin);
        strategy.setPaused(true);

        assertTrue(strategy.isPaused());
    }

    function test_pauseBlocks4626UserFlows(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        vm.prank(emergencyAdmin);
        strategy.setPaused(true);

        assertTrue(strategy.isPaused());
        assertEq(strategy.maxDeposit(_address), 0);
        assertEq(strategy.maxMint(_address), 0);
        assertEq(strategy.maxWithdraw(_address), 0);
        assertEq(strategy.maxRedeem(_address), 0);
        assertEq(strategy.maxWithdraw(_address, 0), 0);
        assertEq(strategy.maxRedeem(_address, MAX_BPS), 0);

        vm.prank(_address);
        vm.expectRevert("paused");
        strategy.deposit(1, _address);

        vm.prank(_address);
        vm.expectRevert("paused");
        strategy.mint(1, _address);

        vm.prank(_address);
        vm.expectRevert("paused");
        strategy.withdraw(1, _address, _address);

        vm.prank(_address);
        vm.expectRevert("paused");
        strategy.withdraw(1, _address, _address, 0);

        vm.prank(_address);
        vm.expectRevert("paused");
        strategy.redeem(1, _address, _address);

        vm.prank(_address);
        vm.expectRevert("paused");
        strategy.redeem(1, _address, _address, MAX_BPS);
    }

    function test_unpauseRestores4626Flows(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        vm.prank(management);
        strategy.setPaused(true);

        vm.prank(management);
        strategy.setPaused(false);

        assertTrue(!strategy.isPaused());
        assertEq(strategy.maxRedeem(_address), _amount);

        uint256 before = asset.balanceOf(_address);

        vm.prank(_address);
        strategy.redeem(_amount, _address, _address);

        assertEq(asset.balanceOf(_address), before + _amount);
        checkStrategyTotals(strategy, 0, 0, 0, 0);
    }

    function test_unpauseDoesNotUndoShutdown(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        vm.prank(management);
        strategy.setPaused(true);

        vm.prank(emergencyAdmin);
        strategy.shutdownStrategy();

        vm.prank(management);
        strategy.setPaused(false);

        assertTrue(!strategy.isPaused());
        assertTrue(strategy.isShutdown());
        assertEq(strategy.maxDeposit(_address), 0);
        assertEq(strategy.maxMint(_address), 0);

        asset.mint(_address, _amount);
        vm.prank(_address);
        asset.approve(address(strategy), _amount);

        vm.prank(_address);
        vm.expectRevert("ERC4626: deposit more than max");
        strategy.deposit(_amount, _address);
    }

    function test_emergencyWithdrawWhenPaused(
        address _address,
        uint256 _amount
    ) public {
        _amount = bound(_amount, minFuzzAmount, maxFuzzAmount);
        vm.assume(
            _address != address(0) &&
                _address != address(strategy) &&
                _address != address(yieldSource)
        );

        mintAndDepositIntoStrategy(strategy, _address, _amount);

        vm.prank(emergencyAdmin);
        strategy.setPaused(true);

        uint256 toWithdraw = _amount / 2;

        vm.prank(emergencyAdmin);
        strategy.emergencyWithdraw(toWithdraw);

        checkStrategyTotals(
            strategy,
            _amount,
            _amount - toWithdraw,
            toWithdraw,
            _amount
        );
        assertEq(asset.balanceOf(address(strategy)), toWithdraw);
        assertTrue(!strategy.isShutdown());
    }

    function test_pauseLeavesERC20ShareFunctionsLive() public {
        uint256 ownerSk = 0xA11CE;
        address owner = vm.addr(ownerSk);
        address spender = address(0xBEEF);
        address recipient = address(0xCAFE);
        uint256 amount = 100 * wad;
        uint256 slice = amount / 4;

        mintAndDepositIntoStrategy(strategy, owner, amount);

        vm.prank(management);
        strategy.setPaused(true);

        vm.prank(owner);
        assertTrue(strategy.transfer(recipient, slice));

        vm.prank(owner);
        assertTrue(strategy.approve(spender, slice));
        assertEq(strategy.allowance(owner, spender), slice);

        vm.prank(spender);
        assertTrue(strategy.transferFrom(owner, recipient, slice));
        assertEq(strategy.allowance(owner, spender), 0);

        _permit(owner, spender, slice, block.timestamp + 1 days, ownerSk);

        assertEq(strategy.allowance(owner, spender), slice);
        assertEq(strategy.balanceOf(recipient), slice * 2);
        assertEq(strategy.balanceOf(owner), amount - slice * 2);
    }

    function test_pauseLeavesManagementFunctionsLive() public {
        uint256 amount = 100 * wad;
        uint256 profit = 10 * wad;
        uint256 idle = 5 * wad;
        address pendingManagement = address(0xB0B);
        address newKeeper = address(0xCA11);
        address newEmergencyAdmin = address(0xEAA);
        address newPerformanceFeeRecipient = address(0xFEE);
        string memory newName = "Paused Strategy";

        mintAndDepositIntoStrategy(strategy, user, amount);

        vm.prank(emergencyAdmin);
        strategy.setPaused(true);

        vm.prank(management);
        strategy.setPendingManagement(pendingManagement);
        assertEq(strategy.pendingManagement(), pendingManagement);

        vm.prank(management);
        strategy.setName(newName);
        assertEq(strategy.name(), newName);

        vm.prank(management);
        strategy.setPerformanceFee(1_234);
        assertEq(strategy.performanceFee(), 1_234);

        vm.prank(management);
        strategy.setPerformanceFeeRecipient(newPerformanceFeeRecipient);
        assertEq(
            strategy.performanceFeeRecipient(),
            newPerformanceFeeRecipient
        );

        vm.prank(management);
        strategy.setProfitMaxUnlockTime(7 days);
        assertEq(strategy.profitMaxUnlockTime(), 7 days);

        vm.prank(management);
        strategy.setKeeper(newKeeper);
        assertEq(strategy.keeper(), newKeeper);

        vm.prank(management);
        strategy.setEmergencyAdmin(newEmergencyAdmin);
        assertEq(strategy.emergencyAdmin(), newEmergencyAdmin);

        queueHarvestProfit(strategy, profit);

        vm.prank(newKeeper);
        (uint256 reportedProfit, uint256 reportedLoss) = strategy.report();
        assertEq(reportedProfit, profit);
        assertEq(reportedLoss, 0);

        asset.mint(address(strategy), idle);

        vm.prank(newKeeper);
        strategy.tend();
        assertEq(asset.balanceOf(address(strategy)), 0);

        vm.prank(newEmergencyAdmin);
        strategy.shutdownStrategy();
        assertTrue(strategy.isShutdown());
        assertTrue(strategy.isPaused());
    }

    function test_emergencyWithdrawNotPausedOrShutdownReverts() public {
        vm.prank(management);
        vm.expectRevert("not paused or shutdown");
        strategy.emergencyWithdraw(0);
    }

    function _permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint256 ownerSk
    ) internal {
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                strategy.nonces(owner),
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                strategy.DOMAIN_SEPARATOR(),
                structHash
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerSk, digest);

        strategy.permit(owner, spender, amount, deadline, v, r, s);
    }
}
