// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {ExtendedTest} from "../utils/ExtendedTest.sol";
import {Setup, IMockStrategy, ERC20Mock} from "../utils/Setup.sol";

contract StrategyHandler is ExtendedTest {

    Setup public setup;

    constructor() {
        setup = Setup(msg.sender);
    }
    
    function deposit(address _user, uint256 _amount) public {
        ERC20Mock asset = setup.asset();
        IMockStrategy strategy = setup.strategy();

        asset.mint(_user, _amount);
        vm.prank(_user);
        asset.approve(address(strategy), _amount);

        vm.prank(_user);
        strategy.deposit(_amount, _user);
    }

    function mint(address _user, uint256 _amount) public {
        ERC20Mock asset = setup.asset();
        IMockStrategy strategy = setup.strategy();
        
        uint256 toMint = strategy.previewMint(_amount);
        asset.mint(_user, toMint);
        vm.prank(_user);
        asset.approve(address(strategy), toMint);

        vm.prank(_user);
        strategy.mint(_amount, _user);
    }

    function withdraw(address _user, uint256 _amount) public {
        ERC20Mock asset = setup.asset();
        IMockStrategy strategy = setup.strategy();

        vm.prank(_user);
        strategy.withdraw(_amount, _user, _user);
    }

    function redeem(address _user, uint256 _amount) public {
        ERC20Mock asset = setup.asset();
        IMockStrategy strategy = setup.strategy();

        vm.prank(_user);
        strategy.redeem(_amount, _user, _user);
    }

    function createProfit(uint256 _amount) public {
        ERC20Mock asset = setup.asset();
        IMockStrategy strategy = setup.strategy();

        asset.mint(address(strategy), _amount);
    }

    function createLoss(address _address, uint256 _amount) public {
        ERC20Mock asset = setup.asset();

        vm.prank(address(setup.yieldSource()));
        asset.transfer(_address, _amount);
    }

    function report() public {
        IMockStrategy strategy = setup.strategy();

        vm.prank(setup.keeper());
        strategy.report();
    }

    function tend() public {
        IMockStrategy strategy = setup.strategy();

        vm.prank(setup.keeper());
        strategy.tend();
    }

    // setter functions
        // ERC20 functions
    
}