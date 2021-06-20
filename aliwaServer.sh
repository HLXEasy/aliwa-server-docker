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

ALIAS_WALLET_VOLUME="docker-aliwa-server_alias-data"
ALIWA_DATABASE_VOLUME="docker-aliwa-server_mariadb-data"
ALIWA_SERVER_VOLUME="docker-aliwa-server_aliwa-data"

# ---------------------------------------------------------------------------
# Show info text and how to use the script
showUsage() {
    echo "
    Usage: ${scriptName} [Options]

    Handle ALiWa server

    Options:
        start
            Start ALiWa and all required containers
        setup
            Setup ALiWa. Not required as 'start' include this option
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
        logs
            Continuously show container logs. Hit Ctrl-C to stop log output.
        -h|help
            Show this help.
    "
}

startALiWa() {
    info "Starting ALiWa"
    if docker volume ls | grep -q ${ALIAS_WALLET_VOLUME} ; then
        info " -> Using existing Docker volume ${ALIAS_WALLET_VOLUME}"
    else
        setupALiWa
    fi
    info " -> Starting main ALiWa containers"
    info "    Please ignore initial errors during ALiWa server startup!"
    info "    ALiWa will be able to connect as soon as the Alias container has"
    info "    finished it's startup phase, which will take some seconds..."
    info "    You can safely cancel the log output using Ctrl-C"
    docker-compose up -d && docker-compose logs -f
    info " -> Done"
}

setupALiWa() {
    info "Bootstrapping ALIAS blockchain"
    info " -> Creating named volume"
    docker volume create ${ALIAS_WALLET_VOLUME}
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
    docker-compose down
    info " -> Done"
}

cleanup() {
    stopALiWa
    info "Removing Docker volumes"
    if docker volume ls | grep -q ${ALIWA_SERVER_VOLUME} ; then
        info " -> Removing volume ${ALIWA_SERVER_VOLUME}"
        docker volume rm ${ALIWA_SERVER_VOLUME}
    fi
    if docker volume ls | grep -q ${ALIWA_DATABASE_VOLUME} ; then
        info " -> Removing volume ${ALIWA_DATABASE_VOLUME}"
        docker volume rm ${ALIWA_DATABASE_VOLUME}
    fi
}

forceCleanup() {
    cleanup
    if docker volume ls | grep -q ${ALIAS_WALLET_VOLUME} ; then
        info " -> Removing volume ${ALIAS_WALLET_VOLUME}"
        docker volume rm ${ALIAS_WALLET_VOLUME}
    fi
}

showLogs() {
    info "Use Ctrl-C to stop log output"
    docker-compose logs -f
}

if [[ ! -e .env ]] ; then
    info "Configuration file '.env' not found, copying it from template 'aliwa.env'."

    # Generate random password and put it onto the configuration file
    randomRPCPassword=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 44 | head -n 1)
    randomMariadbPassword=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 44 | head -n 1)
    randomMariadbRootPassword=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 44 | head -n 1)
    sed -e "s/ALIAS_WALLET_RPCPASSWORD=.*\$/ALIAS_WALLET_RPCPASSWORD=${randomRPCPassword}/g" \
        -e "s/MARIADB_PASSWORD=.*\$/MARIADB_PASSWORD=${randomMariadbPassword}/g" \
        -e "s/MARIADB_ROOT_PASSWORD=.*\$/MARIADB_ROOT_PASSWORD=${randomMariadbRootPassword}/g" \
        aliwa.env > .env

    info " -> Credentials are randomly created but feel free to update them."
fi

# Parse command line arguments
while getopts h? option; do
    case ${option} in
    h | ?) showUsage && exit 0 ;;
    esac
done

case "${1}" in
start)
    startALiWa
    ;;
setup)
    setupALiWa
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
