// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DexFactory} from "../src/DexFactory.sol";

contract DexFactoryTest is Test {
    DexFactory public dexFactory;

    function setUp() public {
        dexFactory = new DexFactory();
        dexFactory.setNumber(0);
    }

    function test_Increment() public {
        dexFactory.increment();
        assertEq(dexFactory.number(), 1);
    }

}
