# ── Stage 1: Build ───────────────────────────────────────────────────────────
FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG QDOMYOS_VERSION=master
ARG QT_WEBGL_BRANCH=5.15

# Package list aligned with upstream CI (linux-x86-build on ubuntu-24.04)
RUN apt-get update && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
        build-essential \
        git \
        ca-certificates \
        qtbase5-dev \
        qtbase5-dev-tools \
        qtbase5-private-dev \
        qtchooser \
        qt5-qmake \
        qtquickcontrols2-5-dev \
        qtconnectivity5-dev \
        qtpositioning5-dev \
        qtlocation5-dev \
        qtmultimedia5-dev \
        libqt5bluetooth5 \
        libqt5widgets5 \
        libqt5positioning5 \
        libqt5xml5 \
        libqt5charts5-dev \
        libqt5charts5 \
        libqt5networkauth5-dev \
        libqt5websockets5-dev \
        libqt5websockets5 \
        libqt5texttospeech5-dev \
        libqt5texttospeech5 \
        libqt5location5-plugins \
        libqt5multimediawidgets5 \
        libqt5multimedia5-plugins \
        libqt5multimedia5 \
        libqt5sql5 \
        libqt5sql5-sqlite \
        libqt5sql5-mysql \
        libqt5sql5-psql \
        libxcb-randr0-dev \
        libxcb-xtest0-dev \
        libxcb-xinerama0-dev \
        libxcb-shape0-dev \
        libxcb-xkb-dev \
        qml-module* \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/src
RUN git clone --recursive \
        https://github.com/cagnulein/qdomyos-zwift.git \
        qdomyos-zwift \
    && if [ "${QDOMYOS_VERSION}" != "master" ]; then \
           git -C qdomyos-zwift checkout "${QDOMYOS_VERSION}"; \
       fi

WORKDIR /usr/local/src/qdomyos-zwift
RUN git submodule update --init src/smtpclient/ \
    && git submodule update --init src/qmdnsengine/ \
    && git submodule update --init tst/googletest/

# Build qthttpserver (required dependency, mirrors CI)
RUN git clone https://github.com/qt-labs/qthttpserver src/qthttpserver \
    && cp qHttpServerBin/5.15.2/headers/* src/qthttpserver/src/3rdparty/http-parser/ \
    && cd src/qthttpserver \
    && qmake && make -j$(nproc) && make install

# Build qdomyos-zwift from repo root (mirrors CI: qmake; make -j8)
RUN qmake && make -j$(nproc)

# Build WebGL platform plugin (required for web UI)
WORKDIR /usr/local/src
RUN git clone --depth 1 --branch ${QT_WEBGL_BRANCH} \
        https://github.com/qt/qtwebglplugin.git qtwebglplugin \
    && cd qtwebglplugin \
    && sed -i 's|var socket = new WebSocket("ws://" + host + ":" + port);|var socket = new WebSocket((window.location.protocol === "https:" ? "wss" : "ws") + "://" + window.location.host);|' \
        src/plugins/platforms/webgl/webqt.jsx \
    && qmake \
    && make -j$(nproc)

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
        bash \
        nginx \
        libqt5bluetooth5 \
        libqt5widgets5 \
        libqt5positioning5 \
        libqt5xml5 \
        libqt5charts5 \
        libqt5networkauth5 \
        libqt5websockets5 \
        libqt5texttospeech5 \
        libqt5location5-plugins \
        libqt5location5 \
        libqt5multimediawidgets5 \
        libqt5multimedia5-plugins \
        libqt5multimedia5 \
        libqt5sql5 \
        qml-module* \
    && rm -rf /var/lib/apt/lists/*

# Binary is at src/qdomyos-zwift when built from repo root
COPY --from=builder /usr/local/src/qdomyos-zwift/src/qdomyos-zwift /usr/local/bin/qdomyos-zwift

RUN ARCH=$(uname -m) \
    && case "$ARCH" in \
        x86_64)  TRIPLE="x86_64-linux-gnu" ;; \
        aarch64) TRIPLE="aarch64-linux-gnu" ;; \
        armv7l)  TRIPLE="arm-linux-gnueabihf" ;; \
        *)       echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac \
    && mkdir -p /usr/lib/${TRIPLE}/qt5/plugins/platforms
COPY --from=builder /usr/local/src/qtwebglplugin/plugins/platforms/libqwebgl.so /tmp/libqwebgl.so
RUN ARCH=$(uname -m) \
    && case "$ARCH" in \
        x86_64)  TRIPLE="x86_64-linux-gnu" ;; \
        aarch64) TRIPLE="aarch64-linux-gnu" ;; \
        armv7l)  TRIPLE="arm-linux-gnueabihf" ;; \
    esac \
    && mv /tmp/libqwebgl.so /usr/lib/${TRIPLE}/qt5/plugins/platforms/libqwebgl.so

COPY run.sh /run.sh
RUN chmod +x /run.sh
EXPOSE 8080
CMD ["/run.sh"]
