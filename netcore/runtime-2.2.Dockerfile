FROM ghcr.io/fj0r/io:__dropbear__ AS dropbear
FROM mcr.microsoft.com/dotnet/core/aspnet:2.2
COPY --from=dropbear / /
WORKDIR /app
EXPOSE 80
ENV TIMEZONE=Asia/Shanghai
RUN set -eux \
ocps tcpdump \
  ; ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
  ; echo "$TIMEZONE" > /etc/timezone \
  ; mkdir -p /etc/dropbear \
  ;

COPY start.sh /
WORKDIR /app
ENTRYPOINT ["/start.sh"]
