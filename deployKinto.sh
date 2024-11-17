#!/bin/zsh

# Run anvil.sh in another shell before running this

# To load the variables in the .env file
source .env

# To deploy and verify our contract
forge script script/GasPriceOptionsFactory.s.sol:Deploy --rpc-url "https://zircuit1-testnet.p2pify.com" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv