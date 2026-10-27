# Base layer for the php8 images.
#
# The package set is the one defined by ~/data/docker.io/xy/images/core/deb.nu:21
# (stacks [base dev ssh net db s3 diag file archive network-tools] resolved
# through hub.yaml "stacks.debian"), so this image can replace the xy:deb layer
# while keeping the bash entrypoint instead of the nushell one.
ARG BASEIMAGE=debian:sid-slim
FROM ghcr.io/orbsh/assets:dropbear AS dropbear

FROM ${BASEIMAGE}

EXPOSE 22

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TIMEZONE=Asia/Shanghai

# Same layout as `hub install dropbear` in deb.nu: /usr/local/bin + /usr/local/libexec.
# The binary is compiled with SFTPSERVER_PATH=/usr/libexec/sftp-server.
COPY --from=dropbear / /usr/local/

RUN set -eux \
  ; mkdir -p /usr/libexec \
  ; ln -sf /usr/local/libexec/sftp-server /usr/libexec/sftp-server \
  ; apt-get update \
  ; apt-get upgrade -y \
  ; DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
      sudo attr procps htop cron tzdata \
      openssh-client s3fs \
      curl ca-certificates rsync \
      strace tcpdump socat lsof \
      patch tree \
      xz-utils zstd zip unzip \
      inetutils-ping iproute2 net-tools nftables iptables \
      sqlite3 \
  ; ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
  ; echo "$TIMEZONE" > /etc/timezone \
  ; sed -i -e 's/^.*\(%sudo.*\)ALL$/\1NOPASSWD:ALL/g' \
      -e 's!^Defaults[[:space:]]*secure_path=.*!Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"!' \
      /etc/sudoers \
  ; apt-get autoremove -y \
  ; apt-get clean -y \
  ; rm -rf /var/lib/apt/lists/* \
  ;