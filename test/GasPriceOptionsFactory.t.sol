// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GasPriceOptionsFactory.sol";
import "../src/CallOption.sol";

/**
 * @title GasPriceOptionsTest
 * @dev Test suite for GasPriceOptionsFactory and CallOption contracts using Foundry.
 */
contract GasPriceOptionsTest is Test {
    GasPriceOptionsFactory factory;
    CallOption option;

    // Test parameters
    uint256 strikePrice = 100 gwei; // Example strike price
    uint256 expiration; // To be set in setup
    address payable writer = payable(address(0x1));
    address payable buyer = payable(address(0x2));
    address payable liquidator = payable(address(0x3));

    // Events to capture for testing
    event OptionCreated(address optionAddress, uint256 strike, uint256 expiration);
    event ShortPositionCreated(address indexed writer, uint256 size, uint256 collateral);
    event LongPositionCreated(address indexed buyer, uint256 size, uint256 price);
    event OptionExercised(address indexed holder, uint256 amount, uint256 gasPrice);
    event PositionLiquidated(address indexed liquidator, address indexed positionOwner, uint256 amount);
    event CollateralWithdrawn(address indexed writer, uint256 amount);

    receive() external payable {} // Tester contract must be able to receive ETH
    fallback() external payable {} // Tester contract must be able to receive ETH

    function setUp() public {
        // Initialize the factory
        factory = new GasPriceOptionsFactory();

        // Set expiration to 1 week from now
        expiration = block.timestamp + 7 days;

        // Create a new option via the factory
        vm.prank(writer);
        factory.createOption(strikePrice, expiration);

        // Retrieve the created option
        address optionAddress = factory.allOptions(0);
        address payable payableOptionAddress = payable(optionAddress);
        option = CallOption(payableOptionAddress);
    }

    function testBlockBasefee() public view {
        assert(block.basefee > 0);
    }

    /**
     * @dev Test the creation of an option.
     */
    function testOptionCreation() public view {
        // Verify that the option was created with correct parameters
        assertEq(option.strike(), strikePrice, "Strike price mismatch");
        assertEq(option.expiration(), expiration, "Expiration mismatch");
        assertEq(option.factory(), address(factory), "Factory address mismatch");
    }

    /**
     * @dev Test the creation of a short position (writing options).
     */
    function testCreateShortPosition() public {
        uint256 optionSize = 10;
        uint256 requiredCollateral = optionSize * strikePrice * 3; // 3x collateralization

        // Writer writes options by sending the required collateral
        vm.prank(writer);
        vm.deal(writer, requiredCollateral);
        vm.expectEmit(true, true, true, true);
        emit ShortPositionCreated(writer, optionSize, requiredCollateral);

        option.writeOptions{value: requiredCollateral}(optionSize);

        // Verify that the short position is recorded correctly
        (address owner, uint256 size, uint256 collateral) = option.shortPositions(0);
        assertEq(owner, writer, "Short position owner mismatch");
        assertEq(size, optionSize, "Short position size mismatch");
        assertEq(collateral, requiredCollateral, "Short position collateral mismatch");
    }

    /**
     * @dev Test the purchase of an option by a buyer.
     */
    function testPurchaseOption() public {
        uint256 optionSize = 5;
        uint256 pricePerOption = 1 ether;
        uint256 totalPrice = optionSize * pricePerOption;

        // Buyer purchases options by sending ETH
        vm.prank(buyer);
        vm.deal(buyer, totalPrice);
        vm.expectEmit(true, true, true, true);
        emit LongPositionCreated(buyer, optionSize, pricePerOption);

        option.buyOptions{value: totalPrice}(optionSize);

        // Verify that the long position is recorded correctly
        (address longOwner, uint256 longSize) = option.longPositions(0);
        assertEq(longOwner, buyer, "Long position owner mismatch");
        assertEq(longSize, optionSize, "Long position size mismatch");
    }

    /**
     * @dev Test the exercise of part of the option.
     */
    function testExerciseOption() public {
        uint256 optionSize = 10;
        uint256 pricePerOption = 1 ether;
        uint256 totalPrice = optionSize * pricePerOption;
        uint256 exerciseAmount = 4;

        // Buyer purchases options
        vm.prank(buyer);
        vm.deal(buyer, totalPrice);
        option.buyOptions{value: totalPrice}(optionSize);

        // Set block.basefee to be higher than strike price to allow exercise
        uint256 newBasefee = strikePrice + 50 gwei;
        vm.fee(newBasefee);

        // Record initial ETH balance of buyer
        uint256 buyerInitialBalance = address(buyer).balance;

        // Buyer exercises part of their options
        vm.prank(buyer);
        vm.expectEmit(true, true, true, true);
        emit OptionExercised(buyer, exerciseAmount, newBasefee);

        option.exercise(exerciseAmount);

        // Calculate expected payout
        uint256 expectedPayout = exerciseAmount * (newBasefee - strikePrice);

        // Verify that buyer received the payout
        uint256 buyerFinalBalance = address(buyer).balance;
        assertEq(buyerFinalBalance, buyerInitialBalance + expectedPayout, "Buyer did not receive correct payout");

        // Verify that the long position was reduced
        (address longOwner, uint256 longSize) = option.longPositions(0);
        assertEq(longOwner, buyer, "Long position owner mismatch after exercise");
        assertEq(longSize, optionSize - exerciseAmount, "Long position size not reduced correctly");
    }

    /**
     * @dev Test the liquidation of an undercollateralized short position.
     */
    function testLiquidation() public {
        uint256 optionSize = 10;
        uint256 requiredCollateral = optionSize * strikePrice * 3; // 3x collateralization
        uint256 initialCollateral = requiredCollateral;

        // Writer writes options by sending the required collateral
        vm.prank(writer);
        vm.deal(writer, initialCollateral);
        vm.expectEmit(true, true, true, true);
        emit ShortPositionCreated(writer, optionSize, requiredCollateral);

        option.writeOptions{value: initialCollateral}(optionSize);

        // Verify that the short position is recorded correctly
        (address owner, uint256 size, uint256 collateral) = option.shortPositions(0);
        assertEq(owner, writer, "Short position owner mismatch");
        assertEq(size, optionSize, "Short position size mismatch");
        assertEq(collateral, requiredCollateral, "Short position collateral mismatch");

        // Manipulate the storage to make the position undercollateralized
        // Compute the storage slot for shortPositions[0].collateral
        // shortPositions is at slot 3
        // collateral is at keccak256(3) + 2

        bytes32 baseSlot = keccak256(abi.encodePacked(uint256(3)));
        uint256 baseSlotNum = uint256(baseSlot);
        uint256 collateralSlotNum = baseSlotNum + 2;
        bytes32 collateralSlot = bytes32(collateralSlotNum);

        uint256 insufficientCollateral = requiredCollateral / 2;
        vm.store(address(option), collateralSlot, bytes32(insufficientCollateral));

        // Verify that the short position is undercollateralized
        (address payable shortOwner, uint256 shortSize, uint256 shortCollateral) = option.shortPositions(0);
        uint256 expectedRequiredCollateral = shortSize * strikePrice * 3;
        assertEq(shortOwner, writer, "Short position owner mismatch after manipulation");
        assertEq(shortSize, optionSize, "Short position size mismatch after manipulation");
        assertTrue(shortCollateral < expectedRequiredCollateral, "Position should be undercollateralized");

        // Liquidator covers the deficit
        uint256 deficit = expectedRequiredCollateral - shortCollateral;
        uint256 liquidatorPayment = deficit;

        // Fund the liquidator and perform liquidation within a single prank session
        vm.startPrank(liquidator);
        vm.deal(liquidator, liquidatorPayment);

        // Expect the PositionLiquidated event
//!!!Check this!        vm.expectEmit(true, true, true, true);
        // Do NOT emit the event manually
        // emit PositionLiquidated(liquidator, writer, optionSize); // Removed

        // Liquidator liquidates the position by sending the deficit
//!!!Forge test cannot make the short owner payable - fix this!       
        option.liquidate{value: liquidatorPayment}(0);

        vm.stopPrank();

        // Verify that the short position's collateral is now sufficient
        (address updatedOwner, uint256 updatedSize, uint256 updatedCollateral) = option.shortPositions(0);
        assertEq(updatedOwner, writer, "Short position owner mismatch after liquidation");
        assertEq(updatedSize, optionSize, "Short position size mismatch after liquidation");
        assertEq(updatedCollateral, insufficientCollateral + liquidatorPayment, "Collateral was not updated correctly after liquidation");

        // Additionally, verify that the collateral meets the required 3x collateralization
        assertTrue(updatedCollateral >= expectedRequiredCollateral, "Collateral is still insufficient after liquidation");
    }
}