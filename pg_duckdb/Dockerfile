ARG BASEIMAGE=ghcr.io/fj0r/0x:pg17_rx
FROM ${BASEIMAGE} as builder-pg_duckdb
ARG PG_VERSION_MAJOR=17

WORKDIR /tmp/pg_duckdb
RUN set -eux \
  ; apt update \
  ; apt install -y --no-install-recommends \
    libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev \
    libssl-dev libxml2-utils xsltproc \
    pkg-config libc++-dev libc++abi-dev libglib2.0-dev \
    libtinfo5 libstdc++-12-dev liblz4-dev \
  \
  ; git clone --depth=1 https://github.com/duckdb/pg_duckdb.git . \
  ; git submodule update --init --recursive \
  ; make -j$(nproc) \
  ; DESTDIR=/out make install \
  \
  ; cd /out/usr \
  ; tar zcvf /tmp/pg_duckdb.tar.gz * \
  ;
