# Backups

What to back up, how, and how to make recovery fast. Philosophy: **config-as-code + data volumes**, so a Pi is never precious.

> **Applies to:** server Pis primarily
> **Related:** [Storage & mounts](03-storage-mounts.md) · [systemd timers](04-systemd.md) · [scripts/backup.sh](../../scripts/README.md)

## The two-layer strategy

1. **Rebuild layer (git)**: everything that makes a Pi *that* Pi — compose files, `.env`s (secrets carefully), systemd units, nginx configs, scripts. Lives in repos like this one. If it's not in git, it doesn't exist.
2. **Data layer (backups)**: the stuff that can't be regenerated — databases (HA recorder), photos, torrent state, home dirs.

Disaster recovery then is: flash → bootstrap → `git clone` → restore data → `docker compose up -d`. Target: a Pi rebuilt in under 30 minutes without heartache.

## What to back up, per role

| Role | Must keep | Nice to have |
|---|---|---|
| Docker host | `/opt/*` compose dirs (incl. named-volume data → use bind mounts to make this trivial), `/etc` highlights | `/home/*` |
| Home Assistant (container) | `/opt/homeassistant/config` (full config incl. Zigbee DB, history) | recorder DB dump |
| Media server | Media library is re-fetchable by design (Sonarr/Radarr re-download) — back up **only** their config dbs | watched/status db |
| Web apps | app dir + Postgres/SQLite dumps, Caddyfile/nginx certs | logs (no) |
| All | `/etc/ssh`, crontabs, fstab, `/boot/firmware/config.txt` tweaks | dpkg package list |

Package list for quick reinstall reference:

```bash
dpkg --get-selections > ~/packages.txt       # restore guide: xargs apt install
```

## The tool: `scripts/backup.sh`

rsync-based, run on the Pi, target = another machine's disk mounted at e.g. `/mnt/backup` (or over ssh):

```bash
sudo /opt/scripts/backup.sh /mnt/backup            # full system-ish rsync
sudo /opt/scripts/backup.sh myuser@nas:/srv/backups/pi-server   # over ssh
```

Nightly via systemd timer — copy the timer from [systemd](04-systemd.md#timers-crons-systemd-replacement) or cron:

```cron
30 3 * * * root /opt/scripts/backup.sh /mnt/backup >> /var/log/backup.log 2>&1
```

## Alternative/supplementary tools

| Tool | When |
|---|---|
| **rsync** (our default) | Disk-to-disk/NAS, incremental, transparent |
| **restic** | Encrypted, deduped, snapshotting to Backblaze B2/S3/NAS — the upgrade when data matters a lot. ARM64 builds exist. Encrypted + deduplicated + prune policies |
| **`dd` whole-card clone** | Cold spare image of a known-good system. Slow, space-hungry; do it once after a machine is perfected, keep on your computer |
| **rpi-clone** | Live-clone a running system to a second SD/USB — warm spare you can literally boot |

Home Assistant specifics (appliance HAOS): Settings → System → Backups (built-in, downloads a .tar you should copy off-box; also supports auto-upload add-ons). Container HA: stop the container or use the same rsync of the config dir (SQLite + YAML); or call the HA backup API.

## Database-consistent backups

SQLite (HA, many small apps): copy with the backup API or snapshot after stopping the stack:

```bash
docker compose stop homeassistant
/opt/scripts/backup.sh /mnt/backup
docker compose start homeassistant
```

Or use `sqlite3 db ".backup '/tmp/consistent.db'"` while running. Postgres: `pg_dump` via `docker compose exec`. Never blind-copy a live SQLite file — it can be mid-write.

## 3-2-1 sanity for a home fleet

- **3** copies: Pi + local backup target + offsite (restic to cloud, or rotate a USB disk to family's house).
- **2** different media (SD + SSD, etc.).
- **1** offsite (cloud / another building).
- **Test restores twice a year** — an untested backup is a rumor. Restore the HA config dir to a fresh container and watch it boot.

## Monitoring backups

A backup without alarm bells will silently die with the disk. Minimum: the healthcheck script logs last-success marker, and `scripts/healthcheck.sh` flags targets older than 26 h ([Monitoring](../08-maintenance/01-monitoring.md)); or use [healthchecks.io](https://healthchecks.io) pings from the timer:

```cron
30 3 * * * root /opt/scripts/backup.sh /mnt/backup && curl -fsS https://hc-ping.com/<uuid> >> /var/log/backup.log 2>&1
```
