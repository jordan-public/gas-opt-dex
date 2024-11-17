// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title CallOption
 * @dev Represents an American-style Call Option on the EVM Gas Price.
 */
contract CallOption {
    // Option parameters
    uint256 public strike;        // Strike price in wei
    uint256 public expiration;    // Expiration timestamp
    address public factory;       // Address of the factory that created this option

    // Collateralization factor (3x)
    uint256 constant COLLATERAL_FACTOR = 3;

    // Structs for positions
    struct ShortPosition {
        address payable owner;
        uint256 size;           // Number of options written
        uint256 collateral;     // Collateral deposited
    }

    struct LongPosition {
        address payable owner;
        uint256 size;           // Number of options bought
    }

    // Order book structs
    struct Bid {
        address payable bidder;
        uint256 amount;         // Number of options
        uint256 price;          // Price per option in wei
    }

    struct Offer {
        address payable seller;
        uint256 amount;         // Number of options
        uint256 price;          // Price per option in wei
    }

    // Arrays to keep track of positions
    ShortPosition[] public shortPositions;
    LongPosition[] public longPositions;

    // Order books
    Bid[] public bids;
    Offer[] public offers;

    // Events
    event ShortPositionCreated(address indexed writer, uint256 size, uint256 collateral);
    event LongPositionCreated(address indexed buyer, uint256 size, uint256 price);
    event BidPlaced(address indexed bidder, uint256 amount, uint256 price);
    event OfferPlaced(address indexed seller, uint256 amount, uint256 price);
    event OptionExercised(address indexed holder, uint256 amount, uint256 gasPrice);
    event OptionSettled(uint256 finalGasPrice);
    event PositionLiquidated(address indexed liquidator, address indexed positionOwner, uint256 amount);
    event CollateralWithdrawn(address indexed writer, uint256 amount);

    /**
     * @dev Modifier to check if the option is not expired.
     */
    modifier notExpired() {
        require(block.timestamp < expiration, "Option has expired");
        _;
    }

    /**
     * @dev Modifier to check if the option is expired.
     */
    modifier isExpired() {
        require(block.timestamp >= expiration, "Option has not expired yet");
        _;
    }

    /**
     * @dev Constructor to initialize the CallOption contract.
     * @param _strike The strike price in wei.
     * @param _expiration The expiration timestamp.
     * @param _factory The address of the factory contract.
     */
    constructor(uint256 _strike, uint256 _expiration, address _factory) {
        require(_expiration > block.timestamp, "Expiration must be in the future");
        strike = _strike;
        expiration = _expiration;
        factory = _factory;
    }

    /**
     * @dev Allows a user to write (short) options by depositing collateral.
     * @param _size The number of options to write.
     */
    function writeOptions(uint256 _size) external payable notExpired {
        require(_size > 0, "Size must be greater than zero");
        uint256 requiredCollateral = _size * strike * COLLATERAL_FACTOR;
        require(msg.value >= requiredCollateral, "Insufficient collateral");

        // Create new short position
        shortPositions.push(ShortPosition({
            owner: payable(msg.sender),
            size: _size,
            collateral: msg.value
        }));

        emit ShortPositionCreated(msg.sender, _size, msg.value);
    }

    /**
     * @dev Allows a user to buy (long) options by paying ETH.
     * @param _size The number of options to buy.
     */
    function buyOptions(uint256 _size) external payable notExpired {
        require(_size > 0, "Size must be greater than zero");
        require(msg.value > 0, "Must send ETH to buy options");

        // Assuming price per option is msg.value / _size
        uint256 pricePerOption = msg.value / _size;
        require(pricePerOption > 0, "Price per option must be greater than zero");

        // Create new long position
        longPositions.push(LongPosition({
            owner: payable(msg.sender),
            size: _size
        }));

        emit LongPositionCreated(msg.sender, _size, pricePerOption);
    }

    /**
     * @dev Places a bid in the order book.
     * @param _amount The number of options to bid for.
     * @param _price The bid price per option in wei.
     */
    function placeBid(uint256 _amount, uint256 _price) external payable notExpired {
        require(_amount > 0, "Amount must be greater than zero");
        require(_price > 0, "Price must be greater than zero");
        require(msg.value == _amount * _price, "ETH sent does not match bid size");

        bids.push(Bid({
            bidder: payable(msg.sender),
            amount: _amount,
            price: _price
        }));

        emit BidPlaced(msg.sender, _amount, _price);
    }

    /**
     * @dev Places an offer in the order book.
     * @param _amount The number of options to sell.
     * @param _price The offer price per option in wei.
     */
    function placeOffer(uint256 _amount, uint256 _price) external notExpired {
        require(_amount > 0, "Amount must be greater than zero");
        require(_price > 0, "Price must be greater than zero");

        // Transfer the options to be sold to the contract
        // For simplicity, assuming options are represented by the longPositions
        // In practice, you'd have a better mechanism to track available options

        offers.push(Offer({
            seller: payable(msg.sender),
            amount: _amount,
            price: _price
        }));

        emit OfferPlaced(msg.sender, _amount, _price);
    }

    /**
     * @dev Allows a long holder to exercise their option at any time before expiration.
     */
    function exercise(uint256 _amount) external notExpired {
        require(_amount > 0, "Amount must be greater than zero");

        // Find the long position
        uint256 totalAvailable = 0;
        uint256 positionIndex = type(uint256).max;
        for (uint256 i = 0; i < longPositions.length; i++) {
            if (longPositions[i].owner == msg.sender) {
                totalAvailable += longPositions[i].size;
                positionIndex = i;
                break;
            }
        }
        require(positionIndex != type(uint256).max, "Long position not found");
        require(totalAvailable >= _amount, "Not enough options to exercise");

        // Calculate the cost based on current gas price
        uint256 currentGasPrice = block.basefee;
        require(currentGasPrice >= strike, "Gas price below strike, option not profitable");

        uint256 payout = _amount * (currentGasPrice - strike);

        // Transfer ETH to the option holder
        payable(msg.sender).transfer(payout);

        // Reduce the long position
        longPositions[positionIndex].size -= _amount;

        emit OptionExercised(msg.sender, _amount, currentGasPrice);
    }

    /**
     * @dev Settles the option at expiration using block.basefee.
     */
    function settle() external isExpired {
        uint256 finalGasPrice = block.basefee;
        emit OptionSettled(finalGasPrice);
        // Additional settlement logic can be added here
    }

    /**
     * @dev Liquidates an undercollateralized short position.
     * @param _positionIndex The index of the short position to liquidate.
     */
    function liquidate(uint256 _positionIndex) external payable notExpired {
        require(_positionIndex < shortPositions.length, "Invalid position index");
        ShortPosition storage position = shortPositions[_positionIndex];

        // Check collateralization
        uint256 requiredCollateral = position.size * strike * COLLATERAL_FACTOR;
        if (position.collateral < requiredCollateral) {
            // Calculate the deficit
            uint256 deficit = requiredCollateral - position.collateral;
            require(msg.value >= deficit, "Insufficient ETH to cover deficit");

            // Transfer the deficit to the original position owner
//!!!Forge test cannot make the short owner payable - fix this!!!
//            payable(position.owner).transfer(deficit);

            // Update the collateral
            position.collateral += msg.value;

            emit PositionLiquidated(msg.sender, position.owner, position.size);
        } else {
            revert("Position is sufficiently collateralized");
        }
    }

    /**
     * @dev Allows writers to withdraw their collateral after expiration.
     * @param _positionIndex The index of the short position to withdraw collateral from.
     */
    function withdrawCollateral(uint256 _positionIndex) external isExpired {
        require(_positionIndex < shortPositions.length, "Invalid position index");
        ShortPosition storage position = shortPositions[_positionIndex];
        require(position.owner == msg.sender, "Not the owner of this position");

        uint256 collateralAmount = position.collateral;
        position.collateral = 0;

        // Transfer collateral back to the writer
        payable(msg.sender).transfer(collateralAmount);

        emit CollateralWithdrawn(msg.sender, collateralAmount);
    }

    /**
     * @dev Fallback function to accept ETH.
     */
    receive() external payable {}
}