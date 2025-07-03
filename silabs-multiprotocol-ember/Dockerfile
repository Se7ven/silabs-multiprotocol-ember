ARG BUILD_FROM
ARG BUILD_ARCH
FROM --platform=linux/amd64 debian:bookworm AS cross-builder-base

ENV \
    LANG="C.UTF-8" \
    DEBIAN_FRONTEND="noninteractive" \
    CURL_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"

WORKDIR /usr/src

# Allow to reuse downloaded packages (these are only staged build images)
# hadolint ignore=DL3009
RUN \
    set -x \
    && (apt-get update || true) \
    && apt-get install -y --no-install-recommends \
       bash \
       curl \
       ca-certificates \
       build-essential \
       git \
       software-properties-common

FROM --platform=linux/amd64 cross-builder-base AS cross-builder-armv7

COPY debian-armv7.cmake /usr/src/debian.cmake

ENV DEBIAN_ARCH=armhf
ENV DEBIAN_CROSS_PREFIX=arm-linux-gnueabihf
ENV SLC_ARCH=linux_arch_32
ENV ZIGBEED_ARCH=zigbee_arm32

RUN \
    set -x \
    && dpkg --add-architecture armhf \
    && (apt-get update || true) \
    && apt-get install -y --no-install-recommends \
       crossbuild-essential-armhf

FROM --platform=linux/amd64 cross-builder-base AS cross-builder-aarch64

COPY debian-arm64.cmake /usr/src/debian.cmake

ENV DEBIAN_ARCH=arm64
ENV DEBIAN_CROSS_PREFIX=aarch64-linux-gnu
ENV SLC_ARCH=linux_arch_64
ENV ZIGBEED_ARCH=zigbee_arm64

RUN \
    set -x \
    && dpkg --add-architecture arm64 \
    && (apt-get update || true) \
    && apt-get install -y --no-install-recommends \
       crossbuild-essential-arm64

FROM --platform=linux/amd64 cross-builder-base AS cross-builder-amd64

COPY debian-amd64.cmake /usr/src/debian.cmake

ENV DEBIAN_ARCH=amd64 \
        DEBIAN_CROSS_PREFIX=x86_64-linux-gnu \
        SLC_ARCH=linux_arch_64 \
        ZIGBEED_ARCH=zigbee_x86_64

RUN \
    set -x \
    && dpkg --add-architecture amd64 \
    && (apt-get update || true) \
    && apt-get install -y --no-install-recommends \
       crossbuild-essential-amd64


FROM --platform=linux/amd64 cross-builder-${BUILD_ARCH} AS cpcd-builder

ARG CPCD_VERSION

RUN \
    set -x \
    && apt-get install -y --no-install-recommends \
       cmake \
       "libmbedtls-dev:${DEBIAN_ARCH}" \
       "libmbedtls14t64:${DEBIAN_ARCH}" \
    && git clone --depth 1 -b "${CPCD_VERSION}" \
       https://github.com/SiliconLabs/cpc-daemon.git \
    && mkdir cpc-daemon/build && cd cpc-daemon/build \
    && cmake ../ \
       -DCMAKE_TOOLCHAIN_FILE=../debian.cmake \
       -DENABLE_ENCRYPTION=FALSE \
    && make \
    && make install

FROM --platform=linux/amd64 cross-builder-${BUILD_ARCH} AS zigbeed-builder

ARG GECKO_SDK_VERSION

RUN \
    set -x \
    && apt-get install -y --no-install-recommends \
       python3 \
       python3-jinja2 \
       python3-pip \
#       openjdk-21-jre \
       git-lfs \
       unzip \
    && curl -o https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb \
    && dpkg -i jdk-21_linux-x64_bin.deb \
    && curl -O https://www.silabs.com/documents/login/software/slc_cli_linux.zip \
    && unzip slc_cli_linux.zip \
    && cd slc_cli/ && chmod +x slc

ENV PATH="/usr/src/slc_cli/:$PATH"

RUN \
   set -x \
    && git clone --depth 1 -b ${GECKO_SDK_VERSION} \
    https://github.com/SiliconLabs/simplicity_sdk.git

