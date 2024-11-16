#!/bin/zsh

# Run anvil.sh in another shell before running this

# To load the variables in the .env file
source .env

# To deploy and verify our contract
# forge script script/DexFactory.s.sol:Deploy --slow --legacy --rpc-url "https://mainnet.skalenodes.com/v1/elated-tan-skat" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
forge script script/DexFactory.s.sol:Deploy --slow --legacy --rpc-url "https://testnet.skalenodes.com/v1/juicy-low-small-testnet" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
