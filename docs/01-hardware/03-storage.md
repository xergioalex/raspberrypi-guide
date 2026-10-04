# Storage

Choosing boot and data storage: SD cards, USB SSDs, and NVMe on the Pi 5.

> **Applies to:** all models; NVMe section is Pi 5-specific
> **Related:** [Models](01-models.md) · [Storage & mounts](../05-system/03-storage-mounts.md) · [Backups](../05-system/05-backups.md)

## SD cards

- **Class doesn't matter; sustained random I/O does.** Look for **A1/A2 application-performance** rated cards from reputable brands (SanDisk, Samsung, Kingston).
- **Capacity**: 32 GB is the practical minimum for a server (OS + Docker images + logs); 64–128 GB gives breathing room for media/database workloads.
- **Counterfeits are everywhere.** Verify a new card with `f3` (`brew install f3` / `apt install f3`) or H2testw before trusting it:
  ```bash
  f3write /Volumes/CARD && f3read /Volumes/CARD
  ```
- SD cards **wear out**. Log-heavy or database workloads (Home Assistant recorder, Plex, torrenting) belong on an SSD. Mitigations if you must use SD: log less ([journal vacuum](../05-system/04-systemd.md)), use `log2ram`-style caching, or a read-only overlay (`raspi-config` → Performance → Overlay FS).
- SD card slot speeds: the Pi 4/5 DDR50-mode slot tops out around 40–50 MB/s — even a great card won't go faster. Anything I/O-heavy → USB SSD or NVMe.

## USB SSD boot (Pi 4 / Pi 5, works well)

A USB 3.0 SSD is ~10× faster than any SD card and far more durable.

1. Update the bootloader, then set USB-first boot order (Pi 4; Pi 5 usually works out of the box):
   ```bash
   sudo rpi-eeprom-update -a          # apply pending bootloader updates, then reboot
   sudo rpi-eeprom-config             # edit; ensure a line like:
   # BOOT_ORDER=0xf16                 # NVMe(6) → USB(4) → SD(1) → retry(f)
   ```
   Digits are tried right-to-left. `0xf41` = SD first; `0xf416` = NVMe, USB, SD, network.
2. Flash the OS onto the SSD with Imager exactly as for an SD card — see [Imaging](../02-imaging/01-raspberry-pi-imager.md).
3. Plug into a **USB 3.0 port** (blue, on Pi 4 the outer pair? — no: Pi 4/5 USB 3 ports are the ones closest to the center of the board) and power on.

Notes:
- Bus-powered small SSDs (e.g. M.2 in a USB enclosure drawing < 1 A) are fine on Pi 4; on Pi 5 prefer a PSU-backed enclosure or the official 27 W PSU.
- Avoid cheap USB-SATA bridges from no-name brands — UASP quirks cause random disconnects. Kingston/StarTech/UGREEN adapters and official NVKe HATs are known-good.

## NVMe boot (Pi 5 only)

The Pi 5 exposes one PCIe 2.0 x1 lane over an FFC connector. With an M.2 HAT (official, Pimoroni NVMe Base, Geekworm X1001, …) you get real SSD performance (~800–900 MB/s ceiling on Gen2; Gen 3 is forceable but officially unsupported/unstable):

1. Mount the NVMe HAT per its manual (power the HAT appropriately).
2. Flash the OS to the NVMe drive (via USB enclosure or directly on another machine).
3. Boot and confirm: `lsblk` shows `nvme0n1`; `BOOT_ORDER=0xf16` in `rpi-eeprom-config` if it doesn't boot first try.
4. Enable TRIM if not automatic:
   ```bash
   sudo systemctl enable --now fstrim.timer
   ```

## Where to put what (data layout)

```
/boot/firmware   # boot partition (firmware + config.txt)
/                # OS root — keep lean
/opt/<service>   # compose stacks + their bind-mount data (or /srv/<service>)
/mnt/<name>      # mounted bulk media/backup volumes (fstab)
/home/<user>     # user dotfiles, small projects
```

We standardize on `/opt/<service>` for stacks and bind mounts, `/mnt/<name>` for fstab-mounted bulk storage. See [Compose patterns](../06-docker/02-compose-patterns.md).
