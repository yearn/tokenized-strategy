// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "erc4626-tests/ERC4626.test.sol";

import {Setup} from "./utils/Setup.sol";

// SEE https://github.com/a16z/erc4626-tests
contract ERC4626StdTest is ERC4626Test, Setup {
    function setUp() public override(ERC4626Test, Setup) {
        super.setUp();
        setFees(0, 0);
        _underlying_ = address(asset);
        _vault_ = address(strategy);
        _delta_ = 0;
        _vaultMayBeEmpty = true;
        _unlimitedAmount = true;
    }

    //Avoid special case for deposits of uint256 max
    function test_previewDeposit(
        Init memory init,
        uint256 assets
    ) public override {
        if (assets == type(uint256).max) assets -= 1;
        super.test_previewDeposit(init, assets);
    }

    function test_deposit(
        Init memory init,
        uint256 assets,
        uint256 allowance
    ) public override {
        if (assets == type(uint256).max) assets -= 1;
        super.test_deposit(init, assets, allowance);
    }

    // The pinned ERC4626 test suite still uses legacy `testFail_*` names for
    // these cases. Newer Forge versions reject those, so we filter them out in
    // foundry.toml and keep the same coverage here with explicit expectRevert.
    function test_erc4626WithdrawWithoutAllowanceReverts(
        Init memory init,
        uint256 assets
    ) public {
        setUpVault(init);
        address caller = init.user[0];
        address receiver = init.user[1];
        address owner = init.user[2];
        assets = bound(assets, 0, _max_withdraw(owner));

        vm.assume(caller != owner);
        vm.assume(assets > 0);

        _approve(_vault_, owner, caller, 0);

        vm.expectRevert();
        vm.prank(caller);
        strategy.withdraw(assets, receiver, owner);
    }

    function test_erc4626RedeemWithoutAllowanceReverts(
        Init memory init,
        uint256 shares
    ) public {
        setUpVault(init);
        address caller = init.user[0];
        address receiver = init.user[1];
        address owner = init.user[2];
        shares = bound(shares, 0, _max_redeem(owner));

        vm.assume(caller != owner);
        vm.assume(shares > 0);

        _approve(_vault_, owner, caller, 0);

        vm.expectRevert();
        vm.prank(caller);
        strategy.redeem(shares, receiver, owner);
    }
}
