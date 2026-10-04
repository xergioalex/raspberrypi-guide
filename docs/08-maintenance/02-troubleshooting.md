# Troubleshooting

Symptom → diagnosis → fix, from "it won't boot" to "the network hates me". Ordered by how dead the Pi is.

> **Applies to:** Pi 3B+/4/5/Zero 2 W, Raspberry Pi OS
> **Related:** [Power](../01-hardware/02-power.md) · [Storage](../01-hardware/03-storage.md) · [Imaging](../02-imaging/01-raspberry-pi-imager.md#troubleshooting-the-flash-itself)

## Dead: no LEDs / no video at all

| Symptom | Diagnosis | Fix |
|---|---|---|
| No power LED | PSU/cable dead, or (Pi 4 early revs) e-marker USB-C cable bug | Official PSU; dumb USB-C cable (Pi 4 rev < 1.2) |
| PWR on, nothing else, no ACT flashes | Not reading the card | Re-seat card; reflash; check card reader fakes with `f3` |
| Rainbow screen stuck | Start.elf/firmware can't boot the image | Reflash with current Imager |
| ACT LED blink pattern (Pi 4/5) | Firmware error codes — e.g. 4 slow+4 fast = SD unreadable | See below |
| Boots sometimes, crashes under load | Undervolt ([Power](../01-hardware/02-power.md)) | `vcgencmd get_throttled`; real PSU |

Pi 4/5 ACT blink codes (green LED, after initial 3 blinks = pattern start):

- **4 long + 4 short**: SD/card reader broken or unsupported
- **7 short + 1 long**: no bootable image / bad card contents → reflash
- **3 long + 4 short**: 64-bit image on 32-bit-only… (Pi 3 era) wrong OS for the board

## Half-dead: boots, but wrong

| Symptom | Fix |
|---|---|
| Lightning bolt icon (desktop) / throttled bits | Power doc — replace PSU before debugging anything else |
| Slow after months | Check throttling, then disk I/O, then recorder-DB-style SD wear ([Performance](../05-system/02-performance.md)) |
| Random reboots | Power first, then temps (`measure_temp` under load), then SD errors in `dmesg` |
| Filesystem readonly / fsck at every boot | Dying SD card — image what you can, replace + restore ([Backups](../05-system/05-backups.md)) |
| USB device disconnects randomly | Power budget or bad bridge chip; powered hub / better PSU |
| HDMI no signal | Try the *other* micro-HDMI port (Pi 4/5: port 0 is the one nearest the power connector); force HDMI mode in config.txt (`hdmi_force_hotplug=1`, safe mode: `hdmi_safe=1`) |
| Camera "no cameras available" | `rpicam-hello --list-cameras`; ribbon seated? (blue side to USB on v2, contacts to board on v3); Pi 5 needs 22-pin adapter cable |
| Wi-Fi absent/blocked | Wi-Fi country unset → `sudo iw reg set CO`; rfkill: `rfkill list && sudo rfkill unblock wifi` |

## Network trouble

```bash
ip -br addr                 # do you have an address at all?
nmcli device status         # does NetworkManager see/manage the iface?
ping -c3 192.168.1.1        # gateway reachable?
ping -c3 1.1.1.1            # internet reachable?
resolvectl status           # DNS servers sane?
```

| Symptom | Fix |
|---|---|
| `.local` name doesn't resolve | Client-side mDNS missing (Windows: install Bonjour); router blocking mDNS; use IP meanwhile |
| Ethernet link but no IP | Bad cable/switch port; try another; check `sudo ethtool eth0` |
| Wi-Fi drops periodically | Powersave — `sudo iw dev wlan0 set power_save off` (make persistent via NM dispatcher script if it helps) |
| SSH slow to prompt (30 s) | DNS reverse-lookup on the server: add `UseDNS no` to sshd_config |
| Can reach IP but not by name after rename | mDNS cache — flush (macOS: `sudo dscacheutil -flushcache`), wait a minute |

## Service trouble

```bash
systemctl status <unit>            # enabled? exited how?
journalctl -u <unit> -e            # errors, end of log
docker compose ps && docker compose logs --tail=100 <svc>
```

- **Port already in use**: `sudo ss -tulpn | grep :PORT` → stop the squatter or re-map.
- **Container restart-looping**: read its logs; usually a bad env var, missing volume, or (see [ARM](../06-docker/03-arm-compatibility.md)) `exec format error` = wrong architecture.
- **After apt upgrade, service dead**: check `/var/run/reboot-required` — kernel/firmware updates want a reboot.

## Bootloader / EEPROM (Pi 4/5)

```bash
sudo rpi-eeprom-update                 # pending updates?
vcgencmd bootloader_version            # running version
sudo rpi-eeprom-config                 # BOOT_ORDER sanity
```

USB/NVMe boot failing → update EEPROM, set `BOOT_ORDER=0xf416`-style ([Storage](../01-hardware/03-storage.md)).

## Power/throttle decoding

```
vcgencmd get_throttled
0x0      = healthy
bit  0   0x00001  currently undervolted      → replace PSU now
bit  1   0x00002  arm freq capped now        → thermal or power
bit  2   0x00004  throttled now              → same
bit  3   0x00008  soft temp limit now        → cooling
bit 16   0x10000  undervolt occurred         → happened since boot (intermittent PSU)
bit 17   0x20000  freq cap occurred
bit 18   0x40000  throttling occurred
```

High bits set with low bits clear = "it browned out at some point" — still fix the power, corruption is coming.

## Emergency kit (keep on a shelf)

- A second flashed SD card with your bootstrap on it — boot any sick Pi in 2 minutes.
- USB SD reader + your laptop with Imager installed.
- Known-good official PSU(s).
- Recent off-box backup ([Backups](../05-system/05-backups.md)) — the thing that turns disasters into chores.
