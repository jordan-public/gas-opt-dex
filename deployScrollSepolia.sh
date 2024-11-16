#!/bin/zsh

# Run anvil.sh in another shell before running this

# To load the variables in the .env file
source .env

# To deploy and verify our contract
forge script script/DexFactory.s.sol:Deploy --rpc-url "https://sepolia-rpc.scroll.io/" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv