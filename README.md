# ALiWa@Docker - Dockerized Alias Light Wallet
[![Latest release](https://img.shields.io/github/v/release/aliascash/docker-aliwa-server?label=Release&color=%2300bf00)](https://github.com/aliascash/docker-aliwa-server/releases/latest)
[![Latest develop build](https://img.shields.io/github/v/release/aliascash/docker-aliwa-server?include_prereleases&label=Develop-Build)](https://github.com/aliascash/docker-aliwa-server/releases)
[![Discord](https://img.shields.io/discord/426769724018524161?logo=discord)](https://discord.gg/ckkrb8m)
[![Reddit](https://img.shields.io/badge/reddit-join-orange?logo=reddit)](https://www.reddit.com/r/AliasCash/)
[![Build Status Master](https://github.com/aliascash/docker-aliwa-server/actions/workflows/build-master.yml/badge.svg)](https://github.com/aliascash/docker-aliwa-server/actions)
[![Build Status Develop](https://github.com/aliascash/docker-aliwa-server/actions/workflows/build-develop.yml/badge.svg)](https://github.com/aliascash/docker-aliwa-server/actions)

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

    Usage: aliwaServer.sh [Options]

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

  ```

As written on the help output, the script will exit on the first run right after the creation of the configuration file `.env`, as this file needs to be updated manually after that.

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




# Social
- Visit our website [Alias](https://alias.cash/) (ALIAS)
- Please join us on our [Discord](https://discord.gg/ckkrb8m) server
- Read the latest [News](https://alias.cash/news/)
- Visit our thread at [BitcoinTalk](https://bitcointalk.org/index.php?topic=2103301.0)

