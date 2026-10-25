"# devopstaskthree" 
# Simple Monitoring Dashboard with Netdata

Set up real-time system monitoring with [Netdata](https://github.com/netdata/netdata), add a custom chart and a CPU alert, then automate install, load testing and cleanup with shell scripts.

Project page: https://roadmap.sh/projects/simple-monitoring-dashboard

## What's included

| Script | What it does |
|---|---|
| `setup.sh` | Installs Netdata, adds a CPU usage alert and a custom website uptime chart, restarts Netdata and checks it's running |
| `test_dashboard.sh` | Uses `stress-ng` to load CPU, memory and disk I/O, then shows whether the CPU alert fired |
| `cleanup.sh` | Stops any load tests, removes the custom config and uninstalls Netdata |

## Requirements

- Ubuntu or Debian Linux with `systemd` (tested on Ubuntu under WSL2)
- `sudo` access and an internet connection

## How to run

```bash
git clone https://github.com/agyesam12/devopstaskthree.git
cd devopstaskthree
chmod +x setup.sh test_dashboard.sh cleanup.sh

sudo ./setup.sh            # 1. install and configure
# open http://localhost:19999 in your browser
sudo ./test_dashboard.sh   # 2. generate load and watch the charts
sudo ./cleanup.sh          # 3. remove everything
```

## What's monitored

Netdata collects these automatically every second:
- **CPU:** usage per core and in total (`system.cpu`)
- **Memory:** used, cached, free (`system.ram`)
- **Disk I/O:** reads and writes per disk (`disk.*`)
- Network, processes, load average and hundreds of other metrics

## Customisation: new chart

`setup.sh` adds an **HTTP check** chart (`go.d/httpcheck.conf`) that checks https://sammyfoldtech.com every 10 seconds and charts:
- response time
- whether the site is up (status code and content checks)

You'll find it in the dashboard under **httpcheck**.

## Alert: CPU usage above 80%

`setup.sh` adds `health.d/cpu_usage.conf`:

```
 alarm: high_cpu_usage
    on: system.cpu
lookup: average -1m unaligned of user,system,softirq,irq,guest
 every: 10s
  warn: $this > 80
  crit: $this > 95
 delay: down 1m
```

- `lookup` averages the last **1 minute**, so a brief spike doesn't trigger it, which avoids false alarms.
- `warn` above 80%, `crit` above 95%.
- `delay: down 1m` waits a minute before clearing, so the alert doesn't flip on and off.

`test_dashboard.sh` runs all CPU cores at 90% for 90 seconds, which should put the alert into **WARNING**.

## Notes

- On first visit, the dashboard may ask you to sign in to Netdata Cloud. You can skip that and use the local dashboard anonymously.
- Config lives in `/etc/netdata` (or `/opt/netdata/etc/netdata` for the static build). After editing alerts, reload them with `sudo netdatacli reload-health`.