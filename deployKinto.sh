#!/bin/zsh

# Run anvil.sh in another shell before running this

# To load the variables in the .env file
source .env

# To deploy and verify our contract
# forge script script/GasPriceOptionsFactory.s.sol:Deploy --rpc-url "https://42888.rpc.thirdweb.com/${THIRDWEB_API_KEY}" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
forge script script/GasPriceOptionsFactory.s.sol:Deploy --rpc-url "http://35.215.120.180:8545" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
