// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {TokenizedStrategy} from "../../TokenizedStrategy.sol";

contract MockStorage {
    TokenizedStrategy.StrategyData public slot0;
    TokenizedStrategy.Management public slot1;
    uint256 public slot3;
}
