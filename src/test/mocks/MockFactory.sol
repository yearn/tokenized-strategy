pragma solidity 0.8.18;

contract MockFactory {
    uint16 public feeBps;
    address public recipient;

    constructor(uint16 bps, address treasury) {
        feeBps = bps;
        recipient = treasury;
    }

    function setRecipient(address _address) public {
        recipient = _address;
    }

    function setFee(uint16 bps) public {
        feeBps = bps;
    }

    function protocol_fee_config() external view returns (uint16, address) {
        return (feeBps, recipient);
    }
}
