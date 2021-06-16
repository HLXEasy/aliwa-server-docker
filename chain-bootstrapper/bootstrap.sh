#!/bin/sh
# ===========================================================================
#
# SPDX-FileCopyrightText: © 2021 Alias Developers
# SPDX-License-Identifier: MIT
#
# Created: 2021-06-14 HLXEasy
#
# This script downloads and extracts the ALIAS bootstrap archive onto
# /alias/.aliaswallet/
#
# ===========================================================================
set +x

echo "Creating directories"
mkdir -p /alias/.aliaswallet
cd /alias/

if [[ -e BootstrapChain.zip ]] ; then
    echo "Using existing BootstrapChain.zip"
else
    echo "Downloading bootstrap archive"
    wget \
        --no-verbose \
        --show-progress \
        --progress=dot:giga \
        https://download.alias.cash/files/bootstrap/BootstrapChain.zip
fi

cd .aliaswallet

if [[ -e .aliaswallet/blk0001.dat ]] ; then
    echo "Cleanup existing blockchain data"
    rm -rf .aliaswallet/blk0001.dat
    rm -rf .aliaswallet/txleveldb
fi

echo "Extracting bootstrap archive..."
unzip ../BootstrapChain.zip

echo "All done"
