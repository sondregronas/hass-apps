#!/bin/bash
set -e

PORT=$(grep -o '"port":[^,}]*' /data/options.json 2>/dev/null | grep -o '[0-9]*' || echo 8080)
PORT=${PORT:-8080}
HTTP_PORT=$((PORT + 1))
WS_PORT=$((PORT + 2))
NO_GUI_JSON=$(grep -o '"no_gui":[^,}]*' /data/options.json 2>/dev/null | grep -o 'true\|false' || true)
NO_GUI=${NO_GUI:-${NO_GUI_JSON:-false}}

echo "[INFO] Starting QDomyos-Zwift on port ${PORT} (internal HTTP: ${HTTP_PORT}, WS: ${WS_PORT})..."

mkdir -p /config
if [ -d /root/.config ] && [ ! -L /root/.config ]; then
    cp -rn /root/.config/. /config/ 2>/dev/null || true
    rm -rf /root/.config
fi
ln -sfn /config /root/.config

mkdir -p /config/logs
if [ -d /profiles ] && [ ! -L /profiles ]; then
    cp -rn /profiles/. /config/logs/ 2>/dev/null || true
    rm -rf /profiles
fi
ln -sfn /config/logs /profiles

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

while true; do
    set +e
    qdomyos-zwift ${GUI_FLAGS}
    EXIT_CODE=$?
    set -e

    if [ $EXIT_CODE -eq 0 ]; then
        echo "[INFO] qdomyos-zwift exited cleanly."
        break
    fi

    echo "[ERROR] qdomyos-zwift exited with code ${EXIT_CODE}" >&2
    if [ $EXIT_CODE -eq 139 ]; then
        echo "[ERROR] Segmentation fault (SIGSEGV) detected." >&2
    fi

    echo "[INFO] Restarting in 3 seconds..."
    sleep 3
done
