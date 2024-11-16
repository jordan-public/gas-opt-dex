#!/bin/zsh

# Run anvil.sh in another shell before running this

# To load the variables in the .env file
source .env

# To deploy and verify our contract
forge script script/DexFactory.s.sol:Deploy --slow --rpc-url "https://testnet.evm.nodes.onflow.org" --sender $SENDER --private-key $PRIVATE_KEY --broadcast -vvvv
