// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {ITokenizedStrategy} from "../interfaces/ITokenizedStrategy.sol";

library TokenizedStrategyLib {
    bytes32 internal constant BASE_STRATEGY_STORAGE =
        bytes32(uint256(keccak256("yearn.base.strategy.storage")) - 1);

    // prettier-ignore
    struct StrategyData {
        ERC20 asset;
        uint8 decimals;
        string name;
        uint256 totalSupply;
        mapping(address => uint256) nonces;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 lastTotalAssets;
        uint256 profitUnlockingRate;
        uint96 fullProfitUnlockDate;
        address keeper;
        uint32 profitMaxUnlockTime;
        uint16 performanceFee;
        address performanceFeeRecipient;
        uint96 lastReport;
        address management;
        address pendingManagement;
        address emergencyAdmin;
        uint8 entered;
        bool shutdown;
        uint96 lastAccrual;
    }

    function strategyStorage() internal pure returns (StrategyData storage S) {
        bytes32 slot = BASE_STRATEGY_STORAGE;
        assembly {
            S.slot := slot
        }
    }

    function asset() internal view returns (address) {
        return address(strategyStorage().asset);
    }

    function name() internal view returns (string memory) {
        return strategyStorage().name;
    }

    function symbol() internal view returns (string memory) {
        return ITokenizedStrategy(address(this)).symbol();
    }

    function decimals() internal view returns (uint8) {
        return strategyStorage().decimals;
    }

    function apiVersion() internal view returns (string memory) {
        return ITokenizedStrategy(address(this)).apiVersion();
    }

    function MAX_FEE() internal view returns (uint16) {
        return ITokenizedStrategy(address(this)).MAX_FEE();
    }

    function FACTORY() internal view returns (address) {
        return ITokenizedStrategy(address(this)).FACTORY();
    }

    function management() internal view returns (address) {
        return strategyStorage().management;
    }

    function pendingManagement() internal view returns (address) {
        return strategyStorage().pendingManagement;
    }

    function keeper() internal view returns (address) {
        return strategyStorage().keeper;
    }

    function emergencyAdmin() internal view returns (address) {
        return strategyStorage().emergencyAdmin;
    }

    function performanceFee() internal view returns (uint16) {
        return strategyStorage().performanceFee;
    }

    function performanceFeeRecipient() internal view returns (address) {
        return strategyStorage().performanceFeeRecipient;
    }

    function profitMaxUnlockTime() internal view returns (uint256) {
        uint256 _profitMaxUnlockTime = strategyStorage().profitMaxUnlockTime;
        if (_profitMaxUnlockTime == type(uint32).max) {
            return type(uint256).max;
        }

        return _profitMaxUnlockTime;
    }

    function lastReport() internal view returns (uint256) {
        return uint256(strategyStorage().lastReport);
    }

    function lastAccrual() internal view returns (uint256) {
        return uint256(strategyStorage().lastAccrual);
    }

    function lastTotalAssets() internal view returns (uint256) {
        return strategyStorage().lastTotalAssets;
    }

    function fullProfitUnlockDate() internal view returns (uint256) {
        return uint256(strategyStorage().fullProfitUnlockDate);
    }

    function profitUnlockingRate() internal view returns (uint256) {
        return strategyStorage().profitUnlockingRate;
    }

    function isShutdown() internal view returns (bool) {
        return strategyStorage().shutdown;
    }

    function totalAssets() internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).totalAssets();
    }

    function totalSupply() internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).totalSupply();
    }

    function balanceOf(address _account) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).balanceOf(_account);
    }

    function allowance(
        address _owner,
        address _spender
    ) internal view returns (uint256) {
        return strategyStorage().allowances[_owner][_spender];
    }

    function nonces(address _owner) internal view returns (uint256) {
        return strategyStorage().nonces[_owner];
    }

    function DOMAIN_SEPARATOR() internal view returns (bytes32) {
        return ITokenizedStrategy(address(this)).DOMAIN_SEPARATOR();
    }

    function unlockedShares() internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).unlockedShares();
    }

    function requireManagement(address _sender) internal view {
        require(_sender == strategyStorage().management, "!management");
    }

    function requireKeeperOrManagement(address _sender) internal view {
        StrategyData storage S = strategyStorage();
        require(_sender == S.keeper || _sender == S.management, "!keeper");
    }

    function requireEmergencyAuthorized(address _sender) internal view {
        StrategyData storage S = strategyStorage();
        require(
            _sender == S.emergencyAdmin || _sender == S.management,
            "!emergency authorized"
        );
    }

    function pricePerShare() internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).pricePerShare();
    }

    function convertToShares(uint256 _assets) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).convertToShares(_assets);
    }

    function convertToAssets(uint256 _shares) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).convertToAssets(_shares);
    }

    function previewDeposit(uint256 _assets) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).previewDeposit(_assets);
    }

    function previewMint(uint256 _shares) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).previewMint(_shares);
    }

    function previewWithdraw(uint256 _assets) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).previewWithdraw(_assets);
    }

    function previewRedeem(uint256 _shares) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).previewRedeem(_shares);
    }

    function maxDeposit(address _receiver) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).maxDeposit(_receiver);
    }

    function maxMint(address _receiver) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).maxMint(_receiver);
    }

    function maxWithdraw(address _owner) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).maxWithdraw(_owner);
    }

    function maxWithdraw(
        address _owner,
        uint256 _maxLoss
    ) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).maxWithdraw(_owner, _maxLoss);
    }

    function maxRedeem(address _owner) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).maxRedeem(_owner);
    }

    function maxRedeem(
        address _owner,
        uint256 _maxLoss
    ) internal view returns (uint256) {
        return ITokenizedStrategy(address(this)).maxRedeem(_owner, _maxLoss);
    }
}
