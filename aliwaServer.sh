#!/bin/bash
# ===========================================================================
#
# SPDX-FileCopyrightText: © 2021 Alias Developers
# SPDX-License-Identifier: MIT
#
# Created: 2021-06-14 HLXEasy
#
# This script can be used to run an ALiWa (ALIAS Light Wallet) server
#
# ===========================================================================
set +x

# Determine own location, cd there and source helper content
ownLocation="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ownLocation}" || exit 1
scriptName=$(basename "$0")
. ./include/helpers_console.sh
_init

# ---------------------------------------------------------------------------
# Show info text and how to use the script
showUsage() {
    echo "
    Usage: ${scriptName} [Options]

    Handle ALiWa server

    Initial execution will just create the configuration file '.env' and exit.
    After that the configuration needs to be completed with the base64 encoded
    private key of the Tor Onion v3 address, which should be used to access
    the ALiWa server.

    The configuration also contains randomly generated credentials to access
    the Alias daemon and the ALiWa database. As long as the Alias daemon
    container is not instantiated, you can modify these credentials if you
    like. If you modify them afterwards, you also need to modify the file
    '/alias/.aliaswallet/alias.conf' on the Alias daemon container.

    Options:
        setupMainnet|setupTestnet
            One of these options must be used initially to define which type
            of ALiWa server you want to run: MAINNET or TESTNET
        start
            Start ALiWa and all required containers
        stop
            Stop ALiWa and all required containers
        clean
            Wipe out the Docker volumes to save disk space a/o prepare for
            a clean new start. Will stop the containers before.
            Note:
            The Docker volume with the blockchain will stay intact.
            Use force-clean to wipe out this volume too.
        force-clean
            Wipe out all Docker volumes. This includes the blockchain volume
            too, so the Bootstrap archive will be downloaded again within
            the next start.
        bootstrap
            Bootstrap ALiWa by using Alias bootstrap archive. Option 'start'
            includes usage of this option.
        logs
            Continuously show container logs. Hit Ctrl-C to stop log output.
            The output will be limited to the last 500 lines, as there might
            be way more log content, which will take a long time to show up
            to the end.
        -h|help
            Show this help.
    "
}

startALiWa() {
    info "Starting ALiWa"
    if docker volume ls | grep -q "${ALIAS_WALLET_VOLUME}" ; then
        info " -> Using existing Docker volume ${ALIAS_WALLET_VOLUME}"
    else
        bootstrapALiWa
    fi
#    if docker volume ls | grep -q "${ALIWA_SERVER_VOLUME}" ; then
#        info " -> Using existing Docker volume ${ALIWA_SERVER_VOLUME}"
#    else
#        info " -> Creating named volume ${ALIWA_SERVER_VOLUME}"
#        docker volume create "${ALIWA_SERVER_VOLUME}"
#    fi
    if docker volume ls | grep -q "${ALIWA_DATABASE_VOLUME}" ; then
        info " -> Using existing Docker volume ${ALIWA_DATABASE_VOLUME}"
    else
        info " -> Creating named volume ${ALIWA_DATABASE_VOLUME}"
        docker volume create "${ALIWA_DATABASE_VOLUME}"
    fi
    info " -> Starting main ALiWa containers"
    info "    Please ignore initial errors during ALiWa server startup!"
    info "    ALiWa will be able to connect as soon as the Alias container has"
    info "    finished it's startup phase, which will take some seconds..."
    info "    You can safely cancel the log output using Ctrl-C"
    docker-compose -f "${DOCKER_COMPOSE_SCRIPT}" up -d && docker-compose -f "${DOCKER_COMPOSE_SCRIPT}" logs --tail=500 -f
    info " -> Done"
}

bootstrapALiWa() {
    info "Bootstrapping ALIAS blockchain"
    info " -> Creating named volume ${ALIAS_WALLET_VOLUME}"
    docker volume create "${ALIAS_WALLET_VOLUME}"
    info " -> Starting bootstrap container"
    info " -> Patience, the download and extraction of 2G would take some time..."
    cd ${ownLocation}/chain-bootstrapper
    docker-compose up -d && docker-compose logs -f
    docker-compose down
    cd - >/dev/null
    info " -> Done"
}

stopALiWa() {
    info "Stopping ALiWa"
    docker-compose -f "${DOCKER_COMPOSE_SCRIPT}" down
    info " -> Done"
}

cleanup() {
    stopALiWa
    info "Removing Docker volumes"
    if docker volume ls | grep -q "${ALIWA_SERVER_VOLUME}" ; then
        info " -> Removing volume ${ALIWA_SERVER_VOLUME}"
        docker volume rm "${ALIWA_SERVER_VOLUME}"
    fi
    if docker volume ls | grep -q "${ALIWA_DATABASE_VOLUME}" ; then
        info " -> Removing volume ${ALIWA_DATABASE_VOLUME}"
        docker volume rm "${ALIWA_DATABASE_VOLUME}"
    fi
}

