pragma solidity 0.8.14;

contract MockFactory {
    uint16 public feeBps;
    uint32 public lastChange;
    address public recipient;

    constructor(uint16 bps, address treasury) {
        feeBps = bps;
        lastChange = uint32(block.timestamp);
        recipient = treasury;
    }

    function setRecipient(address _address) public {
        recipient = _address;
    }

    function setFee(uint16 bps) public {
        feeBps = bps;
        lastChange = uint32(block.timestamp);
    }

    function protocol_fee_config() external returns (uint16, uint32, address) {
        return (feeBps, lastChange, recipient);
    }
}
