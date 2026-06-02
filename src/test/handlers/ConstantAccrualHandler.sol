// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import "forge-std/console.sol";
import {ExtendedTest} from "../utils/ExtendedTest.sol";
import {Setup, IMockStrategy, ERC20Mock} from "../utils/Setup.sol";
import {LibAddressSet, AddressSet} from "../utils/LibAddressSet.sol";
import {MockYieldSource} from "../mocks/MockYieldSource.sol";

contract ConstantAccrualHandler is ExtendedTest {
    using LibAddressSet for AddressSet;

    address internal constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    Setup public setup;
    IMockStrategy public strategy;
    ERC20Mock public asset;
    MockYieldSource public yieldSource;

    uint256 public maxFuzzAmount = 1e30;
    uint256 public minFuzzAmount = 10_000;
    uint256 public MAX_BPS = 10_000;

    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;
    uint256 public ghost_liveProfitSum;
    uint256 public ghost_liveLossSum;
    uint256 public ghost_reportProfitSum;
    uint256 public ghost_reportLossSum;
    uint256 public ghost_pendingQueuedProfit;
    uint256 public ghost_pendingQueuedLoss;

    uint256 public liveProfitReportProfit;
    uint256 public liveProfitReportLoss;
    uint256 public liveLossReportProfit;
    uint256 public liveLossReportLoss;
    uint256 public noopReports;
    uint256 public tendNeutralChecks;
    uint256 public sameBlockIdempotentChecks;
    uint256 public activeUnlockLossBurns;
    uint256 public liveProfitNoBufferChecks;
    uint256 public queuedDeltaReportChecks;
    uint256 public zeroUnlockTimeChecks;
    uint256 public accountingViolations;

    bool public pendingLiveProfit;
    bool public pendingLiveLoss;
    bool public pendingLiveProfitNoBuffer;

    mapping(bytes32 => uint256) public calls;

    AddressSet internal _actors;
    address internal actor;

    modifier createActor() {
        actor = msg.sender;
        _actors.add(msg.sender);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        _ensureActor();
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
        yieldSource = MockYieldSource(strategy.yieldSource());
        skip(10);
    }

    function deposit(uint256 amount) public createActor countCall("deposit") {
        amount = bound(amount, minFuzzAmount, maxFuzzAmount);
        if (strategy.previewDeposit(amount) == 0) return;

        uint256 lastAccrualBefore = strategy.lastAccrual();
        bool hadPendingLiveProfitNoBuffer = pendingLiveProfitNoBuffer;

        _depositFor(actor, amount);
        _afterAccrualSync(lastAccrualBefore, hadPendingLiveProfitNoBuffer);

        ghost_depositSum += amount;
    }

    function mint(uint256 shares) public createActor countCall("mint") {
        shares = bound(shares, minFuzzAmount, maxFuzzAmount);

        uint256 assets = strategy.previewMint(shares);
        if (assets == 0) return;

        uint256 lastAccrualBefore = strategy.lastAccrual();
        bool hadPendingLiveProfitNoBuffer = pendingLiveProfitNoBuffer;

        asset.mint(actor, assets);

        vm.prank(actor);
        asset.approve(address(strategy), assets);

        vm.prank(actor);
        uint256 deposited = strategy.mint(shares, actor);
        _afterAccrualSync(lastAccrualBefore, hadPendingLiveProfitNoBuffer);

        ghost_depositSum += deposited;
    }

    function withdraw(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("withdraw") {
        uint256 maxWithdraw = strategy.maxWithdraw(actor);
        if (maxWithdraw == 0) return;

        amount = bound(amount, 0, maxWithdraw);
        if (amount == 0) return;

        uint256 lastAccrualBefore = strategy.lastAccrual();
        bool hadPendingLiveProfitNoBuffer = pendingLiveProfitNoBuffer;

        vm.prank(actor);
        strategy.withdraw(amount, actor, actor, MAX_BPS);
        _afterAccrualSync(lastAccrualBefore, hadPendingLiveProfitNoBuffer);

        ghost_withdrawSum += amount;
    }

    function redeem(uint256 actorSeed, uint256 shares) public useActor(actorSeed) countCall("redeem") {
        uint256 maxRedeem = strategy.maxRedeem(actor);
        if (maxRedeem == 0) return;

        shares = bound(shares, 0, maxRedeem);
        if (shares == 0) return;
        if (strategy.previewRedeem(shares) == 0) return;

        uint256 lastAccrualBefore = strategy.lastAccrual();
        bool hadPendingLiveProfitNoBuffer = pendingLiveProfitNoBuffer;

        vm.prank(actor);
        uint256 assets = strategy.redeem(shares, actor, actor, MAX_BPS);
        _afterAccrualSync(lastAccrualBefore, hadPendingLiveProfitNoBuffer);

        ghost_withdrawSum += assets;
    }

    function liveProfit(uint256 amount) public countCall("liveProfit") {
        _ensureActor();
        uint256 rawBufferBefore = rawStrategyBuffer();
        amount = _boundDelta(amount);

        asset.mint(address(yieldSource), amount);

        ghost_liveProfitSum += amount;
        pendingLiveProfit = true;

        if (rawBufferBefore == 0) {
            pendingLiveProfitNoBuffer = true;
        }
    }

    function liveLoss(uint256 amount) public countCall("liveLoss") {
        _ensureActor();
        uint256 available = yieldSource.balance();
        if (available <= ghost_pendingQueuedLoss) return;
        available -= ghost_pendingQueuedLoss;
        if (available == 0) return;

        amount = bound(amount, 1, available / 2 == 0 ? 1 : available / 2);
        uint256 rawBufferBefore = rawStrategyBuffer();

        yieldSource.simulateLoss(amount);

        ghost_liveLossSum += amount;
        pendingLiveLoss = true;

        if (rawBufferBefore != 0 && strategy.fullProfitUnlockDate() > block.timestamp) {
            activeUnlockLossBurns++;
        }
    }

    function queueReportProfit(uint256 amount) public countCall("queueReportProfit") {
        _ensureActor();
        amount = _boundDelta(amount);

        asset.mint(address(yieldSource), amount);
        yieldSource.queueRewards(amount);

        ghost_pendingQueuedProfit += amount;
    }

    function queueReportLoss(uint256 amount) public countCall("queueReportLoss") {
        _ensureActor();
        uint256 available = yieldSource.balance();
        if (available <= ghost_pendingQueuedLoss) return;

        available -= ghost_pendingQueuedLoss;
        if (available == 0) return;

        amount = bound(amount, 1, available / 2 == 0 ? 1 : available / 2);
        yieldSource.queueLoss(amount);

        ghost_pendingQueuedLoss += amount;
    }

    function report() public countCall("report") {
        bool hadLiveProfit = pendingLiveProfit;
        bool hadLiveLoss = pendingLiveLoss;
        bool hadPendingLiveProfitNoBuffer = pendingLiveProfitNoBuffer;
        bool accrualCanRun = strategy.lastAccrual() != block.timestamp;
        uint256 expectedProfit;
        uint256 expectedLoss;

        if (ghost_pendingQueuedProfit > ghost_pendingQueuedLoss) {
            expectedProfit = ghost_pendingQueuedProfit - ghost_pendingQueuedLoss;
        } else {
            expectedLoss = ghost_pendingQueuedLoss - ghost_pendingQueuedProfit;
        }

        vm.prank(setup.keeper());
        (uint256 profit, uint256 loss) = strategy.report();

        ghost_reportProfitSum += profit;
        ghost_reportLossSum += loss;

        if (accrualCanRun) {
            if (profit != expectedProfit || loss != expectedLoss) {
                accountingViolations++;
            } else {
                queuedDeltaReportChecks++;
            }
        }

        if (accrualCanRun && hadPendingLiveProfitNoBuffer && expectedProfit == 0) {
            if (rawStrategyBuffer() != 0) {
                accountingViolations++;
            } else {
                liveProfitNoBufferChecks++;
            }
        }

        if (hadLiveProfit && profit != 0) liveProfitReportProfit++;
        if (hadLiveProfit && loss != 0) liveProfitReportLoss++;
        if (hadLiveLoss && profit != 0) liveLossReportProfit++;
        if (hadLiveLoss && loss != 0) liveLossReportLoss++;
        if (!hadLiveProfit && !hadLiveLoss && expectedProfit == 0 && expectedLoss == 0 && profit == 0 && loss == 0) {
            noopReports++;
        }

        ghost_pendingQueuedProfit = 0;
        ghost_pendingQueuedLoss = 0;
        pendingLiveProfit = false;
        pendingLiveLoss = false;
        pendingLiveProfitNoBuffer = false;
    }

    function reportWithQueuedProfit(uint256 amount) public countCall("reportWithQueuedProfit") {
        queueReportProfit(amount);
        report();
    }

    function reportWithQueuedLoss(uint256 amount) public countCall("reportWithQueuedLoss") {
        queueReportLoss(amount);
        report();
    }

    function syncViaManagementSetter() public countCall("syncViaManagement") {
        uint256 lastAccrualBefore = strategy.lastAccrual();
        bool hadPendingLiveProfitNoBuffer = pendingLiveProfitNoBuffer;
        address feeRecipient = setup.performanceFeeRecipient();

        vm.prank(setup.management());
        strategy.setPerformanceFeeRecipient(feeRecipient);

        _afterAccrualSync(lastAccrualBefore, hadPendingLiveProfitNoBuffer);
    }

    function sameBlockDoubleAccrual(uint256 amount) public countCall("sameBlockDoubleAccrual") {
        _ensureActor();
        skip(1);

        amount = _boundDelta(amount);
        asset.mint(address(yieldSource), amount);
        pendingLiveProfit = true;
        if (rawStrategyBuffer() == 0) pendingLiveProfitNoBuffer = true;

        syncViaManagementSetter();

        uint256 lastTotalAssetsAfterFirstSync = strategy.lastTotalAssets();
        uint256 totalAssetsAfterFirstSync = strategy.totalAssets();

        asset.mint(address(yieldSource), amount);
        pendingLiveProfit = true;
        if (rawStrategyBuffer() == 0) pendingLiveProfitNoBuffer = true;

        syncViaManagementSetter();

        if (
            strategy.lastAccrual() != block.timestamp || strategy.lastTotalAssets() != lastTotalAssetsAfterFirstSync
                || strategy.totalAssets() != totalAssetsAfterFirstSync
        ) {
            accountingViolations++;
        } else {
            sameBlockIdempotentChecks++;
        }
    }

    function tendNeutral(uint256 amount) public countCall("tendNeutral") {
        _ensureActor();
        amount = _boundDelta(amount);

        asset.mint(address(strategy), amount);

        uint256 lastTotalAssetsBefore = strategy.lastTotalAssets();
        uint256 lastAccrualBefore = strategy.lastAccrual();
        uint256 supplyBefore = strategy.totalSupply();
        uint256 ppsBefore = strategy.pricePerShare();

        vm.prank(setup.keeper());
        strategy.tend();

        if (
            strategy.lastTotalAssets() != lastTotalAssetsBefore || strategy.lastAccrual() != lastAccrualBefore
                || strategy.totalSupply() != supplyBefore || strategy.pricePerShare() != ppsBefore
        ) {
            accountingViolations++;
        } else {
            tendNeutralChecks++;
        }
    }

    function skipSmall(uint256 time) public countCall("skipSmall") {
        time = bound(time, 1, 1 days);
        skip(time);
    }

    function skipToHalfUnlock() public countCall("skipHalf") {
        skip(setup.profitMaxUnlockTime() / 2);
    }

    function skipPastUnlock() public countCall("skipPastUnlock") {
        skip(setup.profitMaxUnlockTime() + 1);
    }

    function setFees(uint16 protocolFee, uint16 performanceFee) public countCall("setFees") {
        protocolFee = uint16(bound(uint256(protocolFee), 0, 1_000));
        performanceFee = uint16(bound(uint256(performanceFee), 0, 2_000));

        uint256 lastAccrualBefore = strategy.lastAccrual();
        bool hadPendingLiveProfitNoBuffer = pendingLiveProfitNoBuffer;

        setup.mockFactory().setFee(protocolFee);

        vm.prank(setup.management());
        strategy.setPerformanceFee(performanceFee);

        _afterAccrualSync(lastAccrualBefore, hadPendingLiveProfitNoBuffer);
    }

    function setProfitMaxUnlockTime(uint32 unlockTime) public countCall("setProfitMaxUnlockTime") {
        uint256 bounded = unlockTime % 5 == 0 ? 0 : bound(uint256(unlockTime), 1, 31_556_952);
        uint256 lastAccrualBefore = strategy.lastAccrual();
        bool hadPendingLiveProfitNoBuffer = pendingLiveProfitNoBuffer;

        vm.prank(setup.management());
        strategy.setProfitMaxUnlockTime(bounded);

        if (bounded == 0) zeroUnlockTimeChecks++;

        _afterAccrualSync(lastAccrualBefore, hadPendingLiveProfitNoBuffer);
    }

    function actualAssets() public view returns (uint256) {
        return yieldSource.balance() + asset.balanceOf(address(strategy));
    }

    function rawStrategyBuffer() public view returns (uint256) {
        return strategy.balanceOf(address(strategy)) + strategy.unlockedShares();
    }

    function trackedSupply() public view returns (uint256 supply) {
        address[] memory actors = _actors.addresses();
        for (uint256 i; i < actors.length; ++i) {
            supply += strategy.balanceOf(actors[i]);
        }

        supply += strategy.balanceOf(setup.protocolFeeRecipient());
        supply += strategy.balanceOf(setup.performanceFeeRecipient());
        supply += strategy.balanceOf(DEAD_ADDRESS);
        supply += strategy.balanceOf(address(strategy));
    }

    function actorCount() public view returns (uint256) {
        return _actors.count();
    }

    function callSummary() external view {
        console.log("Constant accrual call summary:");
        console.log("-------------------");
        console.log("deposit", calls["deposit"]);
        console.log("mint", calls["mint"]);
        console.log("withdraw", calls["withdraw"]);
        console.log("redeem", calls["redeem"]);
        console.log("live profit", calls["liveProfit"]);
        console.log("live loss", calls["liveLoss"]);
        console.log("queue report profit", calls["queueReportProfit"]);
        console.log("queue report loss", calls["queueReportLoss"]);
        console.log("report", calls["report"]);
        console.log("report queued profit", calls["reportWithQueuedProfit"]);
        console.log("report queued loss", calls["reportWithQueuedLoss"]);
        console.log("sync management", calls["syncViaManagement"]);
        console.log("same block accrual", calls["sameBlockDoubleAccrual"]);
        console.log("set unlock time", calls["setProfitMaxUnlockTime"]);
        console.log("tend neutral", calls["tendNeutral"]);
        console.log("-------------------");
        console.log("live profit + report profit", liveProfitReportProfit);
        console.log("live profit + report loss", liveProfitReportLoss);
        console.log("live loss + report profit", liveLossReportProfit);
        console.log("live loss + report loss", liveLossReportLoss);
        console.log("noop reports", noopReports);
        console.log("same block idempotent", sameBlockIdempotentChecks);
        console.log("tend neutral checks", tendNeutralChecks);
        console.log("live profit no buffer", liveProfitNoBufferChecks);
        console.log("queued delta report checks", queuedDeltaReportChecks);
        console.log("zero unlock time checks", zeroUnlockTimeChecks);
        console.log("active unlock loss burns", activeUnlockLossBurns);
        console.log("accounting violations", accountingViolations);
    }

    function _afterAccrualSync(uint256 lastAccrualBefore, bool hadPendingLiveProfitNoBuffer) internal {
        if (lastAccrualBefore == block.timestamp) return;

        if (hadPendingLiveProfitNoBuffer) {
            if (rawStrategyBuffer() != 0) {
                accountingViolations++;
            } else {
                liveProfitNoBufferChecks++;
            }
            pendingLiveProfitNoBuffer = false;
        }

        pendingLiveProfit = false;
        pendingLiveLoss = false;
    }

    function _ensureActor() internal {
        if (_actors.count() != 0) return;

        actor = address(0xA11CE);
        _actors.add(actor);
        _depositFor(actor, minFuzzAmount * 100);
        ghost_depositSum += minFuzzAmount * 100;
    }

    function _depositFor(address receiver, uint256 amount) internal {
        if (strategy.previewDeposit(amount) == 0) return;

        asset.mint(receiver, amount);

        vm.prank(receiver);
        asset.approve(address(strategy), amount);

        vm.prank(receiver);
        strategy.deposit(amount, receiver);
    }

    function _boundDelta(uint256 amount) internal view returns (uint256) {
        uint256 base = strategy.totalAssets();
        uint256 upper = base == 0 ? minFuzzAmount * 100 : base / 2;
        if (upper < minFuzzAmount) upper = minFuzzAmount;
        if (upper > maxFuzzAmount) upper = maxFuzzAmount;
        return bound(amount, minFuzzAmount, upper);
    }
}
