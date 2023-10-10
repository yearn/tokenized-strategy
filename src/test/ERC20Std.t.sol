// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {Setup, MockStrategy, IMockStrategy} from "./utils/Setup.sol";

// Adapted from Maple finance's ERC20 standard testing package
// see: https://github.com/maple-labs/erc20/blob/main/contracts/test/ERC20.t.sol
contract ERC20BaseTest is Setup {
    address internal immutable self = address(this);

    bytes internal constant ARITHMETIC_ERROR =
        abi.encodeWithSignature("Panic(uint256)", 0x11);

    function setUp() public override {
        super.setUp();
    }

    function invariant_metadata() public {
        assertEq(strategy.name(), "Test Strategy");
        assertEq(
            strategy.symbol(),
            string(abi.encodePacked("ys", asset.symbol()))
        );
        assertEq(strategy.decimals(), 18);
    }

    function testFuzz_mint(address account_, uint256 amount_) public {
        vm.assume(account_ != address(0) && account_ != address(strategy));
        amount_ = bound(amount_, minFuzzAmount, maxFuzzAmount);

        vm.prank(address(strategy));
        mintAndDepositIntoStrategy(strategy, account_, amount_);

        assertEq(strategy.totalSupply(), amount_);
        assertEq(strategy.balanceOf(account_), amount_);
    }

    function testFuzz_burn(
        address account_,
        uint256 amount0_,
        uint256 amount1_
    ) public {
        vm.assume(account_ != address(0) && account_ != address(strategy));
        amount0_ = bound(amount0_, minFuzzAmount + 1, maxFuzzAmount);
        amount1_ = bound(amount1_, minFuzzAmount, amount0_);

        mintAndDepositIntoStrategy(strategy, account_, amount0_);
        vm.prank(account_);
        strategy.withdraw(amount1_, account_, account_);

        assertEq(strategy.totalSupply(), amount0_ - amount1_);
        assertEq(strategy.balanceOf(account_), amount0_ - amount1_);
    }

    function testFuzz_approve(address account_, uint256 amount_) public {
        vm.assume(account_ != address(0) && account_ != address(strategy));
        amount_ = bound(amount_, minFuzzAmount, maxFuzzAmount);

        assertTrue(strategy.approve(account_, amount_));

        assertEq(strategy.allowance(self, account_), amount_);
    }

    function testFuzz_increaseAllowance(
        address account_,
        uint256 initialAmount_,
        uint256 addedAmount_
    ) public {
        vm.assume(account_ != address(0) && account_ != address(strategy));
        initialAmount_ = bound(initialAmount_, 0, type(uint256).max / 2);
        addedAmount_ = bound(addedAmount_, 0, type(uint256).max / 2);

        strategy.approve(account_, initialAmount_);

        assertEq(strategy.allowance(self, account_), initialAmount_);

        assertTrue(strategy.increaseAllowance(account_, addedAmount_));

        assertEq(
            strategy.allowance(self, account_),
            initialAmount_ + addedAmount_
        );
    }

    function testFuzz_increaseAllowance_overflows(
        address account_,
        uint256 initialAmount_,
        uint256 addedAmount_
    ) public {
        vm.assume(account_ != address(0) && account_ != address(strategy));
        initialAmount_ = bound(
            initialAmount_,
            type(uint256).max / 2 + 1,
            type(uint256).max
        );
        addedAmount_ = bound(
            addedAmount_,
            type(uint256).max / 2 + 1,
            type(uint256).max
        );

        strategy.approve(account_, initialAmount_);

        assertEq(strategy.allowance(self, account_), initialAmount_);

        vm.expectRevert(ARITHMETIC_ERROR);
        strategy.increaseAllowance(account_, addedAmount_);

        assertEq(strategy.allowance(self, account_), initialAmount_);
    }

    function testFuzz_decreaseAllowance_nonInfiniteApproval(
        address account_,
        uint256 initialAmount_,
        uint256 subtractedAmount_
    ) public {
        vm.assume(account_ != address(0) && account_ != address(strategy));
        initialAmount_ = bound(initialAmount_, 0, type(uint256).max - 1);
        subtractedAmount_ = bound(subtractedAmount_, 0, initialAmount_);

        strategy.approve(account_, initialAmount_);

        assertEq(strategy.allowance(self, account_), initialAmount_);

        assertTrue(strategy.decreaseAllowance(account_, subtractedAmount_));

        assertEq(
            strategy.allowance(self, account_),
            initialAmount_ - subtractedAmount_
        );
    }

    function testFuzz_decreaseAllowance_underFlows(
        address account_,
        uint256 initialAmount_,
        uint256 subtractedAmount_
    ) public {
        vm.assume(account_ != address(0) && account_ != address(strategy));
        initialAmount_ = bound(initialAmount_, 0, type(uint256).max - 1);
        subtractedAmount_ = bound(
            subtractedAmount_,
            initialAmount_ + 1,
            type(uint256).max
        );

        strategy.approve(account_, initialAmount_);

        assertEq(strategy.allowance(self, account_), initialAmount_);

        vm.expectRevert(ARITHMETIC_ERROR);
        strategy.decreaseAllowance(account_, subtractedAmount_);

        assertEq(strategy.allowance(self, account_), initialAmount_);
    }

    function testFuzz_transfer(address account_, uint256 amount_) public {
        vm.assume(account_ != address(0) && account_ != address(strategy));
        amount_ = bound(amount_, minFuzzAmount, maxFuzzAmount);

        mintAndDepositIntoStrategy(strategy, self, amount_);

        assertTrue(strategy.transfer(account_, amount_));

        assertEq(strategy.totalSupply(), amount_);

        if (self == account_) {
            assertEq(strategy.balanceOf(self), amount_);
        } else {
            assertEq(strategy.balanceOf(self), 0);
            assertEq(strategy.balanceOf(account_), amount_);
        }
    }

    function testFuzz_transferFrom(
        address recipient_,
        uint256 approval_,
        uint256 amount_
    ) public {
        vm.assume(recipient_ != address(0) && recipient_ != address(strategy));

        amount_ = bound(amount_, minFuzzAmount, maxFuzzAmount);
        approval_ = bound(approval_, amount_, type(uint256).max - 1);

        ERC20User owner = new ERC20User();

        mintAndDepositIntoStrategy(strategy, address(owner), amount_);

        owner.erc20_approve(address(strategy), self, approval_);

        assertTrue(strategy.transferFrom(address(owner), recipient_, amount_));

        assertEq(strategy.totalSupply(), amount_);

        approval_ = address(owner) == self ? approval_ : approval_ - amount_;

        assertEq(strategy.allowance(address(owner), self), approval_);

        if (address(owner) == recipient_) {
            assertEq(strategy.balanceOf(address(owner)), amount_);
        } else {
            assertEq(strategy.balanceOf(address(owner)), 0);
            assertEq(strategy.balanceOf(recipient_), amount_);
        }
    }

    function testFuzz_transferFrom_infiniteApproval(
        address recipient_,
        uint256 amount_
    ) public {
        vm.assume(recipient_ != address(0) && recipient_ != address(strategy));
        uint256 MAX_UINT256 = type(uint256).max;

        amount_ = bound(amount_, minFuzzAmount, maxFuzzAmount);

        ERC20User owner = new ERC20User();

        mintAndDepositIntoStrategy(strategy, address(owner), amount_);
        owner.erc20_approve(address(strategy), self, MAX_UINT256);

        assertEq(strategy.balanceOf(address(owner)), amount_);
        assertEq(strategy.totalSupply(), amount_);
        assertEq(strategy.allowance(address(owner), self), MAX_UINT256);

        assertTrue(strategy.transferFrom(address(owner), recipient_, amount_));

        assertEq(strategy.totalSupply(), amount_);
        assertEq(strategy.allowance(address(owner), self), MAX_UINT256);

        if (address(owner) == recipient_) {
            assertEq(strategy.balanceOf(address(owner)), amount_);
        } else {
            assertEq(strategy.balanceOf(address(owner)), 0);
            assertEq(strategy.balanceOf(recipient_), amount_);
        }
    }

    function testFuzz_transfer_insufficientBalance(
        address recipient_,
        uint256 amount_
    ) public {
        vm.assume(recipient_ != address(0) && recipient_ != address(strategy));
        amount_ = bound(amount_, minFuzzAmount, maxFuzzAmount);

        ERC20User account = new ERC20User();

        mintAndDepositIntoStrategy(strategy, address(account), amount_ - 1);

        vm.expectRevert(ARITHMETIC_ERROR);
        account.erc20_transfer(address(strategy), recipient_, amount_);

        mintAndDepositIntoStrategy(strategy, address(account), 1);
        account.erc20_transfer(address(strategy), recipient_, amount_);

        assertEq(strategy.balanceOf(recipient_), amount_);
    }

    function testFuzz_transferFrom_insufficientAllowance(
        address recipient_,
        uint256 amount_
    ) public {
        vm.assume(recipient_ != address(0) && recipient_ != address(strategy));
        amount_ = bound(amount_, minFuzzAmount, maxFuzzAmount);

        ERC20User owner = new ERC20User();

        mintAndDepositIntoStrategy(strategy, address(owner), amount_);

        owner.erc20_approve(address(strategy), self, amount_ - 1);

        vm.expectRevert("ERC20: insufficient allowance");
        strategy.transferFrom(address(owner), recipient_, amount_);

        owner.erc20_approve(address(strategy), self, amount_);
        strategy.transferFrom(address(owner), recipient_, amount_);

        assertEq(strategy.balanceOf(recipient_), amount_);
    }

    function testFuzz_transferFrom_insufficientBalance(
        address recipient_,
        uint256 amount_
    ) public {
        vm.assume(recipient_ != address(0) && recipient_ != address(strategy));
        amount_ = bound(amount_, minFuzzAmount, maxFuzzAmount);

        ERC20User owner = new ERC20User();

        mintAndDepositIntoStrategy(strategy, address(owner), amount_ - 1);
        owner.erc20_approve(address(strategy), self, amount_);

        vm.expectRevert(ARITHMETIC_ERROR);
        strategy.transferFrom(address(owner), recipient_, amount_);

        mintAndDepositIntoStrategy(strategy, address(owner), 1);
        strategy.transferFrom(address(owner), recipient_, amount_);

        assertEq(strategy.balanceOf(recipient_), amount_);
    }
}

