# PHP Base Image

[![Docker Build](https://github.com/clevyr/docker-php/actions/workflows/docker.yml/badge.svg)](https://github.com/clevyr/docker-php/actions/workflows/docker.yml)

An enhanced version of the default [PHP Docker image](https://hub.docker.com/_/php) which can install PHP extensions without requiring manual dependency installation using [mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer) and installs a default nginx setup.

## Pull Command

The following command will retrieve an image with PHP 8.5 and Composer v2:

```sh
docker pull ghcr.io/clevyr/php:8.5
```

## Runtime Configuration

The following variables can be configured at build (Typically with an `ARG` in the `Dockerfile`) or during runtime (With environment variables).

### PHP Configuration

Some php.ini values can be configured as a build arg.

| Build Arg                 | Description                                                                                              | Default |
|---------------------------|----------------------------------------------------------------------------------------------------------|---------|
| `PHP_MAX_EXECUTION_TIME`  | See [`max_execution_time`](https://www.php.net/manual/en/info.configuration.php#ini.max-execution-time). | `30`    |
| `PHP_MAX_INPUT_VARS`      | See [`max_input_vars`](https://www.php.net/manual/en/info.configuration.php#ini.max-input-vars).         | `1000`  |
| `PHP_MEMORY_LIMIT`        | See [`memory_limit`](https://www.php.net/manual/en/ini.core.php#ini.memory-limit).                       | `256M`  |
| `PHP_POST_MAX_SIZE`       | See [`post_max_size`](https://www.php.net/manual/en/ini.core.php#ini.post-max-size).                     | `32M`   |
| `PHP_UPLOAD_MAX_FILESIZE` | See [`upload_max_filesize`](https://www.php.net/manual/en/ini.core.php#ini.upload-max-filesize).         | `8M`    |
| `PHP_MAX_FILE_UPLOADS`    | See [`max_file_uploads`](https://www.php.net/manual/en/ini.core.php#ini.max-file-uploads).               | `20`    |

### PHP-FPM Configuration

| Environment Variable           | Description                                                                                                     | Default |
|--------------------------------|-----------------------------------------------------------------------------------------------------------------|---------|
| `PHP_FPM_PM_MAX_CHILDREN`      | See [`pm.max_children`](https://www.php.net/manual/en/install.fpm.configuration.php#pm.max-children).           | `80`    |
| `PHP_FPM_PM_START_SERVERS`     | See [`pm.start_servers`](https://www.php.net/manual/en/install.fpm.configuration.php#pm.start-servers).         | `2`     |
| `PHP_FPM_PM_MIN_SPARE_SERVERS` | See [`pm.min_spare_servers`](https://www.php.net/manual/en/install.fpm.configuration.php#pm.min-spare-servers). | `1`     |
| `PHP_FPM_PM_MAX_SPARE_SERVERS` | See [`pm.max_spare_servers`](https://www.php.net/manual/en/install.fpm.configuration.php#pm.max-spare-servers). | `3`     |
| `PHP_FPM_PM_MAX_REQUESTS`      | See [`pm.max_requests`](https://www.php.net/manual/en/install.fpm.configuration.php#pm.max-requests).           | `0`     |

## Build Arguments

The following variables can be only be configured at build.

| Build Arg          | Description                                                                                                                                         |
|--------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `INSTALL`          | PHP extensions to install. See [here](https://github.com/mlocati/docker-php-extension-installer#supported-php-extensions) for available extensions. |
| `DEPS`             | `apk` dependencies to install during the build.                                                                                                     |

### Nginx Configuration

Some nginx values can be configured as a build arg.

| Build Arg       | Nginx Directive                                                               | Default       |
|-----------------|-------------------------------------------------------------------------------|---------------|
| `NGINX_ROOT`    | [root](http://nginx.org/en/docs/http/ngx_http_core_module.html#root)          | `/app/public` |
| `NGINX_EXPIRES` | [expires](http://nginx.org/en/docs/http/ngx_http_headers_module.html#expires) | `7d`          |

### Legacy Build Arguments

These are the legacy build args. They will still be supported for the forseeable future, but they are not as powerful as the new `INSTALL` build arg, so if you are creating an app from scratch, the `INSTALL` build arg may be more useful for you. These are also convenient because they group up some extensnions. For example, if you set `INSTALL_MYSQL=true`, then both `mysqli` and `pdo_mysql` will be installed.

| Build Arg           | Default   |
|---------------------|-----------|
| `INSTALL_BCMATH`    | `true`    |
| `INSTALL_CALENDAR`  | `false`   |
| `INSTALL_EXIF`      | `false`   |
| `INSTALL_GD`        | `true`    |
| `INSTALL_IMAGICK`   | `false`   |
| `INSTALL_INTL`      | `false`   |
| `INSTALL_PCNTL`     | `false`   |
| `INSTALL_MOSQUITTO` | `false`   |
| `INSTALL_MYSQL`     | `false`   |
| `INSTALL_PGSQL`     | `true`    |
| `INSTALL_REDIS`     | `false`   |
| `INSTALL_XDEBUG`    | `false`   |
| `INSTALL_ZIP`       | `false`   |
