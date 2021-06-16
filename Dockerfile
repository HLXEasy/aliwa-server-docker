# SPDX-FileCopyrightText: © 2021 Alias Developers
# SPDX-License-Identifier: MIT

FROM alpine:3.14
MAINTAINER yves@alias.cash

RUN apk add \
    bash \
    git \
    mariadb-client \
    nodejs \
    npm \
    mc

WORKDIR /opt/
ADD entrypoint.sh .
RUN git clone https://github.com/dynamiccreator/aliwa-server.git \
 && cd aliwa-server \
 && npm install

ENTRYPOINT ["/opt/entrypoint.sh"]
