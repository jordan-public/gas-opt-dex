// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {GasPriceOptionsFactory} from "../src/GasPriceOptionsFactory.sol";

contract Deploy is Script {
    GasPriceOptionsFactory public gasPriceOptionsFactory;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        gasPriceOptionsFactory = new GasPriceOptionsFactory();
        console.log("GasPriceOptionsFactory deployed at address:", address(gasPriceOptionsFactory));

        // Create a new option via the factory
        address option = gasPriceOptionsFactory.createOption(100 gwei, block.timestamp + 7 days);
        console.log("Sample Option created at address:", option);

        vm.stopBroadcast();
    }
}
