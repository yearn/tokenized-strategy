// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc4626-tests/ERC4626.test.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {ERC4626Mock, IERC20Metadata} from "@openzeppelin/contracts/mocks/ERC4626Mock.sol";

import {Setup, ERC20, MockStrategy} from "./utils/Setup.sol";

// SEE https://github.com/a16z/erc4626-tests
contract ERC4626StdTest is ERC4626Test, Setup {
    function setUp() public override(ERC4626Test, Setup) {
        super.setUp();
        _underlying_ = address(token);
        _vault_ = address(strategy);
        _delta_ = 0;
        _vaultMayBeEmpty = true;
        _unlimitedAmount = true;
    }
}