# Updates & firmware

Keeping the OS, firmware, and bootloader current — safely, on machines you depend on.

> **Applies to:** Raspberry Pi OS (apt-based)
> **Related:** [First boot](../03-setup/01-first-boot.md) · [systemd](04-systemd.md)

## OS packages (apt)

```bash
sudo apt update                  # refresh package indexes
apt list --upgradable            # see what would change
sudo apt full-upgrade -y         # apply (handles dependency changes; prefer over plain upgrade)
sudo apt autoremove -y           # drop orphaned packages
```

Reading the tea leaves:

- Packages **held back** are waiting on new dependencies — `full-upgrade` handles them.
- If apt suggests "restart required" (`/var/run/reboot-required` exists), reboot when convenient: `sudo reboot`.
- Lock-file/`dpkg` interrupted errors: `sudo apt --fix-broken install`, `sudo dpkg --configure -a`.

## Scheduled cadence

| Machine type | Cadence |
|---|---|
| Servers (Docker/HA/media) | `sudo apt update && sudo apt full-upgrade -y` weekly + before any planned change; unattended-upgrades handles security patches meanwhile |
| Desktops | When prompted by the GUI updater, or same weekly routine |
| Appliance Pis (HAOS etc.) | Update from the appliance's own UI, **not** apt |

Update Docker containers separately — see [Compose patterns](../06-docker/02-compose-patterns.md#updating-stacks).

## OS release upgrades (e.g. Bookworm → Trixie)

Raspberry Pi OS supports in-place `apt` release upgrades the Debian way (edit sources, `full-upgrade`), but our fleet policy is **reflash on major releases** for servers:

1. Data lives in compose volumes / mounted disks ([layout](../01-hardware/03-storage.md#where-to-put-what-data-layout)).
2. Flash the new release, run `scripts/bootstrap.sh`, restore data, `docker compose up -d`.
3. Less risk than live-upgrading a machine you can't easily rescue.

## Firmware (VideoCore firmware + kernel)

Delivered as apt packages (`raspberrypi-{bootloader,firmware,kernel-*}`) — so `apt full-upgrade` already covers them. Applies at **next boot**.

```bash
# Pending firmware after an apt upgrade?
sudo rpi-eeprom-update            # "bootloader is up-to-date" or prompts to apply
sudo rpi-eeprom-update -a         # stage updates → reboot applies
```

## Bootloader (EEPROM) — Pi 4 / Pi 5

```bash
sudo rpi-eeprom-update
vcgencmd bootloader_version       # currently running version
sudo rpi-eeprom-config            # view/edit BOOT_ORDER and settings
```

When to care:

- USB/NVMe boot not working → update EEPROM + check `BOOT_ORDER` ([Storage](../01-hardware/03-storage.md)).
- Boot failures after PSU changes → `BOOT_CURRENT` limits / `POWER_OFF_ON_HALT` settings live here.
- Rule: run `sudo rpi-eeprom-update -a` after first flash and every few months; it's cheap insurance.

## Rollback

- apt: `sudo apt install package=version` to pin back, or `sudo apt history` isn't available — log your upgrades (`tail /var/log/apt/history.log`).
- EEPROM: `rpi-eeprom-update` keeps the previous image; `sudo rpi-eeprom-update -r <version>` can revert (rarely needed — see `man rpi-eeprom-update`).
