// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IFactory {
    function protocol_fee_config() external view returns (uint16, address);
}
