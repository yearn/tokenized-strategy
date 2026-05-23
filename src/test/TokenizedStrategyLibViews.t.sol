// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import {Setup} from "./utils/Setup.sol";
import {MockStrategy} from "./mocks/MockStrategy.sol";

contract TokenizedStrategyLibViewsTest is Setup {
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    MockStrategy internal libraryStrategy;

    function setUp() public override {
        super.setUp();
        libraryStrategy = MockStrategy(address(strategy));
    }

    function test_tokenizedStrategyLibraryViewsMatchDirectCalls() public {
        uint256 ownerSk = 0xA11CE;
        address owner = vm.addr(ownerSk);
        address spender = address(0xBEEF);
        address pendingManagement = address(0xCAFE);
        address newKeeper = address(0xD00D);
        address newEmergencyAdmin = address(0xEAA);
        address newPerformanceFeeRecipient = address(0xFEE);
        uint256 amount = 100_000 * wad;

        _assertAllViewsMatch(owner, spender, amount / 10, amount / 20, 77);

        setFees(0, 1_250);
        mintAndDepositIntoStrategy(strategy, owner, amount);

        vm.prank(owner);
        strategy.approve(spender, amount / 3);

        _permit(owner, spender, amount / 7, 1 days, ownerSk);

        vm.prank(management);
        strategy.setPendingManagement(pendingManagement);

        vm.prank(management);
        strategy.setPerformanceFeeRecipient(newPerformanceFeeRecipient);

        vm.prank(management);
        strategy.setProfitMaxUnlockTime(14 days);

        skip(1);
        createAndCheckProfit(strategy, amount / 5, 0, amount / 40);

        vm.prank(management);
        strategy.setKeeper(newKeeper);

        vm.prank(management);
        strategy.setEmergencyAdmin(newEmergencyAdmin);

        skip(3 days);
        _assertAllViewsMatch(owner, spender, amount / 11, amount / 13, 123);
        _assertAccountViewsMatch(address(strategy), spender);
        _assertAccountViewsMatch(newPerformanceFeeRecipient, spender);

        vm.prank(newEmergencyAdmin);
        strategy.shutdownStrategy();

        _assertAllViewsMatch(owner, spender, amount / 17, amount / 19, MAX_BPS);
        _assertAuthHelpersMatch(newKeeper, newEmergencyAdmin);
    }

    function _assertAllViewsMatch(
        address owner,
        address spender,
        uint256 assets,
        uint256 shares,
        uint256 maxLoss
    ) internal {
        assertEq(libraryStrategy.libraryAsset(), strategy.asset(), "asset");
        assertEq(
            keccak256(bytes(libraryStrategy.libraryName())),
            keccak256(bytes(strategy.name())),
            "name"
        );
        assertEq(
            keccak256(bytes(libraryStrategy.librarySymbol())),
            keccak256(bytes(strategy.symbol())),
            "symbol"
        );
        assertEq(
            libraryStrategy.libraryDecimals(),
            strategy.decimals(),
            "decimals"
        );
        assertEq(
            keccak256(bytes(libraryStrategy.libraryApiVersion())),
            keccak256(bytes(strategy.apiVersion())),
            "apiVersion"
        );
        assertEq(
            libraryStrategy.libraryMAX_FEE(),
            strategy.MAX_FEE(),
            "MAX_FEE"
        );
        assertEq(
            libraryStrategy.libraryFACTORY(),
            strategy.FACTORY(),
            "FACTORY"
        );
        assertEq(
            libraryStrategy.libraryManagement(),
            strategy.management(),
            "management"
        );
        assertEq(
            libraryStrategy.libraryPendingManagement(),
            strategy.pendingManagement(),
            "pendingManagement"
        );
        assertEq(libraryStrategy.libraryKeeper(), strategy.keeper(), "keeper");
        assertEq(
            libraryStrategy.libraryEmergencyAdmin(),
            strategy.emergencyAdmin(),
            "emergencyAdmin"
        );
        assertEq(
            libraryStrategy.libraryPerformanceFee(),
            strategy.performanceFee(),
            "performanceFee"
        );
        assertEq(
            libraryStrategy.libraryPerformanceFeeRecipient(),
            strategy.performanceFeeRecipient(),
            "performanceFeeRecipient"
        );
        assertEq(
            libraryStrategy.libraryProfitMaxUnlockTime(),
            strategy.profitMaxUnlockTime(),
            "profitMaxUnlockTime"
        );
        assertEq(
            libraryStrategy.libraryLastReport(),
            strategy.lastReport(),
            "lastReport"
        );
        assertEq(
            libraryStrategy.libraryLastAccrual(),
            strategy.lastAccrual(),
            "lastAccrual"
        );
        assertEq(
            libraryStrategy.libraryLastTotalAssets(),
            strategy.lastTotalAssets(),
            "lastTotalAssets"
        );
        assertEq(
            libraryStrategy.libraryFullProfitUnlockDate(),
            strategy.fullProfitUnlockDate(),
            "fullProfitUnlockDate"
        );
        assertEq(
            libraryStrategy.libraryProfitUnlockingRate(),
            strategy.profitUnlockingRate(),
            "profitUnlockingRate"
        );
        assertEq(
            libraryStrategy.libraryIsShutdown(),
            strategy.isShutdown(),
            "isShutdown"
        );
        assertEq(
            libraryStrategy.libraryIsPaused(),
            strategy.isPaused(),
            "isPaused"
        );
        assertEq(
            libraryStrategy.libraryTotalAssets(),
            strategy.totalAssets(),
            "totalAssets"
        );
        assertEq(
            libraryStrategy.libraryTotalSupply(),
            strategy.totalSupply(),
            "totalSupply"
        );
        assertEq(
            libraryStrategy.libraryDOMAIN_SEPARATOR(),
            strategy.DOMAIN_SEPARATOR(),
            "DOMAIN_SEPARATOR"
        );
        assertEq(
            libraryStrategy.libraryUnlockedShares(),
            strategy.unlockedShares(),
            "unlockedShares"
        );
        assertEq(
            libraryStrategy.libraryPricePerShare(),
            strategy.pricePerShare(),
            "pricePerShare"
        );
        assertEq(
            libraryStrategy.libraryConvertToShares(assets),
            strategy.convertToShares(assets),
            "convertToShares"
        );
        assertEq(
            libraryStrategy.libraryConvertToAssets(shares),
            strategy.convertToAssets(shares),
            "convertToAssets"
        );
        assertEq(
            libraryStrategy.libraryPreviewDeposit(assets),
            strategy.previewDeposit(assets),
            "previewDeposit"
        );
        assertEq(
            libraryStrategy.libraryPreviewMint(shares),
            strategy.previewMint(shares),
            "previewMint"
        );
        assertEq(
            libraryStrategy.libraryPreviewWithdraw(assets),
            strategy.previewWithdraw(assets),
            "previewWithdraw"
        );
        assertEq(
            libraryStrategy.libraryPreviewRedeem(shares),
            strategy.previewRedeem(shares),
            "previewRedeem"
        );
        assertEq(
            libraryStrategy.libraryMaxDeposit(owner),
            strategy.maxDeposit(owner),
            "maxDeposit"
        );
        assertEq(
            libraryStrategy.libraryMaxMint(owner),
            strategy.maxMint(owner),
            "maxMint"
        );
        assertEq(
            libraryStrategy.libraryMaxWithdraw(owner),
            strategy.maxWithdraw(owner),
            "maxWithdraw"
        );
        assertEq(
            libraryStrategy.libraryMaxWithdraw(owner, maxLoss),
            strategy.maxWithdraw(owner, maxLoss),
            "maxWithdraw maxLoss"
        );
        assertEq(
            libraryStrategy.libraryMaxRedeem(owner),
            strategy.maxRedeem(owner),
            "maxRedeem"
        );
        assertEq(
            libraryStrategy.libraryMaxRedeem(owner, maxLoss),
            strategy.maxRedeem(owner, maxLoss),
            "maxRedeem maxLoss"
        );

        _assertAccountViewsMatch(owner, spender);
    }

    function _assertAccountViewsMatch(address owner, address spender) internal {
        assertEq(
            libraryStrategy.libraryBalanceOf(owner),
            strategy.balanceOf(owner),
            "balanceOf"
        );
        assertEq(
            libraryStrategy.libraryAllowance(owner, spender),
            strategy.allowance(owner, spender),
            "allowance"
        );
        assertEq(
            libraryStrategy.libraryNonces(owner),
            strategy.nonces(owner),
            "nonces"
        );
    }

    function _assertAuthHelpersMatch(
        address currentKeeper,
        address currentEmergencyAdmin
    ) internal {
        strategy.requireManagement(management);
        libraryStrategy.libraryRequireManagement(management);

        strategy.requireKeeperOrManagement(management);
        strategy.requireKeeperOrManagement(currentKeeper);
        libraryStrategy.libraryRequireKeeperOrManagement(management);
        libraryStrategy.libraryRequireKeeperOrManagement(currentKeeper);

        strategy.requireEmergencyAuthorized(management);
        strategy.requireEmergencyAuthorized(currentEmergencyAdmin);
        libraryStrategy.libraryRequireEmergencyAuthorized(management);
        libraryStrategy.libraryRequireEmergencyAuthorized(
            currentEmergencyAdmin
        );

        vm.expectRevert("!management");
        strategy.requireManagement(address(0xBAD));
        vm.expectRevert("!management");
        libraryStrategy.libraryRequireManagement(address(0xBAD));

        vm.expectRevert("!keeper");
        strategy.requireKeeperOrManagement(address(0xBAD));
        vm.expectRevert("!keeper");
        libraryStrategy.libraryRequireKeeperOrManagement(address(0xBAD));

        vm.expectRevert("!emergency authorized");
        strategy.requireEmergencyAuthorized(address(0xBAD));
        vm.expectRevert("!emergency authorized");
        libraryStrategy.libraryRequireEmergencyAuthorized(address(0xBAD));
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
