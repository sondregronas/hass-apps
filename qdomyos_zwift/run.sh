#!/usr/bin/with-contenv bashio

bashio::log.info "Starting QDomyos-Zwift (WebGL on port 8080)..."

# Start D-Bus if the system socket isn't available
if [ ! -e /run/dbus/system_bus_socket ]; then
    mkdir -p /run/dbus
    dbus-daemon --system --fork
fi

exec qdomyos-zwift -qml -platform webgl:port=8080

