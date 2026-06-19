// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import "forge-std/Script.sol";

// Deploy a contract to a deterministic address with create2 factory.
contract Deploy is Script {
    // Create X address.
    Deployer public deployer =
        Deployer(0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed);

    // Vault factory address for v3.1.0
    address public factory = 0x310aC28ACF5E514abDbFF9Ab25e21f1bfe22bcAC;

    function run() external {
        vm.startBroadcast();

        // Append constructor args to the bytecode
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("TokenizedStrategy.sol:TokenizedStrategy"),
            abi.encode(factory)
        );

        // CreateX guards this raw salt to
        // 0xf45fdd830e8ee48b85bd4c66eb52737e9c490d2bf9485311e0c013ce2b936820,
        // yielding 0x310f5Db015E9d6E542fd41bd4542640790791e76.
        bytes32 salt = bytes32(
            uint256(
                0x000000000000000000000000000000000000000000000000000000000019fdf1
            )
        );

        address contractAddress = deployer.deployCreate2(salt, bytecode);

        console.log("Address is ", contractAddress);

        vm.stopBroadcast();
    }
}

interface Deployer {
    event ContractCreation(address indexed newContract, bytes32 indexed salt);

    function deployCreate2(
        bytes32 salt,
        bytes memory initCode
    ) external payable returns (address newContract);
}
