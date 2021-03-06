ARG PHP_VERSION=8.0
ARG ALPINE_VERSION=3.12
FROM php:$PHP_VERSION-fpm-alpine$ALPINE_VERSION

ENV LC_ALL=C

WORKDIR /app

RUN set -x \
    && apk add --no-cache \
        bash \
        fcgi \
        gettext \
        git \
        jq \
        nginx \
        s6 \
        su-exec \
    && cd "$PHP_INI_DIR" \
    && sed -ri \
        -e 's/^(access.log)/;\1/' \
        ../php-fpm.d/docker.conf \
    && sed -ri \
        -e 's/^;(ping\.path)/\1/' \
        -e 's/^;(pm\.status_path)/\1/' \
        -e 's/^;?(pm\.max_children).*/\1 = ${PHP_FPM_PM_MAX_CHILDREN}/' \
        -e 's/^;?(pm\.start_servers).*/\1 = ${PHP_FPM_PM_START_SERVERS}/' \
        -e 's/^;?(pm\.min_spare_servers).*/\1 = ${PHP_FPM_PM_MIN_SPARE_SERVERS}/' \
        -e 's/^;?(pm\.max_spare_servers).*/\1 = ${PHP_FPM_PM_MAX_SPARE_SERVERS}/' \
        -e 's/^;?(pm\.max_requests).*/\1 = ${PHP_FPM_PM_MAX_REQUESTS}/' \
        ../php-fpm.d/www.conf \
    && sed -ri \
        -e 's/^;?(max_execution_time).*/\1 = ${PHP_MAX_EXECUTION_TIME}/' \
        -e 's/^;?(max_input_vars).*/\1 = ${PHP_MAX_INPUT_VARS}/' \
        -e 's/^;?(memory_limit).*/\1 = ${PHP_MEMORY_LIMIT}/' \
        -e 's/^;?(post_max_size).*/\1 = ${PHP_POST_MAX_SIZE}/' \
        -e 's/^;?(upload_max_filesize).*/\1 = ${PHP_UPLOAD_MAX_FILESIZE}/' \
        -e 's/^;?(max_file_uploads).*/\1 = ${PHP_MAX_FILE_UPLOADS}/' \
        -e 's/^;?(expose_php).*/\1 = Off/' \
        php.ini-production \
    && ln -s php.ini-production php.ini \
    && mkdir /run/nginx \
    && sed -ri \
        -e 's/#(tcp_nopush on;)/\1/' \
        /etc/nginx/nginx.conf \
    && sed -ri \
        -e '$ s/(})/    application\/wasm wasm;\n\1/' \
        /etc/nginx/mime.types

COPY --from=composer:1 /usr/bin/composer /usr/bin/composer1
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer2
RUN ln -s composer2 /usr/bin/composer
ARG COMPOSER_MEMORY_LIMIT=-1
ENV COMPOSER_MEMORY_LIMIT=$COMPOSER_MEMORY_LIMIT

COPY --from=clevyr/prestissimo /tmp /root/.composer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

COPY rootfs/ /

ENV XDEBUG_MODE="debug"
ENV XDEBUG_CONFIG="client_host=host.docker.internal client_port=9000 start_with_request=trigger log_level=0"

CMD ["s6-svscan", "/etc/services.d"]

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

ONBUILD ARG INSTALL_BCMATH
ONBUILD ARG INSTALL_CALENDAR
ONBUILD ARG INSTALL_EXIF
ONBUILD ARG INSTALL_GD
ONBUILD ARG INSTALL_IMAGICK
ONBUILD ARG INSTALL_INTL
ONBUILD ARG INSTALL_MOSQUITTO
ONBUILD ARG INSTALL_MYSQL
ONBUILD ARG INSTALL_OPCACHE
ONBUILD ARG INSTALL_PGSQL
ONBUILD ARG INSTALL_REDIS
ONBUILD ARG INSTALL_SQLSRV
ONBUILD ARG INSTALL_XDEBUG
ONBUILD ARG INSTALL_ZIP

ONBUILD ARG NGINX_ROOT
ONBUILD ARG NGINX_EXPIRES

ONBUILD ARG COMPOSER_VERSION

ONBUILD RUN \
    if [ "$SKIP_BUILD" != "true" ]; then \
        clevyr-build \
    ; fi
