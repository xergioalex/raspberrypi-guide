# Monitoring

Knowing your Pis are healthy before they aren't: the built-in checks, the healthcheck script, and optional dashboards.

> **Applies to:** all Pis; depth scales from one command to a full Grafana stack
> **Related:** [Troubleshooting](02-troubleshooting.md) · [Performance](../05-system/02-performance.md) · [scripts/healthcheck.sh](../../scripts/README.md)

## Level 0 — the one-liner check-in

```bash
scripts/healthcheck.sh          # temp, throttling, disk, RAM, failed units, docker
```

Output is human-readable and exit-code meaningful (non-zero = something needs eyes) — cron/agents can consume it.

## Level 1 — the commands behind it

```bash
vcgencmd measure_temp                       # SoC temp: < 70 °C idle, < 80 °C loaded = fine
vcgencmd get_throttled                     # 0x0 or investigate power/cooling
free -h                                    # available RAM + swap use
df -h /                                    # disk headroom (keep >15% free)
systemctl --failed                         # units in failed state
docker ps --format '{{.Names}}\t{{.Status}}'   # containers + restart counts
journalctl -p err -S -24h                  # error-level entries, last 24 h
```

## Level 2 — scheduled + notified

Cron mails or healthchecks.io pings (catches "the cron didn't run" too):

```cron
# crontab -e  (or /etc/cron.d/healthcheck)
*/30 * * * * root /opt/scripts/healthcheck.sh --quiet && curl -fsS https://hc-ping.com/<uuid> >/dev/null
0 8 * * *   root /opt/scripts/healthcheck.sh | mail -s "pi-server daily health" me@example.com
```

Uptime/downtime from outside: a free [UptimeRobot](https://uptimerobot.com) ping on any public endpoint; Tailscale-only boxes use their healthcheck ping instead.

## Level 3 — live dashboards

### Netdata (fastest to value)

One command, gorgeous per-process metrics, ARM64-native, web UI on :19999:

```bash
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh && sh /tmp/netdata-kickstart.sh
```

Glances (`pip install glances` / apt) is the lighter cousin — CLI-first, web on :61208.

### Prometheus + Grafana + node_exporter (the real stack)

See [`examples/docker-compose/monitoring.yml`](../../examples/docker-compose/monitoring.yml). node_exporter exposes Pi vitals; Prometheus scrapes; Grafana graphs. Import dashboard **1860** (Node Exporter Full) — it renders Pi temps/throttling too when you add the `vcgencmd` textfile collector.

## Pi-specific signals worth alerting on

| Signal | Meaning | Alert when |
|---|---|---|
| `get_throttled` ≠ 0x0 | Power/thermal events ([decode](02-troubleshooting.md#powerthrottle-decoding)) | any high bit set, ever |
| temp > 80 °C sustained | cooling failing | 10+ min |
| `df` > 85% | SD/disk filling — corruption & crash precursor | threshold |
| SMART realloc/pending sectors (SSD) | dying disk | any nonzero |
| Container restart loops | crashing service | >3 restarts/hour |
| Backup marker file age > 26 h | silent backup death ([Backups](../05-system/05-backups.md#monitoring-backups)) | threshold |

## Fleet view

Tailscale's admin console doubles as a cheap "is everything up" board for tailnet devices. For more, point one Grafana at all Pis' node_exporters (add each as a Prometheus target with its `pi-*.local:9100` address).
