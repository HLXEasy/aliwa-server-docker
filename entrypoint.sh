#!/bin/bash
# ===========================================================================
#
# SPDX-FileCopyrightText: © 2021 Alias Developers
# SPDX-License-Identifier: MIT
#
# Created: 2021-06-14 HLXEasy
#
# This script initializes and starts the Alias Light Wallet ALiWa
#
# ===========================================================================
set +x

echo "Checking connection to MariaDB"
until mysql -u${MARIADB_USER} -p${MARIADB_PASSWORD} -h aliwa-database -e "quit" 2>/dev/null ; do
    >&2 echo " -> MariaDB is unavailable - sleeping"
    sleep 1
done
echo " -> Connection successful"

cd /opt/aliwa-server
foundTxInputTable=$(mysql -u${MARIADB_USER} -p${MARIADB_PASSWORD} -h aliwa-database -D ${MARIADB_DATABASE} -e "show tables like 'tx_inputs';")
if [[ -z "$foundTxInputTable" ]] ; then
    echo "Creating initial ALiWa tables"
    mysql -u${MARIADB_USER} -p${MARIADB_PASSWORD} -h aliwa-database -D ${MARIADB_DATABASE} < aliwa_server.sql
    echo " -> Done"
else
    echo "ALiWa tables already existing on database, skipping initialization step"
fi

echo "Updating ALiWa configuration"
sed -i \
    -e "s/cnf_host.*\$/cnf_host = \"alias-wallet\"/g" \
    -e "s/cnf_username.*\$/cnf_username = \"${RPCUSER}\"/g" \
    -e "s/cnf_password.*\$/cnf_password = \"${RPCPASSWORD}\"/g" \
    -e "s/cnf_db_host.*\$/cnf_db_host = \"aliwa-database\"/g" \
    -e "s/cnf_db_user.*\$/cnf_db_user = \"${MARIADB_USER}\"/g" \
    -e "s/cnf_db_password.*\$/cnf_db_password = \"${MARIADB_PASSWORD}\"/g" \
    -e "s/cnf_db_database.*\$/cnf_db_database = \"${MARIADB_DATABASE}\"/g" \
    -e "s/cnf_read_block_height.*\$/cnf_read_block_height = ${ALIAS_CHAIN_START_SYNC_HEIGHT}/g" \
    config.js

echo "Updating Shell-UI configuration"
sed -i \
    -e "s/^rpcuser=.*\$/rpcuser=${RPCUSER}/g" \
    -e "s/^rpcpassword=.*\$/rpcpassword=${RPCPASSWORD}/g" \
    -e "s/^rpcconnect=.*\$/rpcconnect=alias-wallet/g" \
    /root/.aliaswallet/alias.conf

node server.js
