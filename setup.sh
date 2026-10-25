set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root: sudo ./setup.sh"
    exit 1
fi

DASHBOARD_URL="http://localhost:19999"

echo "==> [1/5] Installing dependencies"
apt-get update -qq
apt-get install -y -qq curl >/dev/null

echo "==> [2/5] Installing Netdata"
if command -v netdata >/dev/null 2>&1; then
    echo "    Netdata already installed, skipping"
else
    curl -fsSL https://get.netdata.cloud/kickstart.sh -o /tmp/netdata-kickstart.sh
    sh /tmp/netdata-kickstart.sh --non-interactive --stable-channel --disable-telemetry
fi


if [ -d /etc/netdata ]; then
    CONFIG_DIR=/etc/netdata
else
    CONFIG_DIR=/opt/netdata/etc/netdata
fi
echo "    Config directory: $CONFIG_DIR"

echo "==> [3/5] Adding alert: CPU usage above 80%"
mkdir -p "$CONFIG_DIR/health.d"
cat > "$CONFIG_DIR/health.d/cpu_usage.conf" <<'CONF'
# Custom alert: average CPU usage over the last minute
 alarm: high_cpu_usage
    on: system.cpu
lookup: average -1m unaligned of user,system,softirq,irq,guest
 units: %
 every: 10s
  warn: $this > 80
  crit: $this > 95
 delay: down 1m
  info: Average CPU usage over the last minute is above 80%
CONF

echo "==> [4/5] Adding custom chart: website uptime check"
mkdir -p "$CONFIG_DIR/go.d"
cat > "$CONFIG_DIR/go.d/httpcheck.conf" <<'CONF'
# Custom chart: is the website up and how fast does it respond?
jobs:
  - name: sammyfoldtech
    url: https://sammyfoldtech.com
    timeout: 5
    update_every: 10
CONF

echo "==> [5/5] Restarting Netdata"
systemctl restart netdata

# Wait up to 30 seconds for the API to answer
for _ in $(seq 1 30); do
    if curl -fs "$DASHBOARD_URL/api/v1/info" >/dev/null; then
        echo
        echo "Netdata is running. Open the dashboard: $DASHBOARD_URL"
        exit 0
    fi
    sleep 1
done

echo "Netdata did not respond on $DASHBOARD_URL. Check: systemctl status netdata"
exit 1