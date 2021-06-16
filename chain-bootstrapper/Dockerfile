# SPDX-FileCopyrightText: © 2021 Alias Developers
# SPDX-License-Identifier: MIT

FROM alpine:3.14
MAINTAINER yves@alias.cash

RUN apk add \
    unzip \
    wget

WORKDIR /opt
ADD bootstrap.sh .

VOLUME /alias

ENTRYPOINT ["/opt/bootstrap.sh"]
