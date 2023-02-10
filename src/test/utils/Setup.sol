// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import "forge-std/console.sol";
import {ExtendedTest} from "./ExtendedTest.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {MockErc20} from "../Mocks/MockErc20.sol";
import {Generic4626} from "../Mocks/Generic4626.sol";
import {MockStrategy} from "../Mocks/MockStrategy.sol";

import {BaseLibrary} from "../../libraries/BaseLibrary.sol";

contract Setup is ExtendedTest {

    MockErc20 public token;
    Generic4626 public strategy;
    

    address public user = address(10);

    uint256 public minFuzzAmount = 1;
    uint256 public maxFuzzAmount = 1e50;

    function setUp() public virtual {

        token = new MockErc20("Test Token", "tTKN");
        // we save the mock base strategy as a Generic4626 to give it the needed interface
        strategy = Generic4626(address(new MockStrategy(token)));

        // deploy the selector helper

        // set the slots for the baseLibrary and the selector helper to the correct addresses
        // store the libraries address at slot 0
        vm.store(address(strategy), bytes32(0), bytes32(uint256(uint160(address(BaseLibrary)))));

        // label all the used addresses for traces
        vm.label(address(token), "token");
        vm.label(address(strategy), "strategy");
        vm.label(address(BaseLibrary), "library");
    }
}