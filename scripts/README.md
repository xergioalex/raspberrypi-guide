# scripts/

Operational scripts for the Pi fleet. Copy them to the Pi (e.g. `/opt/scripts/`) — or clone the repo — and run from there.

| Script | What it does | Usage |
|---|---|---|
| `bootstrap.sh` | Post-flash provisioning: apt update/full-upgrade, EEPROM check, essential packages, SSH hardening, ufw, fail2ban, unattended-upgrades, optional Docker + Tailscale | `sudo ./bootstrap.sh [--hostname NAME] [--docker] [--tailscale] [--yes]` |
| `backup.sh` | rsync the system + `/opt` stacks + `/home` to a target (local mount or ssh host) with excludes and a timestamped marker | `sudo ./backup.sh /mnt/backup` or `sudo ./backup.sh user@host:/path` |
| `healthcheck.sh` | One-shot health report: temp, throttling, disk, RAM, failed units, Docker containers; `--quiet` for cron | `./healthcheck.sh [--quiet]` |

## Install on a Pi

```bash
# from your computer
rsync -avh scripts/ pi-server:/opt/scripts/
ssh pi-server 'chmod +x /opt/scripts/*.sh'

# or full clone
ssh pi-server 'git clone https://github.com/xergioalex/raspberrypi-guide.git ~/raspberrypi-guide'
```

## Recommended post-flash sequence

```bash
sudo /opt/scripts/bootstrap.sh --hostname pi-server --docker
sudo reboot
/opt/scripts/healthcheck.sh
```

## Conventions

- `set -euo pipefail` everywhere; scripts fail loudly, not silently.
- Idempotent: safe to re-run (apt/Docker installs detect existing state).
- Anything destructive prints what it will do first; `--yes` skips prompts for automation.
- Keep the flags documented here and in the relevant doc when you change them (see [CLAUDE.md](../CLAUDE.md)).
