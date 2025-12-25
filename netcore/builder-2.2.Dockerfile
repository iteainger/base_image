FROM mcr.microsoft.com/dotnet/core/sdk:2.2
ARG CSPROJ=2.2.csproj

WORKDIR /src
COPY ${CSPROJ} /src
RUN set -eux \
  ; cat /etc/hosts \
  ; dotnet restore ${CSPROJ}
