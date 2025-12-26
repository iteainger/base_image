FROM ghcr.io/fj0r/0x:php7

WORKDIR /srv

COPY composer.json .

RUN composer install  --no-cache --optimize-autoloader \
    && mv vendor /opt