#!/usr/bin/env bash

# Running log/script of network build commands

bash ./scripts/dirs.sh

cryptogen generate --output=crypto-materials --config=config_hl/orderer-peers.yaml

export FABRIC_CFG_PATH=${PWD}/config_hl
# where configtxgen will look for the configtx.yaml file
# TODO: feature request to specify file (allowing split into separate files e.g. for genesis vs Channels, etc)

configtxgen -profile NetworkGenesis -outputBlock ./artifacts/genesis.block

configtxgen -profile NetworkGenesis -inspectBlock ./artifacts/genesis.block > _docs/inspectGenesis.json

export CHANNEL_NAME=openchannel # (!!!!!!!!) NO CAPITAL LETTERS
# TODO: TBD is this intentional or bug? Did not see referenced in doc.
echo $CHANNEL_NAME
mkdir ./artifacts/$CHANNEL_NAME

configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./artifacts/$CHANNEL_NAME/channel.tx -channelID $CHANNEL_NAME

configtxgen -profile TwoOrgsChannel -inspectChannelCreateTx ./artifacts/$CHANNEL_NAME/channel.tx > _docs/inspectChannel.json

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./artifacts/$CHANNEL_NAME/Org1anchors.tx -channelID $CHANNEL_NAME -asOrg Org1

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./artifacts/$CHANNEL_NAME/Org2anchors.tx -channelID $CHANNEL_NAME -asOrg Org2

# CHANNEL_NAME=$CHANNEL_NAME TIMEOUT=60 docker-compose -f config_docker/docker-compose-cli.yaml up
# NOT triggering the bash script in the yaml (executing commands manually). Do not need to pass variables.
docker-compose -f config_docker/docker-compose-cli.yaml up

docker ps -a #review containers created by docker
docker exec -it cli bash #shell into the 'cli' container to interact with the network
## !! Within cli container:
# root@35ed5451c268:/opt/gopath/src#:

    echo $CHANNEL_NAME #check channel name

    peer channel create -o orderer.scratch.com:7050 -c $CHANNEL_NAME -f ./artifacts/$CHANNEL_NAME/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA_FILE
    # TODO: flag to save $CHANNEL_NAME.block to ./artifacts/$CHANNEL_NAME/ path

    peer channel join -b $CHANNEL_NAME.block #Join peer to channel
    # N.B. peer that actually joined is based on set ENV variables (peer0.org1)
    # Must swap out all the variables to join peer1 and org2 peers to network...

    ## See fabric-samples/first-network/scripts/script.sh
    # for reference as to how these ENV variables are changed in the tutorial script

    ## p0o1
    # export CORE_PEER_LOCALMSPID="Org1MSP"
    # export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/crypto/peerOrganizations/org1.scratch.com/peers/peer0.org1.scratch.com/tls/ca.crt
    # export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/crypto/peerOrganizations/org1.scratch.com/users/Admin@org1.scratch.com/msp
    # export CORE_PEER_ADDRESS=peer0.org1.scratch.com:7051

    ## p1o1
    # export CORE_PEER_LOCALMSPID="Org1MSP"
    # export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/crypto/peerOrganizations/org1.scratch.com/peers/peer0.org1.scratch.com/tls/ca.crt
    # export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/crypto/peerOrganizations/org1.scratch.com/users/Admin@org1.scratch.com/msp
    # export CORE_PEER_ADDRESS=peer1.org1.scratch.com:7051

    ## p0o2
    export CORE_PEER_LOCALMSPID="Org2MSP"
    echo $CORE_PEER_LOCALMSPID
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/crypto/peerOrganizations/org2.scratch.com/peers/peer0.org2.scratch.com/tls/ca.crt
    echo $CORE_PEER_TLS_ROOTCERT_FILE
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/crypto/peerOrganizations/org2.scratch.com/users/Admin@org2.scratch.com/msp
    echo $CORE_PEER_MSPCONFIGPATH
    export CORE_PEER_ADDRESS=peer0.org2.scratch.com:7051
    echo $CORE_PEER_ADDRESS
    peer channel join -b $CHANNEL_NAME.block

    ## ERR: “Expected MSP ID Org1MSP, received Org2MSP”
    # TODO: inquire on chat.
