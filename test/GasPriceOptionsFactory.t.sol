// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CallOption} from "../src/CallOption.sol";
import {GasPriceOptionsFactory} from "../src/GasPriceOptionsFactory.sol";

contract GasPriceOptionsFactoryTest is Test {
    GasPriceOptionsFactory public gasPriceOptionsFactory;
    CallOption public callOption;

    function setUp() public {
        gasPriceOptionsFactory = new GasPriceOptionsFactory();
        callOption = gasPriceOptionsFactory.createOption(2 * block.basefee, block.timestamp + 1 days);
    }

    function test_GetBasefee() public {
        console.log("Basefee: {}", block.basefee);
        assert(block.basefee > 0);
    }
}
