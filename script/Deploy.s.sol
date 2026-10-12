// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import "forge-std/Script.sol";

// Deploy a contract to a deterministic address with create2 factory.
contract Deploy is Script {
    // Create X address.
    Deployer public deployer =
        Deployer(0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed);

    // Vault factory address for v3.1.1
    address public factory = 0x311de24e48C360B9A7765E7aB7eCDBABCd27B134;

    function run() external {
        vm.startBroadcast();

        // Append constructor args to the bytecode
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("TokenizedStrategy.sol:TokenizedStrategy"),
            abi.encode(factory)
        );

        // CreateX guards this raw salt to
        // 0x6b38d02c6d833fcd9319e92fdee40c8b2ca0e465fb7bd0bdf5d856bfb88fc6c2,
        // yielding 0x3110D1Eec90f0651C18e75AD37711A8777342504.
        bytes32 salt = bytes32(
            uint256(
                0x0000000000000000000000000000000000000000000000000000000000000a47
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
