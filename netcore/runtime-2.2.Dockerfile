FROM ghcr.io/fj0r/io:__dropbear__ AS dropbear
FROM mcr.microsoft.com/dotnet/core/aspnet:2.2
COPY --from=dropbear / /
WORKDIR /app
EXPOSE 80
ENV TIMEZONE=Asia/Shanghai
RUN set -eux \
  ; cp /etc/apt/sources.list /etc/apt/sources.list.bak \
  ; sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list \
  ; sed -i 's|security.debian.org|archive.debian.org/debian-security/|g' /etc/apt/sources.list \
  ; sed -i '/stretch-updates/d' /etc/apt/sources.list \
  ; apt-get update \
  ; apt-get upgrade -y \
  ; DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
      ca-certificates curl jq net-tools inetutils-ping procps tcpdump \
  ; ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
  ; echo "$TIMEZONE" > /etc/timezone \
  ; mkdir -p /etc/dropbear \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY start.sh /
WORKDIR /app
ENTRYPOINT ["/start.sh"]
