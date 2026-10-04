# Models & specifications

Reference table for deciding which Pi to use for a workload, and for verifying what a remote device actually is.

> **Applies to:** Raspberry Pi 3B+, 4B, 5, Zero 2 W (the common fleet)
> **Related:** [Power](02-power.md) · [Storage](03-storage.md) · [Choosing an OS](../02-imaging/02-os-choices.md)

## Identify the device you're on

```bash
cat /proc/device-tree/model && echo
# Raspberry Pi 5 Model B Rev 1.0
cat /proc/cpuinfo | grep -E 'Revision|Model'
free -h                                 # Confirms RAM variant
```

## Comparison matrix

| | **Zero 2 W** | **3B+** | **4B** | **5** |
|---|---|---|---|---|
| Released | 2021 | 2018 | 2019 | 2023 |
| SoC | RP3A0 (BCM2710A1) | BCM2837B0 | BCM2711 | BCM2712 |
| CPU | 4× Cortex-A53 @ 1.0 GHz | 4× Cortex-A53 @ 1.4 GHz | 4× Cortex-A72 @ 1.5–1.8 GHz | 4× Cortex-A76 @ 2.4 GHz |
| RAM | 512 MB | 1 GB | 1 / 2 / 4 / 8 GB | 2 / 4 / 8 / 16 GB |
| 64-bit capable | Yes (armv8) | Yes (armv8) | Yes (armv8) | Yes (armv8) |
| Ethernet | — | 1 GbE (via USB2 bus) | True 1 GbE | True 1 GbE |
| Wi-Fi / BT | 802.11n / 4.2 | 802.11ac / 4.2 | 802.11ac / 5.0 | 802.11ac dual-band / 5.0 |
| USB | 1× μUSB OTG (data) | 4× USB 2.0 | 2× USB 3.0 + 2× USB 2.0 | 2× USB 3.0 + 2× USB 2.0 |
| Video out | Mini-HDMI 1080p60 | Full-HDMI 1.4 | 2× micro-HDMI up to 4K | 2× micro-HDMI, dual 4K60 |
| HW video codecs | H.264 enc/dec | H.264 enc/dec, no HEVC | H.264 enc/dec + HEVC 4K60 dec | **None** (software only — CPU is fast enough for 4K60 HEVC playback) |
| GPIO | 40-pin unpopulated | 40-pin populated | 40-pin populated | 40-pin populated |
| Camera/Display | 1× CSI (mini) | CSI/DSI | 2× CSI/DSI (15-pin) | 2× 22-pin MIPI (adapters needed for 15-pin cams) |
| Power input | 5 V / 2 A μUSB | 5 V / 2.5 A μUSB | 5 V / 3 A USB-C | 5 V / 5 A USB-C (27 W for full USB budget) |
| PCIe | — | — | — | 1× PCIe 2.0 x1 (FFC connector → NVMe HAT) |
| Power switch | No | No | No | Yes (dedicated power button header) |
| RTC | No | No | No | Yes (battery-backed with optional header) |

**Not Linux computers** (don't flash an OS onto them): Raspberry Pi Pico / Pico 2 (RP2040/RP2350 microcontrollers, programmed in C/MicroPython), and Compute Modules (CM4/CM5 — same silicon as 4/5 but for carrier boards).

## Which model for which job

| Workload | Recommendation | Why |
|---|---|---|
| Docker host, Home Assistant, media server, web services | **Pi 5 (8 GB)** | A76 cores are ~2–3× a Pi 4; 8 GB fits containers comfortably; NVMe boot |
| Light 24/7 services (DNS, VPN, single small container) | **Pi 4 (4 GB)** or Pi 5 | Pi 4 is still a solid, cheap, low-power server |
| Ad-hoc desktop, retro gaming | Pi 4 / Pi 5 (4–8 GB) | Desktop environment wants RAM; Pi 5 needs the active cooler |
| Sensors, tiny daemons, kiosk with tiny footprint | **Zero 2 W** | Cheap, tiny; 512 MB limits it to Lite OS + one job |
| Learning/experiments, GPIO-heavy projects | Any 40-pin model | 3B+ is fine for slow-rate GPIO |

## Model-specific gotchas agents must remember

- **Pi 5**: requires a 5 V/5 A (27 W) PSU for the full USB current budget — on a 3 A supply USB peripherals are current-limited and brownouts under load are common. Needs active cooling for sustained load. Boots from NVMe with a HAT. No hardware video codec blocks.
- **Pi 4**: USB-C port on early revisions (pre-1.2/1.3) refuses "smart" USB-C cables with e-marker chips — use a dumb cable or official PSU. Bootloader (EEPROM) controls boot order; update it before chasing USB-boot problems.
- **Pi 3B+**: Gigabit Ethernet runs over the USB 2.0 bus → real throughput caps ~300 Mbps. shares that bus with USB devices.
- **Zero 2 W**: 512 MB RAM — use 32-bit Lite for headless single-purpose nodes (a 64-bit userland costs RAM for no benefit here; either works). The data port is the **center** micro-USB (PWR is the outer one). GPIO header is unpopulated — you must solder or use a hammer header.
