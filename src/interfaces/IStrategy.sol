// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {ITokenizedStrategy, IERC4626} from "./ITokenizedStrategy.sol";
import {IBaseTokenizedStrategy} from "./IBaseTokenizedStrategy.sol";

interface IStrategy is IBaseTokenizedStrategy, ITokenizedStrategy {
    // Need to override the `asset` function since 
    // its defined in both interfaces inherited.
    function asset()
        external
        view
        override(IBaseTokenizedStrategy, IERC4626)
        returns (address);
}
