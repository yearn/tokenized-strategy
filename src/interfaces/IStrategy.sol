// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {ITokenizedStrategy} from "./ITokenizedStrategy.sol";
import {IBaseTokenizedStrategy} from "./IBaseTokenizedStrategy.sol";

interface IStrategy is IBaseTokenizedStrategy, ITokenizedStrategy {}
