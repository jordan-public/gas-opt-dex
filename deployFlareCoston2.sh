#!/bin/zsh

# Run anvil.sh in another shell before running this

# To load the variables in the .env file
source .env

# May need to switch to London EVM fork or Solidity version 8.19 or lower

# To deploy and verify our contract
forge script script/GasPriceOptionsFactory.s.sol:Deploy --rpc-url "https://coston2-api.flare.network/ext/C/rpc" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
