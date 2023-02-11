// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import "forge-std/console.sol";
import {ExtendedTest} from "./ExtendedTest.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {MockErc20} from "../Mocks/MockErc20.sol";
import {Generic4626} from "../Mocks/Generic4626.sol";
import {MockStrategy} from "../Mocks/MockStrategy.sol";

import {SelectorHelper} from "../../SelectorHelper.sol";
import {BaseLibrary} from "../../libraries/BaseLibrary.sol";

contract Setup is ExtendedTest {
    MockErc20 public token;
    Generic4626 public strategy;

    SelectorHelper public selectorHelper;

    address public user = address(10);

    uint256 public minFuzzAmount = 1;
    uint256 public maxFuzzAmount = 1e50;

    function setUp() public virtual {
        // deploy the selector helper first to get a deterministic location
        bytes4[] memory selectors = getSelectors();
        selectorHelper = new SelectorHelper(address(BaseLibrary), selectors);

        // create token we will be using as the underlying asset
        token = new MockErc20("Test Token", "tTKN");
        // we save the mock base strategy as a Generic4626 to give it the needed interface
        strategy = Generic4626(address(new MockStrategy(token)));

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

        // label all the used addresses for traces
        vm.label(address(token), "token");
        vm.label(address(strategy), "strategy");
        vm.label(address(BaseLibrary), "library");
        vm.label(address(selectorHelper), "selector heleper");
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
