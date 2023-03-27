pragma solidity 0.8.18;

contract MockRegistry {
    event NewStrategy(address indexed newStrategy, address indexed assetUsed);

    address[] public strategies;

    function newStrategy(address _strategy, address _asset) external {
        strategies.push(_strategy);

        emit NewStrategy(_strategy, _asset);
    }
}
