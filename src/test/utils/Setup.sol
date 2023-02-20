// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import "forge-std/console.sol";
import {ExtendedTest} from "./ExtendedTest.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {IStrategy} from "../Mocks/IStrategy.sol";
import {MockStrategy} from "../Mocks/MockStrategy.sol";

import {DiamondHelper} from "../../DiamondHelper.sol";
import {BaseLibrary} from "../../libraries/BaseLibrary.sol";

contract Setup is ExtendedTest {
    ERC20Mock public asset;
    IStrategy public strategy;

    DiamondHelper public diamondHelper;

    address public management = address(1);
    address public treasury = address(2);
    address public keeper = address(3);
    address public user = address(10);

    // we need to be able to divide by 10 twice and get non 0 number
    uint256 public minFuzzAmount = 100;
    uint256 public maxFuzzAmount = 1e30;
    // TODO: make these adjustable
    uint256 public decimals = 18;
    uint256 public wad = 1e18;
    uint256 public profitMaxUnlockTime = 10 days;
    uint256 public maxPPSPercentDelta = 100;

    function setUp() public virtual {
        // deploy the selector helper first to get a deterministic location
        bytes4[] memory selectors = getSelectors();
        diamondHelper = new DiamondHelper(selectors);

        diamondHelper.setLibrary(address(BaseLibrary));

        // create asset we will be using as the underlying asset
        asset = new ERC20Mock("Test asset", "tTKN", address(this), 0);
        // we save the mock base strategy as a IStrategy to give it the needed interface
        strategy = IStrategy(address(new MockStrategy(address(asset))));

        // set the slots for the baseLibrary to the correct address
        // store the libraries address at slot 0
        vm.store(
            address(strategy),
            bytes32(0),
            bytes32(uint256(uint160(address(BaseLibrary))))
        );

        // make sure our storage is set correctly
        assertEq(
            MockStrategy(payable(address(strategy))).baseLibrary(),
            address(BaseLibrary),
            "lib slot"
        );

        // set keeper
        strategy.setKeeper(keeper);
        // set treasury
        strategy.setTreasury(treasury);
        // set management of the strategy
        strategy.setManagement(management);

        // label all the used addresses for traces
        vm.label(management, "management");
        vm.label(keeper, "keeper");
        vm.label(treasury, "treasury");
        vm.label(address(asset), "asset");
        vm.label(address(strategy), "strategy");
        vm.label(address(BaseLibrary), "library");
        vm.label(address(diamondHelper), "selector heleper");
    }

    function mintAndDepositIntoStrategy(address _user, uint256 _amount) public {
        asset.mint(_user, _amount);

        vm.prank(_user);
        asset.approve(address(strategy), _amount);

        uint256 beforeBalance = asset.balanceOf(address(strategy));

        vm.prank(_user);
        strategy.deposit(_amount, _user);

        assertEq(asset.balanceOf(address(strategy)), beforeBalance + _amount);
    }

    function getSelectors() public pure returns (bytes4[] memory selectors) {
        string[21] memory _selectors = [
            "dd62ed3e",
            "095ea7b3",
            "70a08231",
            "07a2d13a",
            "c6e6f592",
            "a457c2d7",
            "6e553f65",
            "39509351",
            "534021b0",
            "94bf804d",
            "ef8b30f7",
            "b3d7f6b9",
            "4cdad506",
            "0a28a477",
            "ba087652",
            "969b1cdb",
            "01e1d114",
            "18160ddd",
            "a9059cbb",
            "23b872dd",
            "b460af94"
        ];
        selectors = new bytes4[](_selectors.length);
        for (uint256 i; i < _selectors.length; ++i) {
            selectors[i] = bytes4(bytes(_selectors[i]));
        }
    }
}
