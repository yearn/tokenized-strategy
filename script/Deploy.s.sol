// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

import "forge-std/Script.sol";

// Deploy a contract to a deterministic address with create2 factory.
contract Deploy is Script {
    // Create X address.
    Deployer public deployer =
        Deployer(0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed);

    // Vault factory address for v3.0.2
    address public factory = 0x444045c5C13C246e117eD36437303cac8E250aB0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Append constructor args to the bytecode
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("TokenizedStrategy.sol:TokenizedStrategy"),
            abi.encode(factory)
        );

        // Pick an unique salt
        bytes32 salt = keccak256("v3.0.2");

        address contractAddress = deployer.deployCreate2(salt, bytecode);

        console.log("Address is ", contractAddress);

        vm.stopBroadcast();
    }
}

contract Deployer {
    event ContractCreation(address indexed newContract, bytes32 indexed salt);

    function deployCreate2(
        bytes32 salt,
        bytes memory initCode
    ) public payable returns (address newContract) {}
}