#RUN \
#    set -x \
#    && git clone --depth 1 -b ${GECKO_SDK_VERSION} \
#       https://github.com/SiliconLabs/gecko_sdk.git
#
# zigbeed links against libcpc.so
COPY --from=cpcd-builder /usr/local/ /usr/${DEBIAN_CROSS_PREFIX}/
#COPY gecko-sdk-patches/0001-Use-TCP-socket-instead-of-serial-port-SDK.patch /usr/src
#COPY zigbeed-app-patches/0001-Use-TCP-socket-instead-of-serial-port-main-app.patch /usr/src
#
RUN \
    set -x \
    && ldconfig \
    && slc configuration --sdk ./simplicity_sdk \
    && slc signature trust --sdk ./simplicity_sdk \
    && slc signature trust \
    && echo ${ZIGBEED_ARCH} \
    && echo ${SLC_ARCH} \
    && slc generate \
#       --with="zigbee_x86_64,linux_arch_64" \
       --with="${ZIGBEED_ARCH},${SLC_ARCH}" \
       --sdk=$(pwd)/simplicity_sdk \
       --without=zigbee_recommended_linux_arch \
       --project-file=$(pwd)/simplicity_sdk/protocol/zigbee/app/projects/zigbeed/zigbeed.slcp \
       --export-destination=$(pwd)/simplicity_sdk/protocol/zigbee/app/projects/zigbeed/output \
       --copy-proj-sources \
  && cd simplicity_sdk/protocol/zigbee/app/projects/zigbeed/output \
##  && patch -p1 < /usr/src/0001-Use-TCP-socket-instead-of-serial-port-main-app.patch \
  && make -f zigbeed.Makefile \
        AR="${DEBIAN_CROSS_PREFIX}-ar" \
        CC="${DEBIAN_CROSS_PREFIX}-gcc" \
        LD="${DEBIAN_CROSS_PREFIX}-gcc" \
        CXX="${DEBIAN_CROSS_PREFIX}-g++" \
        C_FLAGS="-std=gnu99 -DEMBER_MULTICAST_TABLE_SIZE=16"
#  && ls -la /usr/src/simplicity_sdk/protocol/zigbee/app/zigbeed/output/build/debug/ && exit 1
#        debug

FROM $BUILD_FROM

ARG UNIVERSAL_SILABS_FLASHER
LABEL org.opencontainers.image.source=https://github.com/Se7ven/silabs-multiprotocol-ember
RUN \
    set -x \
    && (apt-get update || true) \
    && apt-get install -y --no-install-recommends \
       libmbedtls14 \
       socat \
       supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/src/*


COPY --from=zigbeed-builder \
     /usr/src/simplicity_sdk/util/third_party/ot-br-posix /usr/src/ot-br-posix
COPY --from=zigbeed-builder \
     /usr/src/simplicity_sdk/util/third_party/openthread /usr/src/openthread
COPY --from=zigbeed-builder \
     /usr/src/simplicity_sdk/protocol/openthread/platform-abstraction/posix /usr/src/silabs-vendor-interface
COPY --from=cpcd-builder /usr/local/ /usr/local/

ENV BORDER_ROUTING=1
ENV BACKBONE_ROUTER=1
ENV WEB_GUI=1
ENV DOCKER=1

COPY otbr-patches/0001-Avoid-writing-to-system-console.patch /usr/src
COPY otbr-patches/0001-rest-support-erasing-all-persistent-info-1908.patch /usr/src
COPY otbr-patches/0002-rest-support-deleting-the-dataset.patch /usr/src
COPY otbr-patches/0003-mdns-update-mDNSResponder-to-1790.80.10.patch /usr/src
COPY otbr-patches/0004-mdns-add-Linux-specific-patches.patch /usr/src

# Required and installed during build (script/bootstrap), could be removed
ENV OTBR_BUILD_DEPS="build-essential ninja-build cmake wget ca-certificates \
  libreadline-dev libncurses-dev libcpputest-dev libdbus-1-dev libavahi-common-dev \
  libavahi-client-dev libboost-dev libboost-filesystem-dev libboost-system-dev \
  libnetfilter-queue-dev"

# Build OTBR natively from Gecko SDK sources
WORKDIR /usr/src
RUN \
    set -x \
    && (apt-get update || true) \
    # Install npm/nodejs for WebUI manually to avoid systemd getting pulled in \
    && apt-get install -y --no-install-recommends \
#       nodejs \
#       npm \
       iproute2 \
       patch \
       python3 \
       python3-full \
       python3-dev \
       python3-pip \
       python3-aiohttp \
       python3-cryptography \
       python3-yarl \
       lsb-release \
       netcat-traditional \
       sudo \
    && cd ot-br-posix \
#    && patch -p1 < /usr/src/0001-Avoid-writing-to-system-console.patch \
#    && patch -p1 < /usr/src/0001-rest-support-erasing-all-persistent-info-1908.patch \
#    && patch -p1 < /usr/src/0002-rest-support-deleting-the-dataset.patch \
#    && patch -p1 < /usr/src/0003-mdns-update-mDNSResponder-to-1790.80.10.patch \
#    && patch -p1 < /usr/src/0004-mdns-add-Linux-specific-patches.patch \
    && ln -s ../../../openthread/ third_party/openthread/repo \
    && (cd third_party/openthread/repo \
        && ln -s ../../../../silabs-vendor-interface/openthread-core-silabs-posix-config.h src/posix/platform/openthread-core-silabs-posix-config.h) \
    && chmod +x ./script/* \
    && ./script/bootstrap \
    # Mimic rt_tables_install \
    && echo "88 openthread" >> /etc/iproute2/rt_tables \
    # Mimic otbr_install \
    && (./script/cmake-build \
        -DBUILD_TESTING=OFF \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_MODULE_PATH=/usr/src/silabs-vendor-interface/ \
        -DOTBR_FEATURE_FLAGS=ON \
        -DOTBR_DNSSD_DISCOVERY_PROXY=ON \
        -DOTBR_SRP_ADVERTISING_PROXY=ON \
        -DOTBR_INFRA_IF_NAME=eth0 \
        -DOTBR_MDNS=mDNSResponder \
        -DOTBR_VERSION= \
        -DOT_PACKAGE_VERSION= \
        -DOTBR_DBUS=OFF \
        -DOT_MULTIPAN_RCP=ON \
#        -DOT_POSIX_CONFIG_RCP_BUS=VENDOR \
        -DOT_POSIX_RCP_VENDOR_BUS=on \
        -DOT_POSIX_RCP_VENDOR_BUS=CPC \
        -DOT_POSIX_CONFIG_RCP_VENDOR_DEPS_PACKAGE=/usr/src/silabs-vendor-interface/posix_vendor_rcp.cmake \
        -DOT_POSIX_CONFIG_RCP_VENDOR_INTERFACE=/usr/src/silabs-vendor-interface/cpc_interface.cpp \
        -DOT_PLATFORM_CONFIG="openthread-core-silabs-posix-config.h" \
        -DOT_LINK_RAW=1 \
        -DOTBR_VENDOR_NAME="Home Assistant" \
        -DOTBR_PRODUCT_NAME="Silicon Labs Multiprotocol" \
        -DOTBR_WEB=ON \
        -DOTBR_BORDER_ROUTING=ON \
        -DOTBR_REST=ON \
        -DOTBR_BACKBONE_ROUTER=ON \
        && cd build/otbr/ \
        && ninja \
        && ninja install) \
    && pip install universal-silabs-flasher==${UNIVERSAL_SILABS_FLASHER} --break-system-packages \
    && apt-get purge -y --auto-remove \
       build-essential \
       patch \
       python3-pip \
       python3-dev \
       git \
       git-lfs \
       libmbedtls-dev \
       ${OTBR_BUILD_DEPS} \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/src/*
#
COPY --from=zigbeed-builder \
     /usr/src/simplicity_sdk/protocol/zigbee/app/projects/zigbeed/output/build/debug/zigbeed \
     /usr/local/bin
#
RUN ldconfig && touch /accept_silabs_msla

COPY rootfs /
RUN for f in /etc/s6-overlay/s6-rc.d/**/data/*; do chmod +x $f; done \
    && for f in /etc/s6-overlay/s6-rc.d/**/run; do chmod +x $f; done

ENV \
    S6_STAGE2_HOOK=/etc/s6-overlay/scripts/enable-check.sh

HEALTHCHECK --interval=10s --start-period=120s CMD [ "$(s6-svstat -u /run/service/zigbeed)" = "true" ]

# use s6-overlay as init system
WORKDIR /
ENTRYPOINT ["/init"]
