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

mkdir -p /root/.config /config

# Restore write permissions in case a previous run locked the directory
chmod 755 /root/.config 2>/dev/null || true
find /root/.config -name "*.conf" -exec chmod 644 {} \; 2>/dev/null || true

if [ "$(ls -A /config 2>/dev/null)" ]; then
    cp -rf /config/. /root/.config/
fi

if [ "$LOCK_SETTINGS" = "true" ]; then
    find /root/.config -name "*.conf" -exec chmod 444 {} \; 2>/dev/null || true
    chmod 555 /root/.config 2>/dev/null || true
fi

# Required by Qt; missing this can cause a segfault
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

set +e
qdomyos-zwift ${GUI_FLAGS}
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -ne 0 ]; then
    echo "[ERROR] qdomyos-zwift exited with code ${EXIT_CODE}" >&2
    if [ $EXIT_CODE -eq 139 ]; then
        echo "[ERROR] Segmentation fault (SIGSEGV) detected." >&2
        echo "[ERROR] XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}" >&2
        echo "[ERROR] /root/.config permissions: $(stat -c '%a %n' /root/.config 2>/dev/null)" >&2
        echo "[ERROR] dbus socket: $(ls -la /run/dbus/system_bus_socket 2>/dev/null || echo 'missing')" >&2
    fi
    exit $EXIT_CODE
fi
