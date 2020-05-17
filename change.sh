#!/bin/bash

CONSENSUS="$1"

if [ $CONSENSUS = "poet" ]; then
    docker exec sawtooth-validator bash -c '
        if [ -e /pbft-shared/validators/validator.priv ]; then
          cp /pbft-shared/validators/validator.pub /etc/sawtooth/keys/validator.pub
          cp /pbft-shared/validators/validator.priv /etc/sawtooth/keys/validator.priv
        fi &&
        if [ ! -e /etc/sawtooth/keys/validator.priv ]; then
          sawadm keygen
          mkdir -p /pbft-shared/validators || true
          cp /etc/sawtooth/keys/validator.pub /pbft-shared/validators/validator.pub
          cp /etc/sawtooth/keys/validator.priv /pbft-shared/validators/validator.priv
        fi &&
        if [ ! -e config-genesis.batch ]; then
          sawset genesis -k /etc/sawtooth/keys/validator.priv -o config-genesis.batch
        fi &&
        while [[ ! -f /pbft-shared/validators/validator-1.pub || \
                 ! -f /pbft-shared/validators/validator-2.pub || \
                 ! -f /pbft-shared/validators/validator-3.pub || \
                 ! -f /pbft-shared/validators/validator-4.pub ]];
        do sleep 1; done;
        echo sawtooth.consensus.pbft.members=\\['\"'$$(cat /pbft-shared/validators/validator.pub)'\"','\"'$$(cat /pbft-shared/validators/validator-1.pub)'\"','\"'$$(cat /pbft-shared/validators/validator-2.pub)'\"','\"'$$(cat /pbft-shared/validators/validator-3.pub)'\"','\"'$$(cat /pbft-shared/validators/validator-4.pub)'\"'\\] &&
        if [ ! -e config.batch ]; then
         sawset proposal create \
            -k /etc/sawtooth/keys/validator.priv \
            sawtooth.consensus.algorithm.name=pbft \
            sawtooth.consensus.algorithm.version=1.0 \
            sawtooth.consensus.pbft.members=\\['\"'$$(cat /pbft-shared/validators/validator.pub)'\"','\"'$$(cat /pbft-shared/validators/validator-1.pub)'\"','\"'$$(cat /pbft-shared/validators/validator-2.pub)'\"','\"'$$(cat /pbft-shared/validators/validator-3.pub)'\"','\"'$$(cat /pbft-shared/validators/validator-4.pub)'\"'\\] \
            sawtooth.publisher.max_batches_per_block=1200 \
            -o config.batch
        fi &&
        if [ ! -e /var/lib/sawtooth/genesis.batch ]; then
          sawadm genesis config-genesis.batch config.batch
        fi &&
        if [ ! -e /root/.sawtooth/keys/my_key.priv ]; then
          sawtooth keygen my_key
        fi &&
        sawtooth-validator -vv \
          --bind consensus:tcp://eth0:5050 \
          --scheduler parallel \
                  --peering static \
          --maximum-peer-connectivity 10000'
fi;

if [ $CONSENSUS = "devmode" ]; then
    docker exec sawtooth-shell-default bash -c '
        sawset proposal create -k /etc/sawtooth/keys/validator.priv \
        sawtooth.consensus.algorithm.name=Devmode \
        sawtooth.consensus.algorithm.version=0.1 \
        -o config.batch'
fi;


if [ $CONSENSUS = "raft" ]; then
    docker exec sawtooth-validator bash -c '
        sawset proposal create --url http://ec2-34-207-173-85.compute-1.amazonaws.com:8008 -k /etc/sawtooth/keys/validator.priv \
        sawtooth.consensus.algorithm.name=raft \
        sawtooth.consensus.algorithm.version=0.1 \
        sawtooth.consensus.raft.peers=["$(cat /etc/sawtooth/keys/validator.pub)"] && \
        sawtooth-validator -vv \
          --endpoint tcp://validator:8800 \
          --bind consensus:tcp://eth0:5050 \
          --bind network:tcp://eth0:8800 \
          --peering static
        '
fi;


docker exec sawtooth-validator bash -c '
$(cat /pbft-shared/validators/validator-2.pub)' 
