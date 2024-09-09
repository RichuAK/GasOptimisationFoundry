// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Gas.sol";

contract DeployGas is Script {
    GasContract public gas;
    uint256 public totalSupply = 1000000000;
    address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address addr1 = address(0x5678);
    address addr2 = address(0x9101);
    address addr3 = address(0x1213);

    address[] admins = [address(0x1), address(0x2), address(0x3), address(0x4), owner];

    function run() public {
        vm.startBroadcast(owner);
        gas = new GasContract(admins, totalSupply);
        vm.stopBroadcast();
        console.log("Address: ", address(gas));
    }
}
