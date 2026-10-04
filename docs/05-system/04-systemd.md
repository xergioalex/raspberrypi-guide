# systemd

Writing and operating services and timers on Raspberry Pi OS — for apps that shouldn't live in Docker (or must run before it).

> **Applies to:** systemd (all Raspberry Pi OS releases)
> **Related:** [systemd templates](../../examples/systemd/) · [Backups](05-backups.md) (timer example)

## Daily driver commands

```bash
systemctl status <unit>                # state + last logs
sudo systemctl start|stop|restart <unit>
sudo systemctl enable --now <unit>     # start at boot + right now
sudo systemctl disable --now <unit>
systemctl list-units --type=service --state=running
systemctl --failed                     # what broke at boot

journalctl -u <unit> -n 50             # last 50 lines
journalctl -u <unit> -f                # follow
journalctl -u <unit> --since "1 hour ago"
journalctl --disk-usage                # journal size
sudo journalctl --vacuum-size=200M     # cap it (or set SystemMaxUse= below)
```

Keep the journal bounded permanently:

```bash
sudo mkdir -p /etc/systemd/journald.conf.d
echo -e "[Journal]\nSystemMaxUse=200M" | sudo tee /etc/systemd/journald.conf.d/size.conf
sudo systemctl restart systemd-journald
```

## Run a user app as a system service

Template (also in [`examples/systemd/myapp.service`](../../examples/systemd/myapp.service)):

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Node/Python app
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=myuser
WorkingDirectory=/opt/myapp
Environment=NODE_ENV=production
EnvironmentFile=-/opt/myapp/.env
ExecStart=/usr/bin/node server.js        # absolute paths, always
Restart=on-failure
RestartSec=5

# Hardening (drop what the app doesn't need)
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/opt/myapp/data

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload            # after ANY unit file edit
sudo systemctl enable --now myapp
journalctl -u myapp -f                  # watch it start
```

Gotchas:

- `daemon-reload` after every edit — the #1 "my change did nothing" cause.
- Absolute paths in `ExecStart`; `~` and `$PATH` don't expand.
- App logs to **stdout/stderr** → journald captures automatically. Don't daemonize inside the app (no `pm2 daemon`, no `&`).
- Start order: `After=network-online.target` (+ `Wants=`) for anything binding a port.

## Timers (cron's systemd replacement)

`/etc/systemd/system/backup.service`:

```ini
[Unit]
Description=Nightly data backup

[Service]
Type=oneshot
User=root
ExecStart=/opt/scripts/backup.sh /mnt/backup
```

`/etc/systemd/system/backup.timer`:

```ini
[Unit]
Description=Run backup nightly at 03:30

[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true          # catch up if the box was off at the scheduled time

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer
systemctl list-timers                    # next fire time for everything
```

Cron still exists (`crontab -e`) and is fine for one-liners (`scripts/healthcheck.sh` cron entry in [Monitoring](../08-maintenance/01-monitoring.md)). Timers win on logging (journal), `Persistent=` catch-up, and dependencies.

## Docker dependency ordering

A compose stack that must come up after a data mount:

```ini
# /etc/systemd/system/docker-compose@.service
[Unit]
Description=Compose stack %i
Requires=docker.service
After=docker.service mnt-data.mount

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/%i
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
```

`mnt-data.mount` is the systemd name for a fstab mount at `/mnt/data` — use `systemctl list-units --type=mount` to find exact names.
