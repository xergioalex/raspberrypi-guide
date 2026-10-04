# Power

Power problems are the #1 source of "mysterious" Pi failures: random reboots, corrupted SD cards, USB devices dropping, Wi-Fi instability. Get power right first.

> **Applies to:** all models
> **Related:** [Models](01-models.md) · [Troubleshooting](../08-maintenance/02-troubleshooting.md)

## Official PSU requirements

| Model | Official PSU | Notes |
|---|---|---|
| Pi 5 | 27 W USB-C (5.1 V / 5 A) | With a 5 V/3 A PSU the Pi runs, but total USB current is capped and peripherals may misbehave |
| Pi 4 | 15 W USB-C (5.1 V / 3 A) | Early boards reject e-marker USB-C cables |
| Pi 3B+ | μUSB 5.1 V / 2.5 A | |
| Zero 2 W | μUSB 5 V / 2 A | |

Rules of thumb:

- Use the official PSU or one with the exact voltage/current rating. "Charger" ≠ "PSU": chargers sag under load.
- Long/thin USB cables cause voltage drop — prefer short, thick cables.
- Powering via a PC USB port is fine for a Zero 2 W, marginal for a Pi 3, and **not** for a Pi 4/5.

## Detecting power problems

```bash
vcgencmd get_throttled
# 0x0 = healthy
# bit 0 (0x1)    currently undervolted
# bit 1 (0x2)    frequency capped *now*
# bit 2 (0x4)    throttled *now*
# bit 3 (0x8)    soft temperature limit active *now*
# bit 16 (0x10000) undervolt has occurred since boot
# bit 17 (0x20000) frequency cap has occurred since boot
# bit 18 (0x40000) throttling has occurred since boot
```

`0x50000` (or any high-bit value) on a Pi that "works fine" means the supply browns out under load — expect SD corruption eventually. Fix the PSU, don't ignore it.

On the desktop, a ⚡ lightning-bolt icon (Pi 3/4) or warning overlay means the same thing.

## Alternatives to wall PSUs

| Method | Notes |
|---|---|
| **PoE / PoE+ HAT** (Pi 3B+/4/5) | Power + data over one Ethernet cable; great for ceiling/attic installs. Mind HAT fan noise and switch power budget |
| **USB UPS** (e.g. APC Back-UPS + NUT) | Graceful shutdown on outage — see [Backups](../05-system/05-backups.md) philosophy; NUT runs fine on ARM |
| **PiJuice / PiSugar HAT** | Battery HATs for Zero/mobile use; integrates with `pijuice` service |
| **12 V → USB-C converters** | Automotive/solar setups; ensure clean 5.1 V at 5 A for Pi 5 — many car adapters can't |
| **GPIO 5 V injection** | Last resort, bypasses protection — avoid |

## Powering down correctly

```bash
sudo poweroff          # or: sudo shutdown -h now
```

Wait for the ACT LED to stop blinking, then unplug. **Never** pull power on a running Pi: the SD card is mounted read-write and yanking power is the top cause of filesystem corruption. For a headless Pi that must survive rude power cuts, see [Storage](03-storage.md) (wear/endurance) and consider an overlay filesystem (`raspi-config` → Performance → Overlay File System) or read-only root.

## Pi 5 power button & RTC

- The Pi 5 has a dedicated power button header; momentary short = graceful poweroff (once an OS with support is booted).
- The Pi 5 has an RTC by default (synced from network); a backup battery header/cell keeps time across power loss — useful for offline logging.
