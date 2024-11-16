#!/bin/zsh

# Run anvil.sh in another shell before running this

# To load the variables in the .env file
source .env

# To deploy and verify our contract
#forge script script/DexFactory.s.sol:Deploy --legacy --rpc-url "https://public-node.testnet.rsk.co" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
forge script script/DexFactory.s.sol:Deploy --legacy --rpc-url "https://rpc.testnet.rootstock.io/lZZVyJCscc9luAu3ByNcsjI9UOAb9H-T" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
#forge script script/DexFactory.s.sol:Deploy --legacy --rpc-url "https://rootstock-testnet.g.alchemy.com/v2/IhgQBvRgybGlyu1Jo8-f9PpIphc4iqw3" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
