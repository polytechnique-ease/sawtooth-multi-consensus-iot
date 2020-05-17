#!/bin/bash

CONSENSUS="$1"

if [ $CONSENSUS = "poet" ]; then
    docker exec sawtooth-validator bash -c '
        sawadm keygen --force && \
        mkdir -p /poet-shared/validator-0 || true && \
        cp -a /etc/sawtooth/keys /poet-shared/validator-0/ && \
        while [ ! -f /poet-shared/poet-enclave-measurement ]; do sleep 1; done && \
        while [ ! -f /poet-shared/poet-enclave-basename ]; do sleep 1; done && \
        while [ ! -f /poet-shared/poet.batch ]; do sleep 1; done && \
        cp /poet-shared/poet.batch / && \
        sawset genesis \
          -k /etc/sawtooth/keys/validator.priv \
          -o config-genesis.batch && \
        sawset proposal create \
          -k /etc/sawtooth/keys/validator.priv \
          sawtooth.consensus.algorithm.name=PoET \
          sawtooth.consensus.algorithm.version=0.1 \
          sawtooth.poet.report_public_key_pem="$(cat /poet-shared/simulator_rk_pub.pem)" \
          sawtooth.poet.valid_enclave_measurements=$(cat /poet-shared/poet-enclave-measurement) \
          -o config.batch && \
        sawset proposal create \
          -k /etc/sawtooth/keys/validator.priv \
             sawtooth.poet.target_wait_time=5 \
             sawtooth.poet.initial_wait_time=25 \
             sawtooth.publisher.max_batches_per_block=100 \
          -o poet-settings.batch 
          -o poet-settings.batch && \
        sawadm genesis \
          config-genesis.batch config.batch poet.batch poet-settings.batch && \
        sawtooth-validator -v \
          --peering static \
          --endpoint tcp://validator-0:8800 \
          --scheduler parallel \
          --network-auth trust && \
        rm /var/lib/sawtooth/genesis.batch'
fi;

if [ $CONSENSUS = "devmode" ]; then
    docker exec sawtooth-shell-default bash -c '
        sawset proposal create -k /etc/sawtooth/keys/validator.priv \
        sawtooth.consensus.algorithm.name=Devmode \
        sawtooth.consensus.algorithm.version=0.1 \
        -o config.batch'
fi;
