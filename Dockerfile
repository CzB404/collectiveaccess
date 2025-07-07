FROM ubuntu:24.04

ENV APACHE_RUN_USER     www-data
ENV APACHE_RUN_GROUP    www-data
ENV APACHE_LOG_DIR      /var/log/apache2
ENV APACHE_PID_FILE     /var/run/apache2.pid
ENV APACHE_RUN_DIR      /var/run/apache2
ENV APACHE_LOCK_DIR     /var/lock/apache2
ENV APACHE_LOG_DIR      /var/log/apache2

ENV CA_PROVIDENCE_VERSION=2.0.8
ENV CA_PROVIDENCE_DIR=/var/www/providence
ENV CA_PAWTUCKET_VERSION=2.0.8
ENV CA_PAWTUCKET_DIR=/var/www

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y
RUN apt update && \
    apt -y install software-properties-common && \
    add-apt-repository -y ppa:ondrej/php && \
    apt update && \
    apt install -y \
    apache2 \
    curl \
    wget \
    zip \
    php8.2 \
    php8.2-bcmath \
    php8.2-curl \
    php8.2-gd \
    php8.2-xml \
    php8.2-zip \
    php8.2-mbstring \
    php8.2-xmlrpc \
    php8.2-intl \
    php8.2-mysql \
    php8.2-cli \
    php8.2-posix \
    php8.2-dev \
    php8.2-redis \
    php8.2-gmp \
    php8.2-ldap \
	php8.2-opcache \
	php8.2-process \
    libapache2-mod-php8.2 \
    mysql-client \
	dcraw \
    ffmpeg \
    ghostscript \
    imagemagick \
    libreoffice \
    libpoppler-dev \
    poppler-utils \
    redis-server \
    libimage-exiftool-perl \
    mediainfo

#GMAGICK
RUN apt install -y php-pear php8.2-dev graphicsmagick libgraphicsmagick1-dev \
	&& pecl channel-update pecl.php.net \
	&& pecl install gmagick-2.0.6RC1 && apt install -y php8.2-gmagick

RUN curl -SsL https://github.com/collectiveaccess/providence/archive/$CA_PROVIDENCE_VERSION.tar.gz | tar -C /var/www/ -xzf -
RUN mv /var/www/providence-$CA_PROVIDENCE_VERSION /var/www/providence
RUN cd $CA_PROVIDENCE_DIR && cp setup.php-dist setup.php

RUN curl -SsL https://github.com/collectiveaccess/pawtucket2/archive/$CA_PAWTUCKET_VERSION.tar.gz | tar -C /var/www/ -xzf -
RUN mv $CA_PAWTUCKET_DIR/pawtucket2-$CA_PAWTUCKET_VERSION/* /var/www
RUN cd $CA_PAWTUCKET_DIR && cp setup.php-dist setup.php

RUN sed -i "s@DocumentRoot \/var\/www\/html@DocumentRoot \/var\/www@g" /etc/apache2/sites-available/000-default.conf
RUN rm -rf /var/www/html
RUN ln -s /$CA_PROVIDENCE_DIR/media /$CA_PAWTUCKET_DIR/media

RUN chown -R www-data:www-data /var/www

# Cleanup repo cache
RUN apt clean

# Create a backup of the default conf files in case directory is mounted
RUN mkdir -p /var/ca/providence/conf
RUN cp -r /$CA_PROVIDENCE_DIR/app/conf/* /var/ca/providence/conf
RUN mkdir -p /var/ca/pawtucket/conf
RUN cp -r /$CA_PAWTUCKET_DIR/app/conf/* /var/ca/pawtucket/conf

# Append php.ini
COPY php-append.ini /php-append.ini
RUN echo /php-append.ini >> /etc/php/8.2/apache2/php.ini && rm /php-append.ini

# Copy our local files
COPY entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh

# Run apcache from entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "/usr/sbin/apache2", "-DFOREGROUND" ]
