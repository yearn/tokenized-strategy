// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockErc20 is ERC20 {
    constructor(string memory name, string memory symbol)
        ERC20("Test Token", "TKN")
    {}

    function mint(address u, uint256 a) external {
        _mint(u, a);
    }
}
