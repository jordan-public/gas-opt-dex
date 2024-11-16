// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DexFactory} from "../src/DexFactory.sol";

contract Deploy is Script {
    DexFactory public dexFactory;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        dexFactory = new DexFactory();

        vm.stopBroadcast();
    }
}