forceCleanup() {
    cleanup
    if docker volume ls | grep -q "${ALIAS_WALLET_VOLUME}" ; then
        info " -> Removing volume ${ALIAS_WALLET_VOLUME}"
        docker volume rm "${ALIAS_WALLET_VOLUME}"
    fi
}

showLogs() {
    info "Use Ctrl-C to stop log output"
    docker-compose -f "${DOCKER_COMPOSE_SCRIPT}" logs --tail=500 -f
}

if [[ ! -e .env ]] ; then
    case "${1}" in
    setupTestnet)
        # TESTNET settings
        ALIAS_CHAIN_START_SYNC_HEIGHT=765000
        ALIAS_WALLET_RPCPORT=36757
        USE_TESTNET=true
        ;;
    setupMainnet)
        # MAINNET settings
        ALIAS_CHAIN_START_SYNC_HEIGHT=1970000
        ALIAS_WALLET_RPCPORT=36657  # MAINNET
        USE_TESTNET=false
        ;;
    *)
        info "Configuration file '.env' not found, please tell the script if to setup for MAINNET or TESTNET!"
        showUsage
        exit
        ;;
    esac

    # Generate random passwords and put them, onto the configuration file
    randomRPCPassword=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 44 | head -n 1)
    randomMariadbPassword=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 44 | head -n 1)
    randomMariadbRootPassword=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 44 | head -n 1)
    sed -e "s/ALIAS_WALLET_RPCPASSWORD=.*\$/ALIAS_WALLET_RPCPASSWORD=${randomRPCPassword}/g" \
        -e "s/MARIADB_PASSWORD=.*\$/MARIADB_PASSWORD=${randomMariadbPassword}/g" \
        -e "s/MARIADB_ROOT_PASSWORD=.*\$/MARIADB_ROOT_PASSWORD=${randomMariadbRootPassword}/g" \
        -e "s/ALIAS_CHAIN_START_SYNC_HEIGHT=.*\$/ALIAS_CHAIN_START_SYNC_HEIGHT=${ALIAS_CHAIN_START_SYNC_HEIGHT}/g" \
        -e "s/ALIAS_WALLET_RPCPORT=.*\$/ALIAS_WALLET_RPCPORT=${ALIAS_WALLET_RPCPORT}/g" \
        -e "s/USE_TESTNET=.*\$/USE_TESTNET=${USE_TESTNET}/g" \
        aliwa.env > .env

    info "    "
    info " -> Configuration file '${ownLocation}/.env' with random credentials created."
    info "    For now this is ok but if you change them after the alias-wallet container"
    info "    was created, you need to update them inside the container too!"
    info " -> This script will be stopped now as you need to put the base64 encoded"
    info "    private key of your Tor Onion v3 address onto the configuration file."
    info "    Use variable 'TOR_SERVICE_KEY1' there."
    info "    "
    info "    Generate the value like 'cat <your-private-key-file> | base64' and put"
    info "    the result in one line onto the configuration file."
    info "    "
    exit
fi

# Source .env and write chain-bootstrapper/.env with value of USE_TESTNET
. ./.env
if ${USE_TESTNET} ; then
    DOCKER_VOLUME_SUFFIX="-testnet"
    DOCKER_COMPOSE_SCRIPT="docker-compose-testnet.yml"
else
    DOCKER_VOLUME_SUFFIX="-mainnet"
    DOCKER_COMPOSE_SCRIPT="docker-compose-mainnet.yml"
fi
echo "USE_TESTNET=${USE_TESTNET}"                    > chain-bootstrapper/.env
echo "DOCKER_VOLUME_SUFFIX=${DOCKER_VOLUME_SUFFIX}" >> chain-bootstrapper/.env

# Parse command line arguments
while getopts h? option; do
    case ${option} in
    h | ?) showUsage && exit 0 ;;
    esac
done

ALIAS_WALLET_VOLUME="aliwa-server_alias-data${DOCKER_VOLUME_SUFFIX}"
ALIWA_DATABASE_VOLUME="aliwa-server_mariadb-data${DOCKER_VOLUME_SUFFIX}"
ALIWA_SERVER_VOLUME="aliwa-server_aliwa-data${DOCKER_VOLUME_SUFFIX}"

case "${1}" in
start)
    startALiWa
    ;;
bootstrap)
    bootstrapALiWa
    ;;
stop)
    stopALiWa
    ;;
clean)
    cleanup
    info " -> Done"
    ;;
force-clean)
    forceCleanup
    info " -> Done"
    ;;
logs)
    showLogs
    ;;
""|help)
    showUsage
    ;;
*)
    info "Unknown option '$1'"
    showUsage
    ;;
esac
