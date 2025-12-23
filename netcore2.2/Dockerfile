# 使用 .NET Core 2.2 SDK
FROM mcr.microsoft.com/dotnet/core/sdk:2.2 AS base

WORKDIR /packages

# 复制包列表文件
COPY nuget-packages.txt .
COPY packages-restore.sh .

# 设置环境变量
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    NUGET_XMLDOC_MODE=skip

# 恢复所有包（类似 pip install -r requirements.txt）
RUN set -eux \
    ; chmod +x packages-restore.sh \
    ; ./packages-restore.sh \
    ; echo "所有 NuGet 包已安装完成！"

# 工作目录
WORKDIR /app

# 复制应用代码
COPY . .

# 构建应用
RUN set -eux \
    ; echo "开始构建应用..." \
    ; dotnet build FMS_API_Core.sln -c Release \
    ; echo "构建完成！"

# 发布应用
RUN set -eux \
    ; echo "开始发布应用..." \
    ; dotnet publish FMS_API_Core.Web/FMS_API_Core.Web.csproj \
        -c Release \
        -o /app/publish \
        --no-restore \
        --no-build \
    ; echo "发布完成！"

# 运行时镜像
FROM mcr.microsoft.com/dotnet/core/aspnet:2.2 AS runtime

WORKDIR /app

# 设置环境
ENV ASPNETCORE_URLS=http://+:80 \
    ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_RUNNING_IN_CONTAINER=true

# 复制编译结果
COPY --from=base /app/publish .

# 运行应用
ENTRYPOINT ["dotnet", "FMS_API_Core.Web.dll"]