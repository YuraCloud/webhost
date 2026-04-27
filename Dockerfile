FROM alpine:3.18

# Install base dependencies
RUN apk add --no-cache \
    curl \
    wget \
    bash \
    ca-certificates \
    openssl \
    nginx \
    php82 \
    php82-fpm \
    php82-mysqli \
    php82-json \
    php82-openssl \
    php82-curl \
    php82-zlib \
    php82-xml \
    php82-phar \
    php82-intl \
    php82-dom \
    php82-xmlreader \
    php82-ctype \
    php82-session \
    php82-mbstring \
    php82-tokenizer \
    php82-xmlwriter \
    php82-fileinfo \
    nodejs \
    npm \
    python3 \
    py3-pip \
    mariadb-client \
    git \
    supervisor \
    composer \
    zip \
    busybox-extras

# Link php82 to php
RUN ln -sf /usr/bin/php82 /usr/bin/php

# Configure Nginx
RUN mkdir -p /run/nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Setup workspace
WORKDIR /home/container

# Copy templates, bahasa, and scripts
COPY templates /home/container/templates
COPY bahasa /home/container/bahasa
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Environment variables
ENV USER=container HOME=/home/container

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
