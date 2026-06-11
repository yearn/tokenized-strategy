// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18;

import {MockYieldSource} from "./MockYieldSource.sol";
import {BaseStrategy, ERC20, TokenizedStrategy} from "../../BaseStrategy.sol";

contract MockStrategy is BaseStrategy {
    address public yieldSource;
    bool public trigger;
    bool public managed;
    bool public kept;
    bool public emergentizated;
    bool public callBaseGuardDuringDeploy;
    bool public lastDeployFundsIsEntered;
    bool public lastBaseGuardIsEntered;

    constructor(
        address _asset,
        address _yieldSource
    ) BaseStrategy(_asset, "Test Strategy") {
        initialize(_asset, _yieldSource);
    }

    function initialize(address _asset, address _yieldSource) public {
        require(yieldSource == address(0));
        yieldSource = _yieldSource;
        ERC20(_asset).approve(_yieldSource, type(uint256).max);
    }

    function _deployFunds(uint256 _amount) internal override {
        lastDeployFundsIsEntered = TokenizedStrategy.isEntered();
        if (callBaseGuardDuringDeploy) {
            this.useBaseReentrancyGuard();
        }
        MockYieldSource(yieldSource).deposit(_amount);
    }

    function _freeFunds(uint256 _amount) internal override {
        MockYieldSource(yieldSource).withdraw(_amount);
    }

    function _strategyTotalAssets() internal view override returns (uint256) {
        return
            MockYieldSource(yieldSource).balance() +
            ERC20(asset).balanceOf(address(this));
    }

    function _harvestAndReport() internal override returns (uint256) {
        MockYieldSource(yieldSource).harvest();
        uint256 balance = ERC20(asset).balanceOf(address(this));
        if (balance > 0 && !TokenizedStrategy.isShutdown()) {
            MockYieldSource(yieldSource).deposit(balance);
        }
        return _strategyTotalAssets();
    }

    function _tend(uint256 /*_idle*/) internal override {
        uint256 balance = ERC20(asset).balanceOf(address(this));
        if (balance > 0) {
            MockYieldSource(yieldSource).deposit(balance);
        }
    }

    function _emergencyWithdraw(uint256 _amount) internal override {
        MockYieldSource(yieldSource).withdraw(_amount);
    }

    function _tendTrigger() internal view override returns (bool) {
        return trigger;
    }

    function setTrigger(bool _trigger) external {
        trigger = _trigger;
    }

    function onlyLetManagers() public onlyManagement {
        managed = true;
    }

    function onlyLetKeepersIn() public onlyKeepers {
        kept = true;
    }

    function onlyLetEmergencyAdminsIn() public onlyEmergencyAuthorized {
        emergentizated = true;
    }

    function setCallBaseGuardDuringDeploy(bool _call) external {
        callBaseGuardDuringDeploy = _call;
    }

    function useBaseReentrancyGuard() external strategyNonReentrant {
        lastBaseGuardIsEntered = TokenizedStrategy.isEntered();
    }

    function libraryAsset() external view returns (address) {
        return TokenizedStrategy.asset();
    }

    function libraryName() external view returns (string memory) {
        return TokenizedStrategy.name();
    }

    function librarySymbol() external view returns (string memory) {
        return TokenizedStrategy.symbol();
    }

    function libraryDecimals() external view returns (uint8) {
        return TokenizedStrategy.decimals();
    }

    function libraryApiVersion() external view returns (string memory) {
        return TokenizedStrategy.apiVersion();
    }

    function libraryMAX_FEE() external view returns (uint16) {
        return TokenizedStrategy.MAX_FEE();
    }

    function libraryFACTORY() external view returns (address) {
        return TokenizedStrategy.FACTORY();
    }

    function libraryManagement() external view returns (address) {
        return TokenizedStrategy.management();
    }

    function libraryPendingManagement() external view returns (address) {
        return TokenizedStrategy.pendingManagement();
    }

    function libraryKeeper() external view returns (address) {
        return TokenizedStrategy.keeper();
    }

    function libraryEmergencyAdmin() external view returns (address) {
        return TokenizedStrategy.emergencyAdmin();
    }

    function libraryPerformanceFee() external view returns (uint16) {
        return TokenizedStrategy.performanceFee();
    }

    function libraryPerformanceFeeRecipient() external view returns (address) {
        return TokenizedStrategy.performanceFeeRecipient();
    }

    function libraryProfitMaxUnlockTime() external view returns (uint256) {
        return TokenizedStrategy.profitMaxUnlockTime();
    }

    function libraryLastReport() external view returns (uint256) {
        return TokenizedStrategy.lastReport();
    }

    function libraryLastAccrual() external view returns (uint256) {
        return TokenizedStrategy.lastAccrual();
    }

    function libraryLastTotalAssets() external view returns (uint256) {
        return TokenizedStrategy.lastTotalAssets();
    }

    function libraryFullProfitUnlockDate() external view returns (uint256) {
        return TokenizedStrategy.fullProfitUnlockDate();
    }

    function libraryProfitUnlockingRate() external view returns (uint256) {
        return TokenizedStrategy.profitUnlockingRate();
    }

    function libraryIsShutdown() external view returns (bool) {
        return TokenizedStrategy.isShutdown();
    }

    function libraryIsPaused() external view returns (bool) {
        return TokenizedStrategy.isPaused();
    }

    function libraryIsEntered() external view returns (bool) {
        return TokenizedStrategy.isEntered();
    }

    function libraryTotalAssets() external view returns (uint256) {
        return TokenizedStrategy.totalAssets();
    }

    function libraryTotalSupply() external view returns (uint256) {
        return TokenizedStrategy.totalSupply();
    }

    function libraryBalanceOf(
        address _account
    ) external view returns (uint256) {
        return TokenizedStrategy.balanceOf(_account);
    }

    function libraryAllowance(
        address _owner,
        address _spender
    ) external view returns (uint256) {
        return TokenizedStrategy.allowance(_owner, _spender);
    }

    function libraryNonces(address _owner) external view returns (uint256) {
        return TokenizedStrategy.nonces(_owner);
    }

    function libraryDOMAIN_SEPARATOR() external view returns (bytes32) {
        return TokenizedStrategy.DOMAIN_SEPARATOR();
    }

    function libraryUnlockedShares() external view returns (uint256) {
        return TokenizedStrategy.unlockedShares();
    }

    function libraryPricePerShare() external view returns (uint256) {
        return TokenizedStrategy.pricePerShare();
    }

    function libraryConvertToShares(
        uint256 _assets
    ) external view returns (uint256) {
        return TokenizedStrategy.convertToShares(_assets);
    }

    function libraryConvertToAssets(
        uint256 _shares
    ) external view returns (uint256) {
        return TokenizedStrategy.convertToAssets(_shares);
    }

    function libraryPreviewDeposit(
        uint256 _assets
    ) external view returns (uint256) {
        return TokenizedStrategy.previewDeposit(_assets);
    }

    function libraryPreviewMint(
        uint256 _shares
    ) external view returns (uint256) {
        return TokenizedStrategy.previewMint(_shares);
    }

    function libraryPreviewWithdraw(
        uint256 _assets
    ) external view returns (uint256) {
        return TokenizedStrategy.previewWithdraw(_assets);
    }

    function libraryPreviewRedeem(
        uint256 _shares
    ) external view returns (uint256) {
        return TokenizedStrategy.previewRedeem(_shares);
    }

    function libraryMaxDeposit(
        address _receiver
    ) external view returns (uint256) {
        return TokenizedStrategy.maxDeposit(_receiver);
    }

    function libraryMaxMint(address _receiver) external view returns (uint256) {
        return TokenizedStrategy.maxMint(_receiver);
    }

    function libraryMaxWithdraw(
        address _owner
    ) external view returns (uint256) {
        return TokenizedStrategy.maxWithdraw(_owner);
    }

    function libraryMaxWithdraw(
        address _owner,
        uint256 _maxLoss
    ) external view returns (uint256) {
        return TokenizedStrategy.maxWithdraw(_owner, _maxLoss);
    }

    function libraryMaxRedeem(address _owner) external view returns (uint256) {
        return TokenizedStrategy.maxRedeem(_owner);
    }

    function libraryMaxRedeem(
        address _owner,
        uint256 _maxLoss
    ) external view returns (uint256) {
        return TokenizedStrategy.maxRedeem(_owner, _maxLoss);
    }

    function libraryRequireManagement(address _sender) external view {
        TokenizedStrategy.requireManagement(_sender);
    }

    function libraryRequireKeeperOrManagement(address _sender) external view {
        TokenizedStrategy.requireKeeperOrManagement(_sender);
    }

    function libraryRequireEmergencyAuthorized(address _sender) external view {
        TokenizedStrategy.requireEmergencyAuthorized(_sender);
    }
}
