# Performance

Sane defaults and targeted tuning: CPU governor, zram, GPU memory, cooling, and what *not* to bother with.

> **Applies to:** Raspberry Pi OS Bookworm+; model-specific notes inline
> **Related:** [Power](../01-hardware/02-power.md) · [Monitoring](../08-maintenance/01-monitoring.md)

## First: measure, don't guess

```bash
top / htop                      # CPU/memory per process
vmstat 1                        # system-wide CPU/r/io at 1 s cadence
iostat -x 1                     # per-disk utilization (sysstat package)
vcgencmd measure_temp
vcgencmd get_throttled          # power/thermal caps — must be 0x0 under load
```

`scripts/healthcheck.sh` summarizes all of it in one shot.

## The usual suspects, in order

1. **Power problems** → throttling masquerading as "slow Pi" ([Power](../01-hardware/02-power.md)).
2. **SD-card I/O** → anything touching disks a lot (Databases, torrenting, log spam). Fix: USB SSD / NVMe, or reduce writes ([Storage](../01-hardware/03-storage.md)).
3. **Memory pressure → swap death.** Check `free -h` and `vmstat`'s `si/so`. Fix: zram (below), or more RAM / fewer containers on that box.
4. **Single-threaded CPU ceiling** → Pi 5 is ~2–3× a Pi 4 per core; move the workload.

## CPU governor

Default `schedutil`/`ondemand` parks cores when idle — correct for servers. For latency-sensitive work:

```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

Reverts at reboot; make persistent with a systemd unit if truly needed. Cost: higher idle heat/power — rarely worth it.

Max frequency check: `vcgencmd get_config arm_freq` · live: `vcgencmd measure_clock arm`.

## zram — compressed RAM swap (better than SD swap)

Pi OS ships zram. Confirm/enable:

```bash
swapon --show                    # should list /dev/zram0
# if missing:
sudo apt install -y zram-tools
echo -e "ALGO=zstd\nPERCENT=50" | sudo tee /etc/default/zramswap
sudo systemctl restart zramswap
```

Never put swap on the SD card — it wears the card and is slow. zram uses CPU to make RAM go ~2× further.

## GPU memory split

Relevant for desktops/cameras only; servers can take it to the minimum:

```bash
sudo raspi-config nonint do_memory_split 16      # Lite/server: 16 MB
sudo raspi-config nonint do_memory_split 128     # desktop/camera use
```

## Overclocking

- **Pi 5**: fixed-frequency part; no official overclock. Spend on cooling instead.
- **Pi 4**: optional ~1.8–2.0 GHz via `/boot/firmware/config.txt` (`arm_freq=2000` + adequate cooling + a PSU that never browns out). Gains are modest; stability risk is real on a 24/7 box. Our stance: don't, unless a specific bottleneck demands it.
- Legacy Pi 3: `arm_freq=1400`-style bumps — same caveats.

## Cooling

- **Pi 5**: the official **Active Cooler** (or a case with fan) is effectively mandatory for sustained load — throttles ~85 °C otherwise.
- **Pi 4**: idle is fine fanless; sustained compile/media load wants heatsinks+fan or the official case fan.
- Check: `vcgencmd measure_temp` after 10 min of load; target < 80 °C sustained.

## Boot-time micro-tuning (optional)

```bash
systemd-analyze blame | head      # slowest units
systemd-analyze critical-chain    # the critical path to multi-user
```

Disable what you don't use (e.g. `sudo systemctl disable --now ModemManager` on pure-Ethernet boxes). Don't chase milliseconds on a Pi — chase I/O and thermals.
