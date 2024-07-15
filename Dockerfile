FROM php:8.1-apache

# install the PHP extensions we need
RUN set -ex; \
  \
  apt-get update; \
  apt-get install -y \
    libzip-dev \
    libicu-dev \
    libpng-dev \
    libxml2-dev \
    zlib1g-dev \
  ; \
  rm -rf /var/lib/apt/lists/*; \
  \
  docker-php-ext-install gd mysqli opcache intl soap zip exif

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
# see https://docs.moodle.org/36/en/OPcache
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.use_cwd=1'; \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.enable_file_override=0'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN echo "max_input_vars = 5000" >> /usr/local/etc/php/php.ini

RUN a2enmod rewrite expires

VOLUME ["/var/www/html", "/var/www/moodledata"]

ENV MOODLE_BRANCH 404
ENV MOODLE_RELEASE 4.4.1
ENV MOODLE_SHA256 fa9cc3ad2326f95e291337b5de627f7b285ac5cbe7986fde9e8d1cb024538ac5

RUN set -ex; \
  curl -o moodle.tgz -fSL "https://download.moodle.org/download.php/direct/stable${MOODLE_BRANCH}/moodle-${MOODLE_RELEASE}.tgz"; \
  echo "$MOODLE_SHA256 moodle.tgz" | sha256sum -c -; \
# upstream tarballs include ./moodle/ so this gives us /usr/src/moodle
  tar -xzf moodle.tgz -C /usr/src/; \
  rm moodle.tgz; \
  chown -R www-data:www-data /usr/src/moodle

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
