FROM alpine:3.8

ENV CONSUL_VERSION=1.2.1 \
    CONSUL_TEMPLATE_VERSION=0.19.0 \
    CONSUL_SERVER=" " \
    DB_CHARSET="utf8"
    

# install wordpress
RUN set -xe;\
    apk upgrade --update --no-cache;\
    apk add \
        lighttpd \
        php5-common \
        php5-iconv \
        php5-json \
        php5-gd \
        php5-curl \
        php5-xml \
        php5-pgsql \
        php5-imap \
        php5-cgi \
        fcgi \
        php5-pdo \
        php5-pdo_pgsql \
        php5-soap \
        php5-xmlrpc \
        php5-posix \
        php5-mcrypt \
        php5-gettext \
        php5-ldap \
        php5-ctype \
        php5-mysql \
        php5-zlib \
        php5-dom \
        curl;\
    sed -i -e 's/#   include "mod_fastcgi.conf"/include "mod_fastcgi.conf"/g' /etc/lighttpd/lighttpd.conf;\
    sed -i -e 's/\/usr\/bin\/php-cgi/\/usr\/bin\/php-cgi5/g' /etc/lighttpd/mod_fastcgi.conf;\
    mkdir -p /usr/share/webapps/;\
    cd /usr/share/webapps/;\
    curl -Ls -o latest.tar.gz http://wordpress.org/latest.tar.gz;\
    tar -xzvf latest.tar.gz;\
    rm latest.tar.gz;\
    chown -R lighttpd /usr/share/webapps/;\
    mkdir /run/lighttpd;\
    chown lighttpd. /run/lighttpd;\
    mkdir /tmp/wordpress;\
    ln -s /usr/share/webapps/wordpress/ /var/www/localhost/htdocs/wordpress

COPY wp-config.php  /var/www/localhost/htdocs/wordpress/wp-config.php

EXPOSE 80

CMD ["/usr/sbin/lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]
