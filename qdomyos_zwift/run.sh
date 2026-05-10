#!/bin/bash
set -e

PORT=$(grep -o '"port":[^,}]*' /data/options.json 2>/dev/null | grep -o '[0-9]*' || echo 8080)
PORT=${PORT:-8080}
HTTP_PORT=$((PORT + 1))
WS_PORT=$((PORT + 2))
NO_GUI_JSON=$(grep -o '"no_gui":[^,}]*' /data/options.json 2>/dev/null | grep -o 'true\|false' || true)
NO_GUI=${NO_GUI:-${NO_GUI_JSON:-false}}

read_option() {
    grep -o "\"$1\":[^,}]*" /data/options.json 2>/dev/null | sed 's/"[^"]*":\s*"\?\([^,"}\s]*\)"\?/\1/' || true
}

MQTT_HOST=$(read_option mqtt_host)
MQTT_PORT=$(read_option mqtt_port)
MQTT_USERNAME=$(read_option mqtt_username)
MQTT_PASSWORD=$(read_option mqtt_password)
MQTT_DEVICEID=$(read_option mqtt_deviceid)

# Config persistence
mkdir -p /config
if [ -d /root/.config ] && [ ! -L /root/.config ]; then
    cp -rn /root/.config/. /config/ 2>/dev/null || true
    rm -rf /root/.config
fi
ln -sfn /config /root/.config

mkdir -p /root/profiles

# Apply MQTT overrides and disable virtual BT device
CONF_FILE=$(find /config -name "qDomyos-Zwift.conf" 2>/dev/null | head -1)
if [ -n "$CONF_FILE" ]; then
    apply_setting() {
        local key="$1" val="$2"
        if grep -q "^${key}=" "$CONF_FILE"; then
            sed -i "s|^${key}=.*|${key}=${val}|" "$CONF_FILE"
        else
            echo "${key}=${val}" >> "$CONF_FILE"
        fi
    }
    [ -n "$MQTT_HOST" ]        && apply_setting mqtt_host        "$MQTT_HOST"
    [ -n "$MQTT_PORT" ]        && apply_setting mqtt_port        "$MQTT_PORT"
    [ -n "$MQTT_USERNAME" ]    && apply_setting mqtt_username    "$MQTT_USERNAME"
    [ -n "$MQTT_PASSWORD" ]    && apply_setting mqtt_password    "$MQTT_PASSWORD"
    [ -n "$MQTT_DEVICEID" ]    && apply_setting mqtt_deviceid    "$MQTT_DEVICEID"
fi

export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

if [ ! -e /run/dbus/system_bus_socket ]; then
    mkdir -p /run/dbus
    dbus-daemon --system --fork
fi

cat > /etc/nginx/nginx.conf <<EOF
events {}
http {
    server {
        listen ${PORT};
        location / {
            proxy_pass http://127.0.0.1:${HTTP_PORT};
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection \$http_connection;
            if (\$http_upgrade = "websocket") {
                proxy_pass http://127.0.0.1:${WS_PORT};
            }
        }
    }
}
EOF

nginx -g "daemon off;" &

GUI_FLAGS="-qml -platform webgl:port=${HTTP_PORT}:wsserverport=${WS_PORT}"
if [ "$NO_GUI" = "true" ]; then
    GUI_FLAGS="-no-gui -no-console -no-log"
fi

echo "[INFO] Starting QDomyos-Zwift on port ${PORT}..."

set +e
qdomyos-zwift ${GUI_FLAGS}
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -ne 0 ]; then
    echo "[ERROR] qdomyos-zwift exited with code ${EXIT_CODE}" >&2
fi

export QT_LOGGING_RULES="qt.bluetooth*=true"
export QT_ASSUME_STDERR_HAS_CONSOLE=1

exit $EXIT_CODE
