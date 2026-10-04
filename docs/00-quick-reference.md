# Quick reference — Raspberry Pi cheat sheet

One page of the commands used most often. Each links to the full doc.

> **Applies to:** Raspberry Pi OS (Bookworm or newer), Pi 3 / Pi 4 / Pi 5 / Zero 2 W
> **Related:** all docs — this file is a summary, the detail docs are the source of truth

## Identity & system info

```bash
cat /etc/os-release                    # OS version (e.g. Debian 12 "bookworm")
uname -m                               # aarch64 = 64-bit OS, armv7l/armv6l = 32-bit
cat /proc/device-tree/model            # Exact model, e.g. "Raspberry Pi 5 Model B Rev 1.0"
hostnamectl                            # Hostname, chassis, OS in one shot
vcgencmd get_throttled                 # 0x0 = healthy; anything else → power/thermal issue
```

## Temperature, throttling, power

```bash
vcgencmd measure_temp                  # SoC temperature (°C)
vcgencmd measure_volts core            # Core voltage
vcgencmd get_throttled                 # Decode: 0x1 undervolt now, 0x2 freq capped now,
                                       # 0x4 throttled now, 0x8 soft temp limit now
                                       # 0x10000 undervolt occurred, 0x20000 cap occurred, ...
```

Full decoding: [Troubleshooting](08-maintenance/02-troubleshooting.md).

## Network (NetworkManager — Bookworm default)

```bash
nmcli device status                    # All interfaces + state
nmcli connection show                  # Saved connections
nmcli device wifi list                 # Scan Wi-Fi
nmcli device wifi connect "SSID" password "pass"   # Join Wi-Fi
nmcli connection modify "preconfigured" \
  ipv4.addresses 192.168.1.50/24 ipv4.gateway 192.168.1.1 \
  ipv4.dns "1.1.1.1,9.9.9.9" ipv4.method manual    # Static IP
nmcli connection up "preconfigured"    # Apply
ip -br addr                            # Quick IP overview
```

Details: [Networking](03-setup/04-networking.md).

## SSH

```bash
ssh <user>@<hostname>.local            # Connect via mDNS
ssh-keygen -t ed25519 -C "comment"     # Generate key
ssh-copy-id <user>@<hostname>.local    # Install key
```

Details: [SSH](04-remote-access/01-ssh.md).

## Updates & firmware

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt autoremove -y
sudo rpi-eeprom-update                # Check for bootloader updates (Pi 4/5)
sudo rpi-eeprom-update -a             # Apply bootloader update (takes effect after reboot)
```

Details: [Updates & firmware](05-system/01-updates-firmware.md).

## raspi-config (non-interactive)

```bash
sudo raspi-config                     # Interactive TUI
sudo raspi-config nonint do_hostname "pi-server"   # Set hostname
sudo raspi-config nonint do_ssh 0                  # Enable SSH (0 = enable)
sudo raspi-config nonint get_ssh                   # Query (0 = enabled)
```

Details: [raspi-config](03-setup/02-raspi-config.md).

## Storage

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS    # Disk layout
df -h                                         # Free space
sudo dmesg | grep -i -E 'usb|sda|nvme'        # Why didn't my drive mount?
findmnt /mnt/data                             # Show mount options for a path
sudo mount -a                                 # Test+apply /etc/fstab entries
```

Details: [Storage & mounts](05-system/03-storage-mounts.md), [Hardware: storage](01-hardware/03-storage.md).

## Docker (Compose v2)

```bash
docker compose up -d                   # Start stack in current dir
docker compose logs -f --tail=100      # Follow logs
docker compose pull && docker compose up -d   # Update stack
docker compose down                    # Stop stack
docker ps -a                           # All containers
docker system df                       # Disk usage by images/volumes
docker system prune -a                 # ⚠️ Remove ALL unused images/containers
```

Details: [Docker](06-docker/02-compose-patterns.md).

## systemd

```bash
systemctl status <unit>                # Status
sudo systemctl restart <unit>          # Restart
sudo systemctl enable --now <unit>     # Enable + start
journalctl -u <unit> -f                # Follow unit logs
journalctl --disk-usage                # Journal size
sudo journalctl --vacuum-size=200M     # Shrink journal
```

Details: [systemd](05-system/04-systemd.md).

## Backups

```bash
sudo scripts/backup.sh /mnt/backup     # rsync backup to target (run on the Pi)
rsync -aAX --delete --exclude={'/dev/*','/proc/*','/sys/*','/tmp/*','/run/*','/mnt/*','/media/*','/lost+found'} / /path/to/backup/
```

Details: [Backups](05-system/05-backups.md).

## Health check (cron-friendly)

```bash
scripts/healthcheck.sh                 # Temp, throttle, disk, memory, Docker
```

Details: [Monitoring](08-maintenance/01-monitoring.md).

## GPIO / camera (quick)

```bash
pinout                                 # Interactive pin diagram (gpiozero)
rpicam-hello --list-cameras            # Detect cameras (Bookworm libcamera stack)
gpio readall                           # Pin states (wiringpi-style, if installed)
```

Details: [GPIO & peripherals](01-hardware/04-gpio-peripherals.md).
