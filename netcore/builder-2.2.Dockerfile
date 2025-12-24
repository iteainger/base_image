ARG CSPROJ=2.2.csproj
FROM mcr.microsoft.com/dotnet/core/sdk:2.2-slim

WORKDIR /src
COPY ${CSPORJ} /src
RUN set -eux \
  ; cat /etc/hosts \
  ; dotnet restore ${CSPROJ}
