#!/usr/bin/env bash
set -euo pipefail

# Start MITM with the web interface
export MITMPROXY_CONF_DIR=/etc/mitmproxy
/usr/bin/mitmweb \
  --set confdir=/etc/mitmproxy \
  --mode regular \
  --listen-host 127.0.0.1 \
  --listen-port 5000 \
  --web-host 127.0.0.1 \
  --web-port 5001 &

# Reverse proxy with password using Caddy
cat << EOF > /tmp/Caddyfile
:$MITM_PORT {
  basicauth {
  	$MITM_USERNAME $(caddy hash-password --plaintext "$MITM_PASSWORD")
  }
  reverse_proxy 0.0.0.0:5001
}
EOF
/usr/bin/caddy run --config /tmp/Caddyfile &

# Give mitmproxy a moment
echo "Loading MITM proxy.."
until bash -c "</dev/tcp/127.0.0.1/5000" &>/dev/null; do
  sleep 0.5
done
echo "MITM proxy is now available!"

# Launch the server via proxychains so all sockets go through mitmproxy
exec /usr/bin/proxychains4 /bin/bash /entrypoint-original.sh