contract ERC20PermitTest is Setup {
    uint256 internal constant S_VALUE_INCLUSIVE_UPPER_BOUND =
        uint256(
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        );
    uint256 internal constant WAD = 10 ** 18;

    address internal _owner;
    address internal _spender;

    uint256 internal _skOwner = 1;
    uint256 internal _skSpender = 2;
    uint256 internal _nonce = 0;
    uint256 internal _deadline = 5_000_000_000; // Timestamp far in the future

    ERC20User internal _user;

    function setUp() public override {
        super.setUp();
        _owner = vm.addr(_skOwner);
        _spender = vm.addr(_skSpender);

        vm.warp(_deadline - 52 weeks);

        _user = new ERC20User();
    }

    function test_initialState() public {
        assertEq(strategy.nonces(_owner), 0);
        assertEq(strategy.allowance(_owner, _spender), 0);
    }

    function testFuzz_permit(uint256 amount_) public {
        uint256 startingNonce = strategy.nonces(_owner);
        uint256 expectedNonce = startingNonce + 1;

        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(strategy),
            _owner,
            _spender,
            amount_,
            startingNonce,
            _deadline,
            _skOwner
        );

        _user.erc20_permit(
            address(strategy),
            _owner,
            _spender,
            amount_,
            _deadline,
            v,
            r,
            s
        );

        assertEq(strategy.nonces(_owner), expectedNonce);
        assertEq(strategy.allowance(_owner, _spender), amount_);
    }

    function testFuzz_permit_multiple(bytes32 seed_) public {
        for (uint256 i; i < 10; ++i) {
            testFuzz_permit(uint256(keccak256(abi.encodePacked(seed_, i))));
        }
    }

    function test_permit_zeroAddress() public {
        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(strategy),
            _owner,
            _spender,
            1000,
            0,
            _deadline,
            _skOwner
        );

        vm.expectRevert("ERC20: INVALID_SIGNER");
        _user.erc20_permit(
            address(strategy),
            address(0),
            _spender,
            1000,
            _deadline,
            v,
            r,
            s
        );
    }

    function test_permit_differentSpender() public {
        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(strategy),
            _owner,
            address(1111),
            1000,
            0,
            _deadline,
            _skOwner
        );

        // Using permit with unintended spender should fail.
        vm.expectRevert("ERC20: INVALID_SIGNER");
        _user.erc20_permit(
            address(strategy),
            _owner,
            _spender,
            1000,
            _deadline,
            v,
            r,
            s
        );
    }

    function test_permit_ownerSignerMismatch() public {
        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(strategy),
            _owner,
            _spender,
            1000,
            0,
            _deadline,
            _skSpender
        );

        vm.expectRevert("ERC20: INVALID_SIGNER");
        _user.erc20_permit(
            address(strategy),
            _owner,
            _spender,
            1000,
            _deadline,
            v,
            r,
            s
        );
    }

    function test_permit_withExpiry() public {
        uint256 expiry = 482112000 + 1 hours;

        // Expired permit should fail
        vm.warp(482112000 + 1 hours + 1);

        assertEq(block.timestamp, 482112000 + 1 hours + 1);

        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(strategy),
            _owner,
            _spender,
            1000,
            0,
            expiry,
            _skOwner
        );

        vm.expectRevert("ERC20: PERMIT_DEADLINE_EXPIRED");
        _user.erc20_permit(
            address(strategy),
            _owner,
            _spender,
            1000,
            expiry,
            v,
            r,
            s
        );

        assertEq(strategy.allowance(_owner, _spender), 0);
        assertEq(strategy.nonces(_owner), 0);

        // Valid permit should succeed
        vm.warp(482112000 + 1 hours);

        assertEq(block.timestamp, 482112000 + 1 hours);

        (v, r, s) = _getValidPermitSignature(
            address(strategy),
            _owner,
            _spender,
            1000,
            0,
            expiry,
            _skOwner
        );

        _user.erc20_permit(
            address(strategy),
            _owner,
            _spender,
            1000,
            expiry,
            v,
            r,
            s
        );

        assertEq(strategy.allowance(_owner, _spender), 1000);
        assertEq(strategy.nonces(_owner), 1);
    }

    function test_permit_replay() public {
        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(strategy),
            _owner,
            _spender,
            1000,
            0,
            _deadline,
            _skOwner
        );

        // First time should succeed
        _user.erc20_permit(
            address(strategy),
            _owner,
            _spender,
            1000,
            _deadline,
            v,
            r,
            s
        );

        // Second time nonce has been consumed and should fail
        vm.expectRevert("ERC20: INVALID_SIGNER");
        _user.erc20_permit(
            address(strategy),
            _owner,
            _spender,
            1000,
            _deadline,
            v,
            r,
            s
        );
    }

    function test_permit_earlyNonce() public {
        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(strategy),
            _owner,
            _spender,
            1000,
            1,
            _deadline,
            _skOwner
        );

        // Previous nonce of 0 has not been consumed yet, so nonce of 1 should fail.
        vm.expectRevert("ERC20: INVALID_SIGNER");
        _user.erc20_permit(
            address(strategy),
            _owner,
            _spender,
            1000,
            _deadline,
            v,
            r,
            s
        );
    }

    function test_permit_differentVerifier() public {
        address someToken = setUpStrategy();

        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            someToken,
            _owner,
            _spender,
            1000,
            0,
            _deadline,
            _skOwner
        );

        // Using permit with unintended verifier should fail.
        vm.expectRevert("ERC20: INVALID_SIGNER");
        _user.erc20_permit(
            address(strategy),
            _owner,
            _spender,
            1000,
            _deadline,
            v,
            r,
            s
        );
    }

    function test_permit_badS() public {
        (uint8 v, bytes32 r, ) = _getValidPermitSignature(
            address(strategy),
            _owner,
            _spender,
            1000,
            0,
            _deadline,
            _skOwner
        );

        // Send in an s that is above the upper bound.
        bytes32 badS = bytes32(S_VALUE_INCLUSIVE_UPPER_BOUND + 1);
        vm.expectRevert("ERC20: INVALID_SIGNER");
        _user.erc20_permit(
            address(strategy),
            _owner,
            _spender,
            1000,
            _deadline,
            v,
            r,
            badS
        );
    }

    function test_permit_badV() public {
        // Get valid signature. The `v` value is the expected v value that will cause `permit` to succeed, and must be 27 or 28.
        // Any other value should fail.
        // If v is 27, then 28 should make it past the MALLEABLE require, but should result in an invalid signature,
        // and vice versa when v is 28.
        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(strategy),
            _owner,
            _spender,
            1000,
            0,
            _deadline,
            _skOwner
        );

        for (uint8 i; i <= type(uint8).max; i++) {
            if (i == type(uint8).max) {
                break;
            } else if (i != 27 && i != 28) {
                vm.expectRevert("ERC20: INVALID_SIGNER");
            } else {
                if (i == v) continue;

                // Should get past the Malleable require check as 27 or 28 are valid values for s.
                vm.expectRevert("ERC20: INVALID_SIGNER");
            }

            _user.erc20_permit(
                address(strategy),
                _owner,
                _spender,
                1000,
                _deadline,
                i,
                r,
                s
            );
        }
    }

    // Returns an ERC-2612 `permit` digest for the `owner` to sign
    function _getDigest(
        address token_,
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 nonce_,
        uint256 deadline_
    ) internal view returns (bytes32 digest_) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    IMockStrategy(token_).DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner_,
                            spender_,
                            amount_,
                            nonce_,
                            deadline_
                        )
                    )
                )
            );
    }

    // Returns a valid `permit` signature signed by this contract's `owner` address
    function _getValidPermitSignature(
        address token_,
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 nonce_,
        uint256 deadline_,
        uint256 ownerSk_
    ) internal view returns (uint8 v_, bytes32 r_, bytes32 s_) {
        return
            vm.sign(
                ownerSk_,
                _getDigest(token_, owner_, spender_, amount_, nonce_, deadline_)
            );
    }
}

contract ERC20User {
    function erc20_approve(
        address token_,
        address spender_,
        uint256 amount_
    ) external {
        IMockStrategy(token_).approve(spender_, amount_);
    }

    function erc20_permit(
        address token_,
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        IMockStrategy(token_).permit(
            owner_,
            spender_,
            amount_,
            deadline_,
            v_,
            r_,
            s_
        );
    }

    function erc20_transfer(
        address token_,
        address recipient_,
        uint256 amount_
    ) external returns (bool success_) {
        return IMockStrategy(token_).transfer(recipient_, amount_);
    }

    function erc20_transferFrom(
        address token_,
        address owner_,
        address recipient_,
        uint256 amount_
    ) external returns (bool success_) {
        return IMockStrategy(token_).transferFrom(owner_, recipient_, amount_);
    }
}
