
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root: sudo ./cleanup.sh"
    exit 1
fi

echo "==> [1/3] Stopping any running load tests"
pkill stress-ng 2>/dev/null || true

echo "==> [2/3] Removing custom config"
for dir in /etc/netdata /opt/netdata/etc/netdata; do
    rm -f "$dir/health.d/cpu_usage.conf" "$dir/go.d/httpcheck.conf"
done

echo "==> [3/3] Uninstalling Netdata"
if command -v netdata >/dev/null 2>&1 || [ -d /opt/netdata ]; then
    curl -fsSL https://get.netdata.cloud/kickstart.sh -o /tmp/netdata-kickstart.sh
    sh /tmp/netdata-kickstart.sh --uninstall --non-interactive || apt-get purge -y netdata
else
    echo "    Netdata is not installed, skipping"
fi

rm -f /tmp/netdata-kickstart.sh
echo
echo "Cleanup complete."