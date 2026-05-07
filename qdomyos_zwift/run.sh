#!/bin/bash
set -e

PORT=$(grep -o '"port":[^,}]*' /data/options.json 2>/dev/null | grep -o '[0-9]*' || echo 8080)
PORT=${PORT:-8080}
HTTP_PORT=$((PORT + 1))
WS_PORT=$((PORT + 2))
NO_GUI=$(grep -o '"no_gui":[^,}]*' /data/options.json 2>/dev/null | grep -o 'true\|false' || echo false)
NO_GUI=${NO_GUI:-false}
LOCK_SETTINGS=$(grep -o '"lock_settings":[^,}]*' /data/options.json 2>/dev/null | grep -o 'true\|false' || echo true)
LOCK_SETTINGS=${LOCK_SETTINGS:-true}

echo "[INFO] Starting QDomyos-Zwift on port ${PORT} (internal HTTP: ${HTTP_PORT}, WS: ${WS_PORT})..."

# Persist settings: restore saved config from /config on each start.
# /config (mapped to /addon_configs/...) is the source of truth - edit files there.
# We lock down /root/.config so Qt cannot overwrite settings via atomic temp-file rename.
mkdir -p /root/.config
mkdir -p /config

if [ "$(ls -A /config 2>/dev/null)" ]; then
    cp -rf /config/. /root/.config/
fi

# Make .conf files AND the directory itself read-only.
# Qt's QSettings uses atomic writes (write temp file, rename over original).
# A read-only directory prevents temp file creation, stopping settings from being reset.
if [ "$LOCK_SETTINGS" = "true" ]; then
    find /root/.config -name "*.conf" -exec chmod 444 {} \; 2>/dev/null || true
    chmod 555 /root/.config 2>/dev/null || true
fi

# Set XDG_RUNTIME_DIR - required by Qt; missing it can cause a segfault
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

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
    GUI_FLAGS="-no-gui -no-console"
fi

qdomyos-zwift ${GUI_FLAGS}

