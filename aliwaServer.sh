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

    Options:
        start 
            Start ALiWa and all required containers
        setup
            Setup ALiWa. Not required as 'start' include this option
        stop
            Stop ALiWa and all required containers
        clean
            Wipe out the Docker volumes to save disk space a/o prepare for
            a clean new start.
        logs
            Continuously show container logs. Hit Ctrl-C to stop log output.
        -h|help
            Show this help.
    "
}

startALiWa() {
    info "Starting ALiWa"
    if docker volume ls | grep -q aliwa-server-docker_alias-data ; then
        info " -> Using existing Docker volume aliwa-server-docker_alias-data"
    else
        setupALiWa
    fi
    info " -> You can safely cancel the log output using Ctrl-C"
    docker-compose up -d && docker-compose logs -f
    info " -> Done"
}

setupALiWa() {
    info "Bootstrapping ALIAS blockchain"
    info " -> You can safely cancel the log output using Ctrl-C"
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
#    if docker volume ls | grep -q aliwa-server-docker_alias-data ; then
#        info " -> Removing volume aliwa-server-docker_alias-data"
#        docker volume rm aliwa-server-docker_alias-data
#    fi
    if docker volume ls | grep -q aliwa-server-docker_aliwa-data ; then
        info " -> Removing volume aliwa-server-docker_aliwa-data"
        docker volume rm aliwa-server-docker_aliwa-data
    fi
    if docker volume ls | grep -q aliwa-server-docker_mariadb-data ; then
        info " -> Removing volume aliwa-server-docker_mariadb-data"
        docker volume rm aliwa-server-docker_mariadb-data
    fi
    info " -> Done"
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
