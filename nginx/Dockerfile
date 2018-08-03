FROM alpine:3.8

ENV TRAEFIK_VERSION=1.6.5

RUN set -xe;\
    apk add --update --no-cache nginx;\
    rm -Rf /etc/nginx/*;\
    mkdir -p /etc/nginx/servers;\
    mkdir -p /etc/nginx/ssl

COPY nginx.conf /etc/nginx/nginx.conf
COPY mime.types /etc/nginx/mime.types

CMD ["nginx", "-g", "daemon off;"]
