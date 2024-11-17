// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./CallOption.sol";

/**
 * @title GasPriceOptionsFactory
 * @dev Factory contract to create new CallOption contracts.
 */
contract GasPriceOptionsFactory {
    // Array to keep track of all deployed CallOption contracts
    address[] public allOptions;

    event OptionCreated(address optionAddress, uint256 strike, uint256 expiration);

    /**
     * @dev Creates a new CallOption contract.
     * @param _strike The strike price (in wei) for the option.
     * @param _expiration The expiration time (timestamp) for the option.
     */
    function createOption(uint256 _strike, uint256 _expiration) external returns (address) {
        require(_expiration > block.timestamp, "Expiration must be in the future");
        CallOption option = new CallOption(_strike, _expiration, address(this)); // Corrected
        allOptions.push(address(option));
        emit OptionCreated(address(option), _strike, _expiration);
        return address(option);
    }

    /**
     * @dev Returns the total number of options created.
     */
    function getOptionsCount() external view returns (uint256) {
        return allOptions.length;
    }
}