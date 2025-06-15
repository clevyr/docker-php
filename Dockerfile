#syntax=docker/dockerfile:1

ARG PHP_VERSION
ARG COMPOSER_VERSION
ARG ALPINE_VERSION

FROM composer:$COMPOSER_VERSION AS local-composer

FROM php:$PHP_VERSION-fpm-alpine$ALPINE_VERSION AS base
WORKDIR /app

COPY --from=mlocati/php-extension-installer:2.7.24 /usr/bin/install-php-extensions /usr/bin/

RUN <<EOT
  set -eux
  apk add --no-cache bash fcgi gettext git jq nginx postgresql-client s6 su-exec
  install-php-extensions bcmath calendar exif intl pcntl opcache pgsql pdo_pgsql redis zip
  cd "$PHP_INI_DIR"
  sed -ri -e 's/^(access.log)/;\1/' ../php-fpm.d/docker.conf
  sed -ri \
    -e 's/^;(ping\.path)/\1/' \
    -e 's/^;(pm\.status_path)/\1/' \
    -e 's/^;?(pm\.max_children).*/\1 = ${PHP_FPM_PM_MAX_CHILDREN}/' \
    -e 's/^;?(pm\.start_servers).*/\1 = ${PHP_FPM_PM_START_SERVERS}/' \
    -e 's/^;?(pm\.min_spare_servers).*/\1 = ${PHP_FPM_PM_MIN_SPARE_SERVERS}/' \
    -e 's/^;?(pm\.max_spare_servers).*/\1 = ${PHP_FPM_PM_MAX_SPARE_SERVERS}/' \
    -e 's/^;?(pm\.max_requests).*/\1 = ${PHP_FPM_PM_MAX_REQUESTS}/' \
    ../php-fpm.d/www.conf
  sed -ri \
      -e 's/^;?(max_execution_time).*/\1 = ${PHP_MAX_EXECUTION_TIME}/' \
      -e 's/^;?(max_input_vars).*/\1 = ${PHP_MAX_INPUT_VARS}/' \
      -e 's/^;?(memory_limit).*/\1 = ${PHP_MEMORY_LIMIT}/' \
      -e 's/^;?(post_max_size).*/\1 = ${PHP_POST_MAX_SIZE}/' \
      -e 's/^;?(upload_max_filesize).*/\1 = ${PHP_UPLOAD_MAX_FILESIZE}/' \
      -e 's/^;?(max_file_uploads).*/\1 = ${PHP_MAX_FILE_UPLOADS}/' \
      -e 's/^;?(expose_php).*/\1 = Off/' \
      php.ini-production
  ln -s php.ini-production php.ini
  mkdir -p /run/nginx
  sed -ri -e 's/#(tcp_nopush on;)/\1/' /etc/nginx/nginx.conf
  if [ -d /etc/nginx/http.d ]; then
    mv /etc/nginx/http.d /etc/nginx/conf.d
    sed -ri \
      -e 's|/etc/nginx/http.d|/etc/nginx/conf.d|' \
      -e 's|^include /etc/nginx/conf.d/\*.conf;||' \
      /etc/nginx/nginx.conf
  fi
EOT

ENV LC_ALL=C

ARG PHP_FPM_PM_MAX_CHILDREN=80
ENV PHP_FPM_PM_MAX_CHILDREN=$PHP_FPM_PM_MAX_CHILDREN
ARG PHP_FPM_PM_START_SERVERS=2
ENV PHP_FPM_PM_START_SERVERS=$PHP_FPM_PM_START_SERVERS
ARG PHP_FPM_PM_MIN_SPARE_SERVERS=1
ENV PHP_FPM_PM_MIN_SPARE_SERVERS=$PHP_FPM_PM_MIN_SPARE_SERVERS
ARG PHP_FPM_PM_MAX_SPARE_SERVERS=3
ENV PHP_FPM_PM_MAX_SPARE_SERVERS=$PHP_FPM_PM_MAX_SPARE_SERVERS
ARG PHP_FPM_PM_MAX_REQUESTS=0
ENV PHP_FPM_PM_MAX_REQUESTS=$PHP_FPM_PM_MAX_REQUESTS

ARG PHP_MAX_EXECUTION_TIME=30
ENV PHP_MAX_EXECUTION_TIME=$PHP_MAX_EXECUTION_TIME
ARG PHP_MAX_INPUT_VARS=1000
ENV PHP_MAX_INPUT_VARS=$PHP_MAX_INPUT_VARS
ARG PHP_MEMORY_LIMIT=256M
ENV PHP_MEMORY_LIMIT=$PHP_MEMORY_LIMIT
ARG PHP_POST_MAX_SIZE=32M
ENV PHP_POST_MAX_SIZE=$PHP_POST_MAX_SIZE
ARG PHP_UPLOAD_MAX_FILESIZE=8M
ENV PHP_UPLOAD_MAX_FILESIZE=$PHP_UPLOAD_MAX_FILESIZE
ARG PHP_MAX_FILE_UPLOADS=20
ENV PHP_MAX_FILE_UPLOADS=$PHP_MAX_FILE_UPLOADS

ARG COMPOSER_MEMORY_LIMIT=-1
ENV COMPOSER_MEMORY_LIMIT=$COMPOSER_MEMORY_LIMIT

ARG COMPOSER_VERSION
COPY --from=local-composer /usr/bin/composer /usr/bin/composer
RUN <<EOT
  set -eux
  if [ "$COMPOSER_VERSION" = "1" ]; then
    composer global require hirak/prestissimo
    composer clear-cache
  fi
EOT

COPY --from=ghcr.io/roadrunner-server/roadrunner:2025.1.2 /usr/bin/rr /usr/local/bin/rr
COPY rootfs/ /

CMD ["s6-svscan", "/etc/services.d"]

FROM base AS onbuild

ONBUILD ARG PHP_FPM_PM_MAX_CHILDREN
ONBUILD ENV PHP_FPM_PM_MAX_CHILDREN=${PHP_FPM_PM_MAX_CHILDREN:-20}
ONBUILD ARG PHP_FPM_PM_START_SERVERS
ONBUILD ENV PHP_FPM_PM_START_SERVERS=${PHP_FPM_PM_START_SERVERS:-2}
ONBUILD ARG PHP_FPM_PM_MIN_SPARE_SERVERS
ONBUILD ENV PHP_FPM_PM_MIN_SPARE_SERVERS=${PHP_FPM_PM_MIN_SPARE_SERVERS:-1}
ONBUILD ARG PHP_FPM_PM_MAX_SPARE_SERVERS
ONBUILD ENV PHP_FPM_PM_MAX_SPARE_SERVERS=${PHP_FPM_PM_MAX_SPARE_SERVERS:-3}
ONBUILD ARG PHP_FPM_PM_MAX_REQUESTS
ONBUILD ENV PHP_FPM_PM_MAX_REQUESTS=${PHP_FPM_PM_MAX_REQUESTS:-0}

ONBUILD ARG PHP_MAX_EXECUTION_TIME
ONBUILD ENV PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME:-30}
ONBUILD ARG PHP_MAX_INPUT_VARS
ONBUILD ENV PHP_MAX_INPUT_VARS=${PHP_MAX_INPUT_VARS:-1000}
ONBUILD ARG PHP_MEMORY_LIMIT
ONBUILD ENV PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-256M}
ONBUILD ARG PHP_POST_MAX_SIZE
ONBUILD ENV PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE:-32M}
ONBUILD ARG PHP_UPLOAD_MAX_FILESIZE
ONBUILD ENV PHP_UPLOAD_MAX_FILESIZE=${PHP_UPLOAD_MAX_FILESIZE:-8M}
ONBUILD ARG PHP_MAX_FILE_UPLOADS
ONBUILD ENV PHP_MAX_FILE_UPLOADS=${PHP_MAX_FILE_UPLOADS:-20}

ONBUILD ARG SKIP_BUILD
ONBUILD ARG DEPS
ONBUILD ARG INSTALL

ONBUILD ARG INSTALL_GD
ONBUILD ARG INSTALL_IMAGICK
ONBUILD ARG INSTALL_MOSQUITTO
ONBUILD ARG INSTALL_MYSQL
ONBUILD ARG INSTALL_SQLSRV
ONBUILD ARG INSTALL_XDEBUG

ONBUILD ARG NGINX_ROOT
ONBUILD ARG NGINX_EXPIRES

ONBUILD ARG COMPOSER_VERSION

ONBUILD ARG IPE_GD_WITHOUTAVIF=1

ONBUILD RUN <<EOT
  set -eux
  if [ "${SKIP_BUILD:-}" != "true" ]; then
    clevyr-build
  fi
EOT
