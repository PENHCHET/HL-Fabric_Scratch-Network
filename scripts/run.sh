#!/usr/bin/env bash

# Running log/script of network build commands

bash ./scripts/dirs.sh

cryptogen generate --output=crypto-materials --config=config_hl/orderer-peers.yaml

export FABRIC_CFG_PATH=${PWD}/config_hl
# where configtxgen will look for the configtx.yaml file
# TODO feature request to specify file (allowing split into separate files e.g. for genesis vs Channels, etc)
