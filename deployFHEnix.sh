#!/bin/zsh

# Run anvil.sh in another shell before running this

# To load the variables in the .env file
source .env

# To deploy and verify our contract
forge script script/GasPriceOptionsFactory.s.sol:Deploy --skip-simulation --rpc-url "https://api.nitrogen.fhenix.zone" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
