# Choosing an OS

Which operating system to flash, 64-bit vs 32-bit, Lite vs Desktop, and when to use an appliance OS.

> **Applies to:** Raspberry Pi OS Bookworm (Debian 12) era and newer
> **Related:** [Imager step-by-step](01-raspberry-pi-imager.md) · [Models](../01-hardware/01-models.md)

## Decision tree

```
Dedicated single purpose? (Home Assistant appliance, Kodi media player, retro console)
  → Flash the appliance OS via Imager ("Other specific-purpose OS")
    Home Assistant OS | LibreELEC | RetroPie | ...
Otherwise (general server/desktop):
  Raspberry Pi OS
  ├── Server / Docker / kiosk shell → Lite (64-bit)
  └── Desktop / needs GUI → Desktop (64-bit)
Special needs (k8s, glibc-version-sensitive, corporate) → Ubuntu Server (64-bit)
```

## Raspberry Pi OS variants

| Variant | When |
|---|---|
| **Lite (64-bit)** | Default for everything headless. ~450 MB fewer packages than Desktop, smaller update surface, more free RAM |
| **Desktop (64-bit)** | Any GUI use: real desktop, browser-based admin, VNC, kiosks with GUI |
| **32-bit (armv7l/armv6l)** | Only for Pi 1 / Pi 2 / Zero (1) — or a specific vendor image that's 32-bit only |

### 64-bit vs 32-bit

- Pi 3B+/4/5/Zero 2 W are all 64-bit CPUs: **use the 64-bit OS**. It's Raspberry Pi's default for these, faster (A76/A72/A53 benefit), and most modern Docker images publish `arm64` builds first.
- 32-bit's remaining niche: Pi 1/Zero(1) (`armv6`) and the rare closed-source binary that's armv7-only.
- **Zero 2 W (512 MB)**: either works; 32-bit Lite wastes less RAM on a single tiny daemon, 64-bit is fine if you need an arm64-only image. Prefer 32-bit Lite for simple sensor nodes.
- Verify what a running system has: `uname -m` → `aarch64` (64-bit) vs `armv7l` (32-bit).

## Appliance OSes (flash-and-go)

| OS | Purpose | Notes |
|---|---|---|
| **Home Assistant OS (HAOS)** | Dedicated Home Assistant appliance | The full HA experience incl. add-on store; the whole box is HA — don't plan to run other services on it. See [Home Assistant](../07-services/01-home-assistant.md) for the HA-in-Docker alternative |
| **LibreELEC / OSMC** | Kodi media center | Boots straight to Kodi |
| **RetroPie / Batocera** | Retro gaming | Batocera needs no setup |
| **OctoPi** | 3D-printer control (OctoPrint) | |
| **DietPi** | Ultra-light Debian | Lighter than RPi OS Lite, friendly installer; fine but non-default for us |

## Ubuntu Server (64-bit)

Use when you specifically need Ubuntu's kernel/package cadence (e.g. MAAS-managed fleets, or software targeting Ubuntu). Ships cloud-init instead of Imager customization (or the classic `network-config`/user-data on the boot partition). Otherwise prefer Raspberry Pi OS — best-supported on Pi hardware (firmware, `raspi-config`, camera stack).

## What about "no OS at all"?

- **Network/PXE boot** (Pi 4/5): boot from a server over Ethernet — advanced, rarely needed; see [Alternative flash methods](03-alternative-flash-methods.md#network-boot).
- **Compute Modules** flash via `rpiboot`/usbboot tooling, out of scope for the standard fleet.

## Fleet defaults (this repo's recommendation)

| Role | OS |
|---|---|
| Server (Docker host, HA container, media, web) | Raspberry Pi OS **Lite 64-bit** |
| Desktop / GUI kiosk | Raspberry Pi OS **Desktop 64-bit** |
| Home Assistant appliance | **HAOS** via Imager |
| Tiny sensor node (Zero 2 W) | Lite (32-bit fine) |
