FROM mcr.microsoft.com/dotnet/core/sdk:2.2
ARG CSPROJ=FMS_API_Core.Web/FMS_API_Core.Web.csproj

WORKDIR /src
COPY csproj /src
RUN set -eux \
  ; cat /etc/hosts \
  ; dotnet restore ${CSPROJ}
