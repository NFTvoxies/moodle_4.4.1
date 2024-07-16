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

ARG MOODLE_BRANCH
ARG MOODLE_RELEASE
ARG MOODLE_SHA256
ARG MOODLE_DB_HOST
ARG MOODLE_DB_PORT
ARG MOODLE_DB_NAME
ARG MOODLE_DB_USER
ARG MOODLE_DB_PASSWORD
ARG MOODLE_WWW_ROOT
ARG MOODLE_DATA_ROOT
ARG MYSQL_ROOT_PASSWORD
ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD

ENV MOODLE_BRANCH ${MOODLE_BRANCH}
ENV MOODLE_RELEASE ${MOODLE_RELEASE}
ENV MOODLE_SHA256 ${MOODLE_SHA256}
ENV MOODLE_DB_HOST ${MOODLE_DB_HOST}
ENV MOODLE_DB_PORT ${MOODLE_DB_PORT}
ENV MOODLE_DB_NAME ${MOODLE_DB_NAME}
ENV MOODLE_DB_USER ${MOODLE_DB_USER}
ENV MOODLE_DB_PASSWORD ${MOODLE_DB_PASSWORD}
ENV MOODLE_WWW_ROOT ${MOODLE_WWW_ROOT}
ENV MOODLE_DATA_ROOT ${MOODLE_DATA_ROOT}
ENV MYSQL_ROOT_PASSWORD ${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE ${MYSQL_DATABASE}
ENV MYSQL_USER ${MYSQL_USER}
ENV MYSQL_PASSWORD ${MYSQL_PASSWORD}

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
