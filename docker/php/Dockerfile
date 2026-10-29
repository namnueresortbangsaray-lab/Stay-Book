FROM composer:2.8 AS composer
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-interaction --prefer-dist --no-progress --optimize-autoloader

FROM node:22-alpine AS assets
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY tailwind.config.js ./
COPY scripts ./scripts
COPY resources ./resources
RUN npm run build

FROM php:8.3-fpm-alpine AS runtime
RUN apk add --no-cache icu-libs libpq libpng libjpeg-turbo freetype sqlite-libs oniguruma su-exec \
    && apk add --no-cache --virtual .build-deps icu-dev postgresql-dev sqlite-dev libpng-dev libjpeg-turbo-dev freetype-dev oniguruma-dev $PHPIZE_DEPS \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) pdo_sqlite pdo_pgsql intl mbstring gd opcache \
    && apk del .build-deps
WORKDIR /var/www/html
COPY . .
COPY --from=composer /app/vendor ./vendor
COPY --from=assets /app/public/build ./public/build
COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-stay-book.ini
COPY docker/php/php-fpm.conf /usr/local/etc/php-fpm.d/zz-stay-book.conf
COPY docker/php/entrypoint.sh /usr/local/bin/stay-book-entrypoint
RUN chmod +x /usr/local/bin/stay-book-entrypoint /var/www/html/bin/console \
    && mkdir -p storage/database storage/app/uploads storage/backups storage/sessions storage/logs storage/cache \
    && chown -R www-data:www-data storage
EXPOSE 9000
ENTRYPOINT ["stay-book-entrypoint"]
CMD ["php-fpm", "-F"]
