#!/bin/bash
set -e

PORT=$(grep -o '"port":[^,}]*' /data/options.json 2>/dev/null | grep -o '[0-9]*' || echo 8080)
PORT=${PORT:-8080}
HTTP_PORT=$((PORT + 1))
WS_PORT=$((PORT + 2))

echo "[INFO] Starting QDomyos-Zwift on port ${PORT} (internal HTTP: ${HTTP_PORT}, WS: ${WS_PORT})..."

# Persist /root/.config to /config (addon_config mount) so settings survive restarts
mkdir -p /config
if [ -d /root/.config ] && [ ! -L /root/.config ]; then
    # Copy any default config files into /config (won't overwrite existing persisted files)
    cp -rn /root/.config/. /config/ 2>/dev/null || true
    rm -rf /root/.config
fi
ln -sfn /config /root/.config

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

exec qdomyos-zwift -qml -platform webgl:port=${HTTP_PORT}:wsserverport=${WS_PORT}

