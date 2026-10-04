# Raspberry Pi Fleet Guide

> Complete, agent-ready documentation for provisioning, configuring, operating, and maintaining Raspberry Pi computers (Pi 3, Pi 4, Pi 5, Zero 2 W) — for headless servers and desktop use.

This repository is the **single source of truth** for how we work with Raspberry Pis: flashing, first boot, hardening, networking, Docker, Home Assistant, media servers, web development, monitoring, backups, and recovery.

It is written to be consumed by **humans and AI agents alike** — every doc is self-contained, cross-linked, and includes copy-pasteable commands.

---

## Quick start (5 minutes to a working Pi)

1. Install [Raspberry Pi Imager](https://www.raspberrypi.com/software/) on your computer.
2. Flash **Raspberry Pi OS Lite (64-bit)** to an SD card — see [Imaging guide](docs/02-imaging/01-raspberry-pi-imager.md).
3. In Imager's **OS customization** dialog (gear icon / `Ctrl+Shift+X`): set hostname, username + password, enable SSH, pre-configure Wi-Fi.
4. Boot the Pi, then `ssh <user>@<hostname>.local`.
5. Run `scripts/bootstrap.sh` on the Pi to update, harden, and install tooling. See [Bootstrap script](scripts/README.md).

Full walkthroughs: [Imaging](docs/02-imaging/01-raspberry-pi-imager.md) → [First boot](docs/03-setup/01-first-boot.md) → [Security](docs/03-setup/03-users-and-security.md).

---

## Documentation map

| # | Area | Docs |
|---|------|------|
| — | Cheat sheet | [Quick reference](docs/00-quick-reference.md) |
| 01 | Hardware | [Models & specs](docs/01-hardware/01-models.md) · [Power](docs/01-hardware/02-power.md) · [Storage](docs/01-hardware/03-storage.md) · [GPIO & peripherals](docs/01-hardware/04-gpio-peripherals.md) |
| 02 | Imaging | [Raspberry Pi Imager step-by-step](docs/02-imaging/01-raspberry-pi-imager.md) · [Choosing an OS](docs/02-imaging/02-os-choices.md) · [Alternative flash methods](docs/02-imaging/03-alternative-flash-methods.md) |
| 03 | Setup | [First boot](docs/03-setup/01-first-boot.md) · [raspi-config](docs/03-setup/02-raspi-config.md) · [Users & security](docs/03-setup/03-users-and-security.md) · [Networking](docs/03-setup/04-networking.md) |
| 04 | Remote access | [SSH](docs/04-remote-access/01-ssh.md) · [VNC & RDP](docs/04-remote-access/02-vnc-rdp.md) · [Tailscale VPN](docs/04-remote-access/03-tailscale.md) |
| 05 | System | [Updates & firmware](docs/05-system/01-updates-firmware.md) · [Performance](docs/05-system/02-performance.md) · [Storage & mounts](docs/05-system/03-storage-mounts.md) · [systemd](docs/05-system/04-systemd.md) · [Backups](docs/05-system/05-backups.md) |
| 06 | Docker | [Installation](docs/06-docker/01-installation.md) · [Compose patterns](docs/06-docker/02-compose-patterns.md) · [ARM compatibility](docs/06-docker/03-arm-compatibility.md) |
| 07 | Services | [Home Assistant](docs/07-services/01-home-assistant.md) · [Media server](docs/07-services/02-media-server.md) · [File sharing (Samba/NFS)](docs/07-services/03-file-sharing.md) · [Web development](docs/07-services/04-web-development.md) |
| 08 | Maintenance | [Monitoring](docs/08-maintenance/01-monitoring.md) · [Troubleshooting](docs/08-maintenance/02-troubleshooting.md) |

## Scripts & templates

| Path | Purpose |
|------|---------|
| [`scripts/bootstrap.sh`](scripts/README.md) | Post-install: updates, hardening, Docker, monitoring tools |
| [`scripts/backup.sh`](scripts/README.md) | rsync-based data/config backup to a target host or mount |
| [`scripts/healthcheck.sh`](scripts/README.md) | Temperature, throttling, disk, memory, Docker health — cron-friendly |
| [`examples/docker-compose/`](examples/) | Ready-to-adapt stacks: media, Home Assistant, monitoring |
| [`examples/systemd/`](examples/) | Unit file templates for custom services |

## Conventions

- **Language**: all docs in English; commands assume Raspberry Pi OS (Bookworm or newer).
- **Placeholders**: `<angle-brackets>` mark values you must replace.
- **Defaults**: 64-bit Raspberry Pi OS; NetworkManager (`nmcli`) for networking; systemd for services; Docker Compose for apps.
- **Anything destructive** (flashing, `dd`, reformatting) is explicitly called out with a ⚠️ warning.

## For AI agents

Read [`CLAUDE.md`](CLAUDE.md) before answering questions from or making changes on behalf of this repository. It defines structure, safety rules, and how to keep docs in sync.

## License

[MIT](LICENSE) © Sergio Alexander Florez Galeano
