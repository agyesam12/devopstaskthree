#!/usr/bin/env bash
#
# test_dashboard.sh - Put load on the system so it shows up on the dashboard
# and trigger the high_cpu_usage alert.
# Usage: sudo ./test_dashboard.sh
#
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root: sudo ./test_dashboard.sh"
    exit 1
fi

DASHBOARD_URL="http://localhost:19999"

if ! curl -fs "$DASHBOARD_URL/api/v1/info" >/dev/null; then
    echo "Netdata is not running. Run: sudo ./setup.sh"
    exit 1
fi

if ! command -v stress-ng >/dev/null 2>&1; then
    echo "==> Installing stress-ng (load generator)"
    apt-get update -qq
    apt-get install -y -qq stress-ng >/dev/null
fi

echo "Open $DASHBOARD_URL now and watch the charts."
echo

echo "==> [1/3] CPU: all cores at 90% for 90 seconds (should trigger the alert)"
stress-ng --cpu 0 --cpu-load 90 --timeout 90s --quiet

echo "==> Checking alert status"
curl -fs "$DASHBOARD_URL/api/v1/alarms?all" | python3 -c '
import json, sys
alarms = json.load(sys.stdin).get("alarms", {})
found = [a for a in alarms.values() if a.get("name") == "high_cpu_usage"]
if not found:
    print("    high_cpu_usage alert not found - check the config and run setup.sh again")
for a in found:
    print("    high_cpu_usage: status =", a.get("status"), "| value =", a.get("value_string"))
'

echo "==> [2/3] Memory: 2 workers using 40% of RAM for 60 seconds"
stress-ng --vm 2 --vm-bytes 40% --timeout 60s --quiet

echo "==> [3/3] Disk I/O: 2 workers writing for 60 seconds"
stress-ng --hdd 2 --timeout 60s --quiet

echo
echo "Done. On the dashboard, look at: CPU, Memory (RAM), Disks (I/O) and the Alerts tab."