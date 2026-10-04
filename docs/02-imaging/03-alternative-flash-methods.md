# Alternative flash methods

Scriptable and fallback ways to write an image when Imager's GUI isn't the right tool.

> **Applies to:** advanced users, automation, recovery
> **Related:** [Imager step-by-step](01-raspberry-pi-imager.md) (the default path)

## Raspberry Pi Imager CLI (same engine, no GUI)

`rpi-imager` accepts a headless mode; handy on a Mac/Linux build box:

```bash
rpi-imager --cli \
  --first-run-script first-run.sh \
  ~/Downloads/2026-xx-xx-raspios-bookworm-arm64-lite.img.xz \
  /dev/disk4
```

The `--first-run-script` runs as root on first boot (create users, install packages, join Wi-Fi) — the declarative equivalent of Imager's customization wizard. `--debug` increases verbosity.

## Plain `dd` (raw write)

⚠️ **`dd` destroys the target instantly and asks nothing.** Triple-check `of=`.

```bash
# 1. Download an OS image, e.g. from https://www.raspberrypi.com/software/operating-systems/
curl -LO https://downloads.raspberrypi.com/raspios_lite_arm64_latest

# 2. Decompress
unzip raspios_lite_arm64_latest          # → 2026-xx-xx-raspios-bookworm-arm64-lite.img
# .xz images: xz -d *.img.xz

# 3. Identify the target VERY carefully
diskutil list external                   # macOS
lsblk -d -o NAME,SIZE,MODEL,TRAN         # Linux

# 4. Unmount (macOS) then write
diskutil unmountDisk /dev/disk4
sudo dd bs=4M if=image.img of=/dev/disk4 conv=fsync status=progress
# Linux: of=/dev/sdX (whole disk, no partition number)

# 5. Eject
diskutil eject /dev/disk4
```

macOS quirk: `/dev/rdiskN` (raw device) writes much faster than `/dev/diskN`.

## Other GUI tools

- **balenaEtcher** — cross-platform, pick-file → pick-target → flash. Same destructive-care rules.
- **USBImager** — tiny open-source alternative.

All of them write the same bytes; Imager additionally offers OS download + customization, which is why it's our default.

## Legacy headless config (manual files on the boot partition)

Only when you can't use Imager customization. After flashing (and **before** first boot), mount the `bootfs` partition and create:

```bash
# Enable SSH (empty file)
touch /Volumes/bootfs/ssh

# Create a user (Bookworm+; format = username:encrypted-password)
# Generate: openssl passwd -6
echo 'myuser:$6$xyz...' > /Volumes/bootfs/userconf.txt

# Wi-Fi (Bookworm uses NetworkManager, but wpa_supplicant.conf still gets imported)
cat > /Volumes/bootfs/wpa_supplicant.conf <<'EOF'
country=CO
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
  ssid="YourSSID"
  psk="YourPassword"
}
EOF
```

Imager's wizard writes equivalent firstrun automation and is far less error-prone (no locale keyboard surprises) — prefer it.

## Network boot (PXE) — Pi 4/5, advanced

1. Set `BOOT_ORDER` to include network (`3`), e.g. `BOOT_ORDER=0xf31` via `rpi-eeprom-config`.
2. Run a TFTP + NFS server serving the boot files and rootfs (see Raspberry Pi documentation "Network boot").
3. Use case: laboratories/classrooms or diskless terminals. Overkill for a home fleet.

## Copying / cloning an installed system

- **SD→SD clone** (from another Linux box): `dd` the whole card, or boot the source Pi and run a live `rsync` to a second card in a USB reader (exclude `/proc /sys /dev /run /tmp /mnt /media`).
- **`rpi-clone`** (community tool) clones a running system onto a USB/SD target in-place.
- For servers, prefer **config-as-code**: keep everything in compose files + this repo's scripts, so "rebuild" = flash + bootstrap + `docker compose up -d`. See [Backups](../05-system/05-backups.md).
