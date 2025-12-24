FROM mcr.microsoft.com/dotnet/core/sdk:2.2-stretch

WORKDIR /src
COPY 2.2.csproj /src
RUN set -eux \
  ; cat /etc/hosts \
  ; dotnet restore 2.2.csproj
