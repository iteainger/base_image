# PHP 8 + ferron 3 layer on top of the deb base layer (see ./deb.Dockerfile).
ARG BASEIMAGE=iteainger/base_image:deb
FROM ${BASEIMAGE}

ARG PHP_VERSION=8.4
ARG ARCH=x86_64

EXPOSE 22 8080

ENV PHP_VERSION=${PHP_VERSION}
ENV PHP_PKGS \
        php${PHP_VERSION} \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-ast \
        php${PHP_VERSION}-xdebug

RUN set -eux \
  ; apt-get update \
  ; apt-get install -y --no-install-recommends $PHP_PKGS jq \
  ; apt-get autoremove -y \
  ; apt-get clean -y \
  ; rm -rf /var/lib/apt/lists/* \
  ;

# ferron 3 is a musl static build; subcommand form is `ferron run --config`.
# Version is not pinned: newest stable 3.x, falling back to the newest 3.x
# prerelease while 3.0 has not shipped (drop the fallback once it has).
RUN set -eux \
  ; ferron_ver=$(curl --retry 3 -fsSL https://api.github.com/repos/ferronweb/ferron/releases | jq -r '[ .[] | select(.tag_name | startswith("3.")) ] as $r3 | ($r3 | map(select(.prerelease == false)) | first) // ($r3 | first) | .tag_name') \
  ; test -n "$ferron_ver" -a "$ferron_ver" != "null" \
  ; echo "ferron ${ferron_ver}" \
  ; ferron_url="https://github.com/ferronweb/ferron/releases/download/${ferron_ver}/ferron-${ferron_ver}-${ARCH}-unknown-linux-musl.tar.gz" \
  ; curl --retry 3 -fsSL ${ferron_url} \
    | tar -xzf - -C /usr/local/bin ferron ferron-fmt ferron-passwd \
  ; /usr/local/bin/ferron version \
  ;

RUN set -eux \
  ; ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm \
  ; sed -e 's!^.*\(date.timezone =\).*$!\1 Asia/Shanghai!' \
        -i /etc/php/${PHP_VERSION}/fpm/php.ini \
  ; sed -e 's!.*\(daemonize =\).*!\1 no!' \
        -e 's!.*\(error_log =\).*!\1 /var/log/php-fpm/fpm.log!' \
        -i /etc/php/${PHP_VERSION}/fpm/php-fpm.conf \
  ; sed -e 's!\(listen =\).*!\1 /var/run/php/php-fpm.sock!' \
        -e 's!.*\(slowlog =\).*$!\1 /var/log/php-fpm/fpm.log.slow!' \
        -e 's!.*\(clear_env =\).*$!\1 no!' \
        -e 's!.*\(pm.start_servers =\).*$!\1 6!' \
        -e 's!.*\(pm.min_spare_servers =\).*$!\1 5!' \
        -e 's!.*\(pm.max_spare_servers =\).*$!\1 10!' \
        -e 's!.*\(pm.max_children =\).*$!\1 10!' \
        -i /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf \
  ; mkdir -p /var/log/php-fpm /var/run/php

# Download the phar with curl (PHP's own stream wrapper chokes on the proxy and
# truncates the archive: "Failed to decode zlib stream").
RUN set -eux \
  ; curl --retry 3 -fsSL https://getcomposer.org/download/latest-stable/composer.phar \
    -o /usr/local/bin/composer \
  ; chmod +x /usr/local/bin/composer \
  ; composer --version \
  ;

COPY ferron.conf /etc/ferron.conf
COPY setup-php /setup-php
COPY index.php /srv/
COPY entrypoint /entrypoint/

RUN set -eux \
  ; chmod +x /entrypoint/*.sh /setup-php \
  ;

WORKDIR /srv
CMD ["srv"]

ENV DEBUG= \
    DEBUGE= \
    PREBOOT= \
    POSTBOOT= \
    CRONFILE= \
    CONFIGFILE=/etc/ferron.conf \
    PHP_DEBUG= \
    PHP_PROFILE= \
    PHP_TRACE= \
    PHP_DEBUG_IDEKEY= \
    PHP_FPM_SERVERS= \
    UPLOAD_MAX_FILESIZE=

ENTRYPOINT ["/entrypoint/init.sh"]