#!/bin/bash
set -e

echo "[INFO] Starting QDomyos-Zwift..."

# Read port from HA options (/data/options.json), default to 8080
WEBGL_PORT=$(grep -o '"webgl_port":[^,}]*' /data/options.json 2>/dev/null | grep -o '[0-9]*' || echo 8080)
WEBGL_PORT=${WEBGL_PORT:-8080}
echo "[INFO] WebGL port: ${WEBGL_PORT}"

# Persist /root/.config to /addon_config so settings are visible and survive restarts
mkdir -p /addon_config
ln -sfn /addon_config /root/.config

# Start D-Bus if the system socket isn't available
if [ ! -e /run/dbus/system_bus_socket ]; then
    mkdir -p /run/dbus
    dbus-daemon --system --fork
fi

exec qdomyos-zwift -qml -platform webgl:port=${WEBGL_PORT}
