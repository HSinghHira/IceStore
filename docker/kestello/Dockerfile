# syntax=docker/dockerfile:1.7
#
# Kestello for IceStore: PHP-FPM and nginx in one container, with the
# release zip upstream publishes (github.com/kestellohq/cms/releases).
#
# Upstream ships no image; its docker/ folder is a development setup. This
# image is built the way upstream's docker/Dockerfile is (php-fpm with gd,
# zip, intl, bcmath and the database drivers; no xdebug), and serves the site
# with upstream's nginx rules. The whole site lives in /var/www/html, a
# volume: icestore-init copies the release in on the first start, and
# Kestello's own updater (signed updates) keeps it current after that.
#
# To ship a newer release to new installs, change KESTELLO_VERSION, bump
# AIO_VERSION in build-kestello.yml and rebuild.

ARG KESTELLO_VERSION=0.1.0-rc.1

FROM php:8.5.12-fpm-trixie
ARG KESTELLO_VERSION
ARG DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        nginx supervisor unzip curl ca-certificates \
        libpng-dev libjpeg62-turbo-dev libfreetype6-dev libwebp-dev libavif-dev \
        libzip-dev libicu-dev libonig-dev libpq-dev \
        jpegoptim optipng; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif; \
    docker-php-ext-install -j"$(nproc)" pdo_mysql pdo_pgsql mbstring gd zip intl bcmath; \
    pecl install apcu; \
    docker-php-ext-enable apcu; \
    rm -rf /var/lib/apt/lists/* /tmp/pear; \
    rm -f /etc/nginx/sites-enabled/default

ADD https://github.com/kestellohq/cms/releases/download/v${KESTELLO_VERSION}/kestello-${KESTELLO_VERSION}.zip /tmp/kestello.zip
RUN set -eux; \
    mkdir -p /usr/src; \
    unzip -q /tmp/kestello.zip -d /usr/src; \
    test -f /usr/src/kestello/public/index.php; \
    echo "${KESTELLO_VERSION}" > /usr/src/kestello/.icestore-version; \
    rm /tmp/kestello.zip

COPY php.ini /usr/local/etc/php/conf.d/icestore.ini
COPY nginx.conf /etc/nginx/conf.d/kestello.conf
COPY supervisord.conf /etc/supervisor/icestore.conf
COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="kestello" \
      org.opencontainers.image.description="Kestello CMS (release ${KESTELLO_VERSION}) with PHP-FPM and nginx" \
      org.opencontainers.image.version="${KESTELLO_VERSION}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /var/www/html
VOLUME /var/www/html
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080/ || exit 1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
