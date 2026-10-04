# First boot

What happens on first boot, how to find the Pi on the network, connect, and the immediate post-install checklist.

> **Applies to:** Raspberry Pi OS flashed with [Imager customization](../02-imaging/01-raspberry-pi-imager.md) (user, SSH, Wi-Fi already set)
> **Related:** [raspi-config](02-raspi-config.md) · [Users & security](03-users-and-security.md) · [Networking](04-networking.md)

## The boot sequence (what "patience" looks like)

1. Power on → rainbow splash (fast) → boot rainbow/raspberry logos.
2. First-boot init runs: **filesystem expands to fill the card**, user created, SSH host keys generated, Wi-Fi country applied, hostname set. 1–3 minutes on a good card — the green ACT LED blinking = disk activity, all is well.
3. First auto-resize triggers one **automatic reboot** on older releases. Don't panic if it reboots itself once.

Headless (no monitor): the machine just appears on the network once step 2 finishes.

## Find it

From a computer on the same LAN:

```bash
ping pi-server.local          # mDNS name = hostname you set in Imager
ssh myuser@pi-server.local
```

If `.local` doesn't resolve: install avahi/Bonjour on the client (Windows needs Bonjour from iTunes; older Windows needs it manually), or find the DHCP lease in the router.

First login prompt:

```
The authenticity of host 'pi-server.local (192.168.1.42)' can't be established.
ED25519 key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no)?
```

Type `yes`. If you flashed with a public key you're in without a password; otherwise use the password from Imager.

## Post-install checklist (first 10 minutes)

Run these in order — `scripts/bootstrap.sh` automates everything except the parts marked manual:

```bash
# 1. Confirm what we're on
cat /etc/os-release && uname -m && cat /proc/device-tree/model && echo

# 2. Update everything (firmware included)
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y
sudo rpi-eeprom-update -a          # Pi 4/5 bootloader; takes effect next reboot
sudo reboot

# 3. Health: power and temperature must be clean
vcgencmd get_throttled             # want 0x0 — see Power doc if not

# 4. Networking sanity
ip -br addr                        # interface, state, IP
nmcli device status

# 5. Time (logs and TLS need it)
timedatectl                        # confirm NTP synchronized: yes

# 6. Hostname per role (if not set in Imager)
sudo raspi-config nonint do_hostname "pi-media" && sudo reboot

# 7. Hardening + tooling
# → follow docs/03-setup/03-users-and-security.md, or run scripts/bootstrap.sh

# 8. Your first service
# → docs/06-docker/01-installation.md
```

## Desktop first boot (GUI machines)

The desktop shows a welcome wizard: locale, user (skip if Imager created one), Wi-Fi, updates. Complete it once, then:

- Default browser + updates work out of the box.
- For remote desktop use, enable **VNC**: `sudo raspi-config nonint do_vnc 0` (RealVNC server is preinstalled) — see [VNC & RDP](../04-remote-access/02-vnc-rdp.md).
- Screen resolution on headless-use desktops: set a fixed HDMI mode in `raspi-config` → Display, or `video=HDMI-A-1:1920x1080@60D` in `cmdline.txt`.

## If you can't get in

| Symptom | Fix |
|---|---|
| `ssh: connect: connection refused` in the first 5 min | First-boot init still running — wait |
| Refused after 15+ min | SSH wasn't enabled in Imager customization → reflash (fastest), or attach monitor+keyboard and `sudo raspi-config` → Interface → SSH |
| `Permission denied` | Keyboard-layout mismatch corrupted the password at flash time — reflash with correct locale, or attach monitor and use local login |
| Not on Wi-Fi at all | Wi-Fi country wrong / 5 GHz-only SSID on older models — recheck Imager settings; Pi 3B+/Zero 2 W are 2.4 GHz-only on `n` networks |
| Everything fails | Attach monitor + keyboard once: local login always works and removes all network variables |

Next: [raspi-config](02-raspi-config.md) or straight to [Security hardening](03-users-and-security.md).
