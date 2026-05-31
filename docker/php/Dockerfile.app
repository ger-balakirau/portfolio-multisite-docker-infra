ARG BASE_PHP_IMAGE=portfolio-multisite-php:8.5
FROM ${BASE_PHP_IMAGE}

ARG APP_DIR
ARG APP_SOURCE

RUN test -n "${APP_DIR}" && test -n "${APP_SOURCE}"

COPY --chown=www-data:www-data ${APP_SOURCE}/ /var/www/html/${APP_DIR}/

WORKDIR /var/www/html/${APP_DIR}

EXPOSE 9000
CMD ["php-fpm"]
