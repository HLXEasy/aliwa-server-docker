# ALiWa@Docker - Dockerized Alias Light Wallet
[![Latest release](https://img.shields.io/github/v/release/aliascash/docker-aliwa-server?label=Release&color=%2300bf00)](https://github.com/aliascash/docker-aliwa-server/releases/latest)
[![Discord](https://img.shields.io/discord/426769724018524161?logo=discord)](https://discord.gg/ckkrb8m)
[![Reddit](https://img.shields.io/badge/reddit-join-orange?logo=reddit)](https://www.reddit.com/r/AliasCash/)
[![Build Status Master](https://github.com/aliascash/docker-aliwa-server/actions/workflows/build-master.yml/badge.svg)](https://github.com/aliascash/docker-aliwa-server/actions)

Alias is a Secure Proof-of-Stake (PoSv3) Network with Anonymous Transaction Capability.
ALiWa is a light wallet implementation for Alias.

# Licensing

* SPDX-FileCopyrightText: © 2021 Alias Developers
* SPDX-License-Identifier: MIT

## Requirements

* [Docker](https://docs.docker.com/engine/install/)
* [Docker-Compose](https://docs.docker.com/compose/install/)
* The private key for the Tor Onion v3 address, which should be used to contact the server
* Git

## How to use

### Installation and initial run
* Install [Docker](https://docs.docker.com/engine/install/) and [Docker-Compose](https://docs.docker.com/compose/install/)
* Clone this repository
* Start the helper script
  ```
  $ git clone https://github.com/aliascash/docker-aliwa-server
  $ cd docker-aliwa-server
  $ ./aliwaServer.sh
  Info   : Configuration file '.env' not found, please tell the script if 
           to setup for MAINNET or TESTNET!
  
    Usage: aliwaServer.sh [Options]

    Handle ALiWa server

    Initial execution requires usage of option setupMainnet or setupTestnet.
    This will just create the configuration file '.env' and exit.
    After that the configuration needs to be completed with the base64 encoded
    private key of the Tor Onion v3 address, which should be used to access
    the ALiWa server. Example: 'cat hs_ed25519_secret_key | base64'

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

  ```

As written on the help output, the script requires the usage of the option *setupMainnet* or *setupTestnet* to generate the configuration file `.env`. After that the scripts exits, as this file needs to be updated manually after that.

### Configuring Tor hidden service
After the initial run of `aliwaServer.sh` the value of `TOR_SERVICE_KEY1` on the created configuration file `.env` needs to be updated. To do so, the private key from the to-be-used Onion v3 address must be encodet using Base64. The result must be put onto the configuration file **as one line**.

1. Base64 encode private key:
   ```
   cat <your-tor-onionv3-private-key-file> | base64
   ```
   The result might be on two lines. These lines needs to be concatenated onto one line on `.env`
2. Update `.env` file with the result from previous step by replacing the three dots:
   ```
   TOR_SERVICE_KEY1=...
   ```

### Other configuration options
There are multiple other configuration options on `.env`, which could be modified.

One thing to notice: If the Alias daemon was bootstrapped and you change from MAINNET to TESTNET or vica versa, the bootstrapp will not be triggered again! You need to wipe out the Alias daemon Docker volume to trigger a new bootstrap process.

### Start ALiWa server
After the previous steps the ALiWa server is ready to run:
```
$ ./aliwaServer.sh start
```

This will download the required Docker images and start them. In detail the first image will be the [Alias Bootstrapper](https://hub.docker.com/repository/docker/aliascash/docker-aliaswalletd-bootstrapper), which prepares a Docker volume with the bootstrap data for further usage by the [Alias daemon](https://hub.docker.com/repository/docker/aliascash/docker-aliaswalletd). The bootstrap process might take some time as the bootstrap archive with around 2G must be downloaded and extracted. The other images are the [MariaDB database](https://hub.docker.com/_/mariadb), [Tor hidden service](https://hub.docker.com/r/goldy/tor-hidden-service) and the [ALiWa server](https://hub.docker.com/repository/docker/aliascash/docker-aliwa-server) itself.

During the startup there will be some exit's of `aliwa-server` on the log. That's normal as the ALiWa server tries to connect to the Alias daemon, which will work as soon as the daemon is ready to accept RPC commands. Usually this is the case as soon as there is also log output from `alias-daemon`.

Now the ALiWa server is scanning the blockchain starting at the value of `ALIAS_CHAIN_START_SYNC_HEIGHT` on `.env`. How long this sync take depends heavily on the used CPU power and disc I/O.

# Social
- Visit our website [Alias](https://alias.cash/) (ALIAS)
- Please join us on our [Discord](https://discord.gg/ckkrb8m) server
- Read the latest [News](https://alias.cash/news/)
- Visit our thread at [BitcoinTalk](https://bitcointalk.org/index.php?topic=2103301.0)

