ARG PHP_VERSION=8.5
FROM php:${PHP_VERSION}-fpm-alpine

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

RUN install-php-extensions \
  bcmath \
  exif \
  gd \
  intl \
  mbstring \
  mysqli \
  opcache \
  pcntl \
  pdo_mysql \
  redis \
  zip

RUN apk add --no-cache bash curl git icu-data-full libwebp-tools shadow unzip zip

ARG PUID=1000
ARG PGID=1000

RUN usermod -u "${PUID}" www-data && groupmod -g "${PGID}" www-data

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

EXPOSE 9000
CMD ["php-fpm"]
