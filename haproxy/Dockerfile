FROM alpine:3.10
LABEL maintainer "publicarray"
LABEL description "The Reliable, High Performance TCP/HTTP Load Balancer"
ENV REVISION 4

ENV HAPROXY_BUILD_DEPS gcc linux-headers make openssl-dev musl-dev pcre-dev tar zlib-dev

RUN apk add --no-cache $HAPROXY_BUILD_DEPS

# haproxy v 1.8 + is required for http/2
# https://www.haproxy.org/download/1.8/src/CHANGELOG
ENV HAPROXY_VERSION_SHORT 2.1
ENV HAPROXY_VERSION 2.1.2
ENV HAPROXY_SHA256 6079b08a8905ade5a9a2835ead8963ee10a855d8508a85efb7181eea2d310b77
ENV HAPROXY_DOWNLOAD_URL "https://www.haproxy.org/download/${HAPROXY_VERSION_SHORT}/src/haproxy-${HAPROXY_VERSION}.tar.gz"

RUN set -x && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    wget -O haproxy.tar.gz $HAPROXY_DOWNLOAD_URL && \
    echo "${HAPROXY_SHA256} *haproxy.tar.gz" | sha256sum -c - && \
    tar xzf haproxy.tar.gz && \
    cd haproxy-${HAPROXY_VERSION} && \
    make TARGET=linux-glibc USE_OPENSSL=1 USE_STATIC_PCRE=1 USE_PCRE_JIT=1 USE_ZLIB=1 && \
    make install-bin

#------------------------------------------------------------------------------#
FROM alpine:3.10

ENV HAPROXY_RUN_DEPS curl shadow zlib openssl socat runit coreutils

RUN apk add --no-cache $HAPROXY_RUN_DEPS

COPY --from=0 /usr/local/sbin/haproxy /usr/local/sbin/haproxy

RUN set -x && \
    groupadd _haproxy && \
    useradd -g _haproxy -s /dev/null -d /dev/null _haproxy && \
    mkdir -p \
        /etc/service/haproxy/ \
        /run/haproxy/ \
        /etc/service/ocsp-updater && \
    update-ca-certificates 2> /dev/null || true

COPY entrypoint.sh /
COPY haproxy.conf /etc/haproxy.conf
COPY haproxy.sh /etc/service/haproxy/run
COPY ocsp-updater.sh /etc/service/ocsp-updater/run
# wget https://ssl-config.mozilla.org/ffdhe2048.txt -O /opt/ssl/dhparam.pem
COPY ffdhe2048.txt /opt/ssl/dhparam.pem

VOLUME ["/opt/ssl"]

EXPOSE 853/udp 853/tcp 443/udp 443/tcp

RUN haproxy -vv
RUN haproxy -f /etc/haproxy.conf -c || true

# Gracefully exit
# All services are then put into soft-stop state,
# which means that they will refuse to accept new connections
STOPSIGNAL SIGUSR1

# HEALTHCHECK --start-period=5s --interval=3m \
# CMD curl -f -H 'accept: application/dns-message' -k 'https://127.0.0.1/dns-query?ct&dns=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB'>/dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
