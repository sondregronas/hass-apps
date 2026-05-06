# ── Stage 1: Build base (compile tools + Qt dev libs) ───────────────────────
FROM ubuntu:22.04 AS build-base

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
        git \
        ca-certificates \
        qtquickcontrols2-5-dev \
        qtconnectivity5-dev \
        qtbase5-private-dev \
        qtpositioning5-dev \
        libqt5charts5-dev \
        libqt5networkauth5-dev \
        libqt5websockets5-dev \
        qml-module* \
        libqt5texttospeech5-dev \
        qtlocation5-dev \
        qtmultimedia5-dev \
        g++ \
        make \
        wget \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# ── Stage 2: Build Qt WebGL platform plugin ──────────────────────────────────
# Qt 5.15.x releases after 5.15.2 are commercial-only on download.qt.io,
# so we clone the open-source mirror from GitHub instead.
FROM build-base AS webgl-builder

ARG QT_WEBGL_BRANCH=5.15

WORKDIR /usr/local/src
RUN git clone --depth 1 --branch ${QT_WEBGL_BRANCH} \
        https://github.com/qt/qtwebglplugin.git qtwebglplugin \
    && cd qtwebglplugin \
    && sed -i 's|var socket = new WebSocket("ws://" + host + ":" + port);|var socket = new WebSocket((window.location.protocol === "https:" ? "wss" : "ws") + "://" + host + ":" + port);|' \
        src/plugins/platforms/webgl/webqt.jsx \
    && qmake \
    && make -j$(nproc)

# ── Stage 3: Build qdomyos-zwift from upstream ───────────────────────────────
FROM build-base AS app-builder

ARG QDOMYOS_VERSION=master

WORKDIR /usr/local/src
RUN git clone --recursive \
    $([ "${QDOMYOS_VERSION}" = "master" ] \
        && echo "https://github.com/cagnulein/qdomyos-zwift.git" \
        || echo "--branch ${QDOMYOS_VERSION} https://github.com/cagnulein/qdomyos-zwift.git") \
    qdomyos-zwift

WORKDIR /usr/local/src/qdomyos-zwift
RUN git submodule update --init src/smtpclient/ \
    && git submodule update --init src/qmdnsengine/ \
    && git submodule update --init tst/googletest/

WORKDIR /usr/local/src/qdomyos-zwift/src
RUN qmake qdomyos-zwift.pro && make -j$(nproc)

# ── Stage 4: Runtime base ────────────────────────────────────────────────────
FROM ubuntu:22.04 AS runtime

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
        libqt5bluetooth5 \
        libqt5widgets5 \
        libqt5positioning5 \
        libqt5xml5 \
        libqt5charts5 \
        libqt5networkauth5 \
        libqt5websockets5 \
        qml-module* \
        libqt5texttospeech5 \
        libqt5location5-plugins \
        libqt5multimediawidgets5 \
        libqt5multimedia5-plugins \
        libqt5multimedia5 \
        qml-module-qtquick-controls2 \
        libqt5location5 \
        bluez \
        dbus \
        bash \
    && rm -rf /var/lib/apt/lists/*

# ── Stage 5: Final image ──────────────────────────────────────────────────────
FROM runtime

COPY --from=app-builder /usr/local/src/qdomyos-zwift/src/qdomyos-zwift /usr/local/bin/qdomyos-zwift
COPY --from=webgl-builder /usr/local/src/qtwebglplugin/plugins/platforms/libqwebgl.so /tmp/libqwebgl.so
# Derive the multiarch triple from uname -m (no dpkg-dev needed)
RUN ARCH=$(uname -m) \
    && case "$ARCH" in \
        x86_64)  TRIPLE="x86_64-linux-gnu" ;; \
        aarch64) TRIPLE="aarch64-linux-gnu" ;; \
        armv7l)  TRIPLE="arm-linux-gnueabihf" ;; \
        *)       echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac \
    && mkdir -p /usr/lib/${TRIPLE}/qt5/plugins/platforms \
    && mv /tmp/libqwebgl.so /usr/lib/${TRIPLE}/qt5/plugins/platforms/libqwebgl.so

COPY run.sh /run.sh
RUN chmod +x /run.sh
EXPOSE 8080
CMD ["/run.sh"]

