FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    # build toolchain
    build-essential \
    make \
    # MySQL client library + headers (-lmysqlclient, -I/usr/include/mysql)
    libmysqlclient-dev \
    mysql-client \
    # Lua 5.1 runtime + headers (-llua5.1, -I/usr/include/lua5.1)
    lua5.1 \
    liblua5.1-dev \
    # zlib (-lz)
    zlib1g-dev \
    # crypt (-lcrypt)
    libcrypt-dev \
    # process supervisor for running all three servers in one container
    supervisor \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/RTK

COPY docker/supervisord.conf /etc/supervisor/conf.d/rtk.conf
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
