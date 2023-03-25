pragma solidity 0.8.18;

contract Factory {
    uint16 public feeBps;
    uint32 public lastChange;
    address public recipient;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(uint16 bps, address treasury) {
        owner = msg.sender;
        feeBps = bps;
        lastChange = uint32(block.timestamp);
        recipient = treasury;
    }

    function setRecipient(address _address) public onlyOwner {
        recipient = _address;
    }

    function setFee(uint16 bps) public onlyOwner {
        feeBps = bps;
        lastChange = uint32(block.timestamp);
    }

    function protocol_fee_config()
        external
        view
        returns (uint16, uint32, address)
    {
        return (feeBps, lastChange, recipient);
    }
}
