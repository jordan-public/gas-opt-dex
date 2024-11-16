#!/bin/zsh

# Run anvil.sh in another shell before running this

# To load the variables in the .env file
source .env

# To deploy and verify our contract
#forge script script/Multiprotocol.s.sol:Deploy --slow --rpc-url "https://testnet.hashio.io/api" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
forge script script/DexFactory.s.sol:Deploy --slow --rpc-url "https://296.rpc.thirdweb.com" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
