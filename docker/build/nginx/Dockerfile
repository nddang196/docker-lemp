ARG VERSION

FROM nginx:alpine

MAINTAINER VooThanh DEV <voothanhphong@gmail.com>

ENV SERVER_NAME docker.io
ENV PHP_SERVICE ""
ENV PHP_PORT 9000
ENV IS_HTTPS false
ENV IS_MAGENTO false
ENV IS_MAGENTO_MULTI false
ENV MAGENTO_MODE production
ENV MAGENTO_RUN_TYPE store
ENV ROOT_FOLDER /project

COPY vhost/ /etc/nginx/vhost/
COPY include/ /etc/nginx/include/
COPY config/*.conf /etc/nginx/conf.d/

COPY entrypoint.sh /
COPY bin/* /usr/local/bin/

RUN apk update && \
    apk add bash && \
    apk add openssl && \
    mkdir -p ${ROOT_FOLDER} && \
    sed -i -e 's/\r$//' /entrypoint.sh && \
    sed -i -e 's/\r$//' /usr/local/bin/creatSslKey && \
    chmod +x /entrypoint.sh && \
    chmod +x /usr/local/bin/* && \
    rm -rf /var/cache/apk/*

WORKDIR ${ROOT_FOLDER}

ENTRYPOINT ["/entrypoint.sh"]

VOLUME /etc/nginx/conf.d
VOLUME /etc/nginx/include

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]