 
FROM alpine:latest

ARG SWAN_VER=5.3
ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

ENV IMAGE_VER=$BUILD_DATE
WORKDIR /opt/src

# Install build & runtime dependencies
RUN set -eux \
    && apk add --no-cache \
         bash bind-tools coreutils openssl uuidgen wget xl2tpd iptables iptables-legacy \
         iproute2 libcap-ng libcurl libevent linux-pam musl nspr nss nss-tools openrc \
         bison flex gcc make libc-dev bsd-compat-headers linux-pam-dev \
         nss-dev libcap-ng-dev libevent-dev curl-dev nspr-dev \
    # Switch iptables to legacy mode
    && cd /sbin \
    && for fn in iptables iptables-save iptables-restore; do ln -fs xtables-legacy-multi "$fn"; done \
    # Download and build Libreswan
    && cd /opt/src \
    && wget -t 3 -T 30 -nv -O libreswan.tar.gz "https://github.com/libreswan/libreswan/archive/v${SWAN_VER}.tar.gz" \
    || wget -t 3 -T 30 -nv -O libreswan.tar.gz "https://download.libreswan.org/libreswan-${SWAN_VER}.tar.gz" \
    && tar xzf libreswan.tar.gz \
    && rm -f libreswan.tar.gz \
    && cd "libreswan-${SWAN_VER}" \
    && printf 'WERROR_CFLAGS=-w -s\nUSE_DNSSEC=false\nUSE_DH2=true\n' > Makefile.inc.local \
    && printf 'FINALNSSDIR=/etc/ipsec.d\nNSSDIR=/etc/ipsec.d\n' >> Makefile.inc.local \
    && make -s base \
    && make -s install-base \
    && cd /opt/src \
    && mkdir -p /run/openrc \
    && touch /run/openrc/softlevel \
    && rm -rf "/opt/src/libreswan-${SWAN_VER}" \
    # Remove build dependencies
    && apk del --no-cache \
         bison flex gcc make libc-dev bsd-compat-headers linux-pam-dev \
         nss-dev libcap-ng-dev libevent-dev curl-dev nspr-dev

# Download IKEv2 helper script
RUN wget -t 3 -T 30 -nv -O /opt/src/ikev2.sh https://raw.githubusercontent.com/zamibd/setup/refs/heads/main/setup-ipsec-vpn.sh \
    && chmod +x /opt/src/ikev2.sh \
    && ln -s /opt/src/ikev2.sh /usr/bin

# Copy run script
RUN wget -t 3 -T 30 -nv -O /opt/src/run.sh \
    https://raw.githubusercontent.com/zamibd/setup/refs/heads/main/run.sh \
    && chmod 755 /opt/src/run.sh

# Expose VPN ports
EXPOSE 500/udp 4500/udp

CMD ["/opt/src/run.sh"]

# Metadata labels
LABEL maintainer="zami <hi@imzami.com>" \
    org.opencontainers.image.created="$BUILD_DATE" \
    org.opencontainers.image.version="$VERSION" \
    org.opencontainers.image.revision="$VCS_REF" \
    org.opencontainers.image.authors="zami <hi@imzami.com>" \
    org.opencontainers.image.title="IPsec VPN Server on Alpine" \
    org.opencontainers.image.description="Docker image to run an IPsec VPN server (IPsec/L2TP, Cisco IPsec, IKEv2) on Alpine." \
    org.opencontainers.image.url="https://github.com/imzami/vpn-ipsec"
