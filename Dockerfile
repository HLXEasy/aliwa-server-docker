# SPDX-FileCopyrightText: © 2021 Alias Developers
# SPDX-License-Identifier: MIT

FROM alpine:3.14
MAINTAINER yves@alias.cash

RUN apk add \
    bash \
    bc \
    curl \
    dialog \
    git \
    mariadb-client \
    ncurses \
    nodejs \
    npm \
    mc \
    tor

WORKDIR /opt/
ADD entrypoint.sh .
RUN git clone https://github.com/aliascash/alias-sh-rpc-ui.git \
 && mkdir /root/.aliaswallet \
 && cp /opt/alias-sh-rpc-ui/sample_config_daemon/alias.conf /root/.aliaswallet/

RUN git clone https://github.com/dynamiccreator/aliwa-server.git \
 && cd aliwa-server \
 && npm install

ENTRYPOINT ["/opt/entrypoint.sh"]
