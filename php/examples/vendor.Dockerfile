# 业务基础镜像示例：php8 基础镜像 + 预打包的 vendor 包。
#
#   podman build -f vendor.Dockerfile -t myapp-base:latest .
#
# 层级：iteainger/base_image:php（运行环境）→ 本镜像（业务基础镜像，备好 vendor）
# → 业务镜像（COPY 应用代码、把 vendor 接进 /srv）。同一份 vendor 可被多个业务镜像共用。
#
# 这类文件属于业务仓库，这里只作模板。放在 examples/ 下是有意的：x.nu gen 只
# glob 镜像目录根部的 `*Dockerfile`，模板不能和 php/Dockerfile 并列。
ARG BASEIMAGE=ghcr.io/iteainger/base_image:php
FROM ${BASEIMAGE}

ARG VENDOR_URL=http://file.s/vendor.tar.zst

# vendor 解包在 /srv 之外：应用树仍是 COPY/挂载的对象，vendor 自己占一层可缓存。
# 归档顶层就是 `vendor/`，所以 -C /opt 得到 /opt/vendor（若归档自带别的顶层前缀，
# 这里要换成 --strip-components=1）。
#
# 归档是 tar.zst，边下边解：不落临时文件，管道里一次过完。
# 打包命令（在 vendor/ 的上一级执行）：
#   tar -cf - --exclude '.DS_Store' vendor | zstd -T0 -19 -o vendor.tar.zst
# .DS_Store 在打包侧排除；漏排了也不影响运行，镜像里不再处理。
# 不做重试：file.s 偶尔会掐断长传输，那就让构建直接失败（解压侧报 unexpected EOF），
# 不要拿重试掩盖上游问题。
RUN set -eux \
  ; curl -fsSL ${VENDOR_URL} | zstd -dc | tar -xf - -C /opt \
  ; test -d /opt/vendor \
  ;

# 本镜像不含应用代码、也不动 /srv —— 这两件事归业务镜像：
#   FROM myapp-base:latest
#   COPY . /srv/
#   RUN ln -sfn /opt/vendor /srv/vendor
#
# ENTRYPOINT 与 CMD ["srv"] 继承自 iteainger/base_image:php：php-fpm 与 ferron 由
# /entrypoint 拉起，在 :8080 上服务 /srv。