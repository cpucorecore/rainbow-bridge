#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Exit script as soon as a command fails.
set -o errexit

# Executes cleanup function at script exit.
trap cleanup EXIT

waitport() {
    while ! nc -z localhost $1 ; do sleep 1 ; done
}

cleanup() {
    # Kill the nearnode instance that we started (if we started one and if it's still running).
    if [ -n "$node_started" ]; then
        docker kill nearcore watchtower > /dev/null &
    fi
    
    # Kill the ganache instance that we started (if we started one and if it's still running).
    if [ -n "$ganache_pid" ] && ps -p $ganache_pid > /dev/null; then
        kill $ganache_pid
    fi
}

nearnode_port=24567

nearnode_running() {
    nc -z localhost "$nearnode_port"
}

start_nearnode() {
    echo "nearrelay" | "$DIR/start_localnet.py" --home "$DIR/.near" --image "nearprotocol/nearcore:ethdenver"
    waitport $nearnode_port
}

if nearnode_running; then
    echo "Using existing nearnode instance"
else
    echo "Starting our own nearnode instance"
    rm -rf "$DIR/.near"
    start_nearnode
    node_started=1
fi

ganache_port=9545

ganache_running() {
    nc -z localhost "$ganache_port"
}

start_ganache() {
    local accounts=(
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501200,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501201,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501202,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501203,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501204,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501205,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501206,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501207,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501208,1000000000000000000000000"
        --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501209,1000000000000000000000000"
    )

    yarn run ganache-cli --blockTime 12 --gasLimit 10000000 -p "$ganache_port" "${accounts[@]}" > /dev/null &
    ganache_pid=$!
    waitport $ganache_port
}

if ganache_running; then
    echo "Using existing ganache instance"
else
    echo "Starting our own ganache instance"
    start_ganache
fi

NEAR_BRIDGE_OWNER_PRIVATE_KEY=0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501200 \
    NEAR_NODE_URL="http://localhost:3030" \
    NEAR_NODE_NETWORK_ID=local \
    ETHEREUM_NODE_URL="http://localhost:9545" \
    node "$DIR/../index.js" &

# Successfully stop after 5m
sleep 300 && kill -0 $$ && echo "Successfully worked for 5m, stopped"