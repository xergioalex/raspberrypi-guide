# raspi-config

The official Raspberry Pi OS configuration tool — TUI and scriptable non-interactive mode.

> **Applies to:** Raspberry Pi OS Bookworm+
> **Related:** [First boot](01-first-boot.md) · [Networking](04-networking.md) · [Performance](../05-system/02-performance.md)

## Interactive

```bash
sudo raspi-config
```

Sections worth knowing: System (hostname, boot mode, passwords), Display, Interface Options (SSH, VNC, SPI, I²C, serial, camera), Performance (overclock on older models, overlay FS, fan), Localisation, Advanced (network boot order, GL driver), plus an Update action for the tool itself.

Most settings edit `/boot/firmware/config.txt` or systemd units; changes may require reboot.

## Non-interactive (scriptable)

`raspi-config nonint <function> <args>` — the key to idempotent provisioning scripts. `0` = enable, `1` = disable for boolean `do_*` functions.

```bash
# Hostname
sudo raspi-config nonint do_hostname "pi-media"

# SSH / VNC / SPI / I2C / serial / camera
sudo raspi-config nonint do_ssh 0            # enable SSH
sudo raspi-config nonint do_vnc 0            # enable VNC
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_serial 0         # serial console on
sudo raspi-config nonint do_legacy 0         # (legacy camera — avoid)

# Queries (get_* return values, no sudo needed for some)
raspi-config nonint get_ssh                  # 0 = enabled
raspi-config nonint get_hostname
```

Run `raspi-config --help` and read `/usr/bin/raspi-config` for the full function list — it's a readable shell script and the definitive reference for what the TUI does.

## Common tasks

| Task | Menu path | CLI equivalent |
|---|---|---|
| Enable SSH | Interface Options → SSH | `do_ssh 0` |
| Enable VNC | Interface Options → VNC | `do_vnc 0` |
| Set hostname | System Options → Hostname | `do_hostname` |
| Boot to CLI/Desktop | System Options → Boot / Auto Login | `do_boot_behaviour B1/B2/B3/B4` |
| Set timezone/locale | Localisation | `do_change_timezone`, `do_change_locale` |
| Overlay (read-only) FS | Performance → Overlay File System | `do_overlayfs 0` |
| GL driver | Advanced → GL Driver | `do_gldriver` |

## What lives where (when you skip the tool)

- `/boot/firmware/config.txt` — firmware config: GPU memory, overlays (`dtoverlay=`), camera/display, HDMI forcing. It's the file the TUI edits for hardware-level knobs.
- `/boot/firmware/cmdline.txt` — kernel command line (one line!): root device, `console=`, quirk flags.
- `/etc/hostname`, `/etc/hosts` — hostname.
- NetworkManager connections — `/etc/NetworkManager/system-connections/`.
- `networkctl`/`systemd-networkd` — not used by default on Raspberry Pi OS (NetworkManager is the manager since Bookworm).

After editing `config.txt`/`cmdline.txt`: `sudo reboot` to apply.
