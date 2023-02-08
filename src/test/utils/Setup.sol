// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import "forge-std/console.sol";
import {ExtendedTest} from "./ExtendedTest.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {MockStrategy} from "../Mocks/MockStrategy.sol";

contract Setup is ExtendedTest {

    ERC20 public token;
    MockStrategy public strategy;

    uint256 public minFuzzAmount = 1;
    uint256 public maxFuzzAmount = 1e30;

    function setUp() public virtual {

        token = new ERC20("Test Token", "tTKN");
        strategy = new MockStrategy(token);

        // label all the used addresses for traces
        vm.label(address(token), "token");
        vm.label(address(strategy), "strategy");
    }
}