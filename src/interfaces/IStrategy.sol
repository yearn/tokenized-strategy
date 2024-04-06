// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import {ITokenizedStrategy} from "./ITokenizedStrategy.sol";
import {IBaseStrategy} from "./IBaseStrategy.sol";

interface IStrategy is IBaseStrategy, ITokenizedStrategy {}
