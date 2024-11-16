#!/bin/zsh

# Run anvil.sh in another shell before running this

# To load the variables in the .env file
source .env

# git clone https://github.com/RookieCol/hardhat-foundry-starter-kit.git
# cd hardhat-foundry-starter-kit
# chmod u+x rootstock-setup.sh
# ./rootstock-setup.sh

# To deploy and verify our contract
#forge script script/GasPriceOptionsFactory.s.sol:Deploy --legacy --rpc-url "https://public-node.testnet.rsk.co" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
forge script script/GasPriceOptionsFactory.s.sol:Deploy --legacy --rpc-url "https://rpc.testnet.rootstock.io/lZZVyJCscc9luAu3ByNcsjI9UOAb9H-T" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
#forge script script/GasPriceOptionsFactory.s.sol:Deploy --legacy --rpc-url "https://rootstock-testnet.g.alchemy.com/v2/IhgQBvRgybGlyu1Jo8-f9PpIphc4iqw3" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
