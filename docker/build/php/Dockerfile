ARG VERSION=7.0

FROM php:${VERSION}-fpm

MAINTAINER VooThanh DEV <voothanhphong@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV ROOT_FOLDER /project
ENV IS_ACTIVE_XDEBUG false
ENV ENABLE_CRON false

# Update and add install
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	    apt-utils \
        libbz2-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libfreetype6-dev \
        libgeoip-dev \
        libgmp-dev \
        libmagickwand-dev \
        libmagickcore-dev \
        libc-client-dev \
        libkrb5-dev \
        libicu-dev \
        libldap2-dev \
        libpspell-dev \
        libtidy-dev \
        libxslt1-dev \
        libyaml-dev \
        libzip-dev \
        librecode0 \
        librecode-dev \
        zip \
        curl \
        cron \
        vim \
        iproute2 && \
    rm -rf /var/lib/apt/lists/*

# Configure the ext library
RUN PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    if [ $PHP_VERSION -lt 72 ]; then \
        apt-get update && \
        apt-get -y install libmcrypt-dev; \
    fi; \
    if [ $PHP_VERSION -gt 73 ]; then \
        docker-php-ext-configure gd --with-jpeg=/usr/include/ \
            --with-freetype=/usr/include/; \
    else \
        apt-get update && \
        apt-get -y install librecode0 librecode-dev; \
        docker-php-ext-configure gd --with-freetype-dir=/usr/include/ \
            --with-jpeg-dir=/usr/include/ \
            --with-png-dir=/usr/include/; \
        docker-php-ext-configure zip --with-libzip; \
    fi

RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu
RUN docker-php-ext-configure opcache --enable-opcache

# Install required PHP extensions
RUN docker-php-ext-install -j$(nproc) \
                            bcmath \
                            bz2 \
                            calendar \
                            exif \
                            gd \
                            gettext \
                            gmp \
                            imap \
                            intl \
                            ldap \
                            mysqli \
                            opcache \
                            pdo_mysql \
                            pspell \
                            shmop \
                            soap \
                            sockets \
                            sysvmsg \
                            sysvsem \
                            sysvshm \
                            tidy \
                            xmlrpc \
                            xsl \
                            pcntl \
                            zip

RUN PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;"); \
    if [ $PHP_VERSION -lt 72 ]); then \
        docker-php-ext-install mcrypt; \
        curl -o m2 https://files.magerun.net/n98-magerun2-3.2.0.phar; \
    else \
        curl -o m2 https://files.magerun.net/n98-magerun2.phar; \
    fi; \
    if [ $PHP_VERSION -ge 70 ] && [ $PHP_VERSION -lt 74 ]; then \
        docker-php-ext-install recode; \
    fi; \
    if [ $PHP_VERSION -gt 73 ]; then \
        pecl install -o -f xdebug; \
    elif [ $PHP_VERSION -gt 72 ]; then \
        pecl install -o -f xdebug-2.7.1; \
    else \
        pecl install -o -f xdebug-2.6.1; \
    fi

RUN pecl install -o -f redis \
                       geoip-1.1.1

RUN docker-php-ext-enable redis \
                          geoip

# Create user docker add to group www-data
RUN useradd -u 1000 -ms /bin/bash -g www-data www

# Update php config
COPY ini /usr/local/etc/php/conf.d/
COPY pool /usr/local/etc/php-fpm.d/

RUN xdebug3=$(php -v | grep -i "xdebug v3"); \
    \
    if [[ "${xdebug3}" == "" ]]; then \
       rm /usr/local/etc/php/conf.d/z-xdebug3.ini; \
    else \
       rm /usr/local/etc/php/conf.d/z-xdebug.ini; \
    fi
# Entrypoint
COPY ./entrypoint.sh /
RUN sed -i -e 's/\r$//' /entrypoint.sh \
    && chmod +x /entrypoint.sh \
    && chown -R www /entrypoint.sh

# Install composer
RUN curl -sS https://getcomposer.org/installer | \
		php -- --install-dir=/usr/local/bin --version=1.10.19 --filename=composer \
	&& su - www -c "composer global require hirak/prestissimo"

# Download sendmail for mailhog
RUN curl -sSLO https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 \
   && chmod +x mhsendmail_linux_amd64 \
   && mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail

# Download magerun n98
RUN chmod +x m2 && mv m2 /usr/bin/m2

RUN rm -rf /tmp/* && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/entrypoint.sh"]

VOLUME /home/www/.composer/cache

WORKDIR ${ROOT_FOLDER}

EXPOSE 9000

CMD ["php-fpm", "-R"]
