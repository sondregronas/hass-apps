#!/bin/bash
set -e

PORT=$(grep -o '"port":[^,}]*' /data/options.json 2>/dev/null | grep -o '[0-9]*' || echo 8080)
PORT=${PORT:-8080}
HTTP_PORT=$((PORT + 1))
WS_PORT=$((PORT + 2))
NO_GUI=$(grep -o '"no_gui":[^,}]*' /data/options.json 2>/dev/null | grep -o 'true\|false' || echo false)
NO_GUI=${NO_GUI:-false}

echo "[INFO] Starting QDomyos-Zwift on port ${PORT} (internal HTTP: ${HTTP_PORT}, WS: ${WS_PORT})..."

w# Persist settings: restore saved config from /config and make it read-only
# so the app reads our settings but cannot overwrite them on startup.
mkdir -p /root/.config
mkdir -p /config

if [ "$(ls -A /config 2>/dev/null)" ]; then
    cp -rf /config/. /root/.config/
fi

# Make config files read-only so the app can't overwrite them
find /root/.config -name "*.conf" -exec chmod 444 {} \; 2>/dev/null || true

# On exit, make writable again and save back to /config
_save_config() {
    find /root/.config -name "*.conf" -exec chmod 644 {} \; 2>/dev/null || true
    cp -rf /root/.config/. /config/ 2>/dev/null || true
}
trap _save_config EXIT

# Start D-Bus if the system socket isn't available
if [ ! -e /run/dbus/system_bus_socket ]; then
    mkdir -p /run/dbus
    dbus-daemon --system --fork
fi

# Generate nginx config with the user-configured port
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

qdomyos-zwift ${GUI_FLAGS}

