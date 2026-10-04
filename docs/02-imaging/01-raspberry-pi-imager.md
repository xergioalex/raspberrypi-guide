# Raspberry Pi Imager — full step-by-step

The canonical way to create a bootable SD card / USB SSD / NVMe drive for any Raspberry Pi, including headless (no monitor/keyboard) pre-configuration of user, SSH, and Wi-Fi.

> **Applies to:** Raspberry Pi Imager ≥ 1.8 (current v1.9+), any host OS (macOS, Windows, Linux)
> **Related:** [Choosing an OS](02-os-choices.md) · [First boot](../03-setup/01-first-boot.md) · [Alternative flash methods](03-alternative-flash-methods.md)

## What you need

- A computer (macOS / Windows / Linux) with a card reader or free USB port
- Target media: microSD card (≥ 16 GB, A1-rated — see [Storage](../01-hardware/03-storage.md)) or USB/NVMe drive (Pi 4/5)
- Wi-Fi name + password if the Pi won't be on Ethernet
- The target Pi model (pick the right OS — see below)

## Step 1 — Install Imager

Download from <https://www.raspberrypi.com/software/>:

- **macOS**: `.dmg` (Apple Silicon or Intel), drag to Applications — or `brew install --cask raspberry-pi-imager`
- **Windows**: installer `.exe`
- **Linux**: `.deb`/apt repo per the download page, or the AppImage

## Step 2 — Insert the target media

Plug the SD card (via reader) or the USB SSD into the computer. Note the device — on macOS it appears as a volume under `/Volumes`, on Linux as `/dev/sdX` or `/dev/nvmeXn1`. ⚠️ Everything on the target will be **destroyed**.

## Step 3 — Choose the OS

Click **Choose OS**:

- Default: **Raspberry Pi OS (64-bit)** — the recommended build for Pi 3/4/5/Zero 2 W.
- **Raspberry Pi OS (other)** → **Lite (64-bit)**: no desktop, no bundled GUI apps — the right choice for headless servers (smaller, fewer updates, less attack surface).
- **Raspberry Pi OS (other)** → **(32-bit)**: only for Pi 1/2/Zero (1) or special cases (see [OS choices](02-os-choices.md)).
- **Other general-purpose OS**: Ubuntu, etc. — see [OS choices](02-os-choices.md).
- **Other specific-purpose OS**: Home Assistant OS (dedicated HA appliance), LibreELEC, RetroPie, etc. — flashing these is the supported install path for those appliances.

Our fleet default: **Raspberry Pi OS Lite (64-bit)** for servers, **Raspberry Pi OS Desktop (64-bit)** for desktop/kiosk machines.

## Step 4 — Choose storage

Click **Choose Storage** and pick the card/drive. Imager lists all removable media — double-check the size/name so you don't wipe the wrong disk.

## Step 5 — OS Customization (the important part)

Click the **gear icon** (or press `Ctrl+Shift+X`) **before** writing. This replaces all the old manual `ssh` / `wpa_supplicant.conf` hacks and makes headless setup fully declarative:

| Setting | What to enter | Notes |
|---|---|---|
| **Set hostname** | e.g. `pi-server` | You'll reach it as `pi-server.local`. Name it per role, not per person |
| **Set username and password** | a personal user, strong password | **Mandatory.** Modern Raspberry Pi OS has **no default `pi` user** — without this, you can't log in |
| **Configure wireless LAN** | SSID + password + wireless LAN country (e.g. `CO`, `US`, `DE`) | Country must be set or Wi-Fi is radio-blocked. Skip if Ethernet |
| **Set locale settings** | timezone + keyboard layout | Avoids surprise UTC-offsets and wrong-keyboard passwords |
| **Enable SSH** (Services tab) | ✔ *Use password login* — or better, *allow public-key auth* and paste your **public** key | Public-key is the fleet standard; see [SSH](../04-remote-access/01-ssh.md) |
| **Play sound when finished / telemetry** | to taste | Disable telemetry for privacy |

For repeated fleet provisioning, save/load these settings via the wizard — or use the [CLI flash method](03-alternative-flash-methods.md) with a first-run script.

## Step 6 — Write

Click **Save** / **Next** → confirm the overwrite warning → **Write** (or `Yes` to erase + load). Progress bar shows download + verify phases. On success you get a "OS customized" card; safely eject:

- macOS: `diskutil eject /dev/diskN` or Finder eject
- Linux: `udisksctl power-off -b /dev/sdX` or `sudo eject`
- Windows: "Safely Remove Hardware"

## Step 7 — First boot on the Pi

1. Insert the card / plug the drive (USB 3 port for SSDs).
2. Connect Ethernet now if using it (recommended on first boot — faster and fewer variables than Wi-Fi).
3. Power on. Boot takes 1–3 min on first run (init: filesystem expansion, user creation, SSH key generation — **be patient**; the ACT/PIP LED blinks during SD activity).
4. Find it: `ping <hostname>.local` from a computer on the same LAN, or check your router's DHCP client list.
5. Connect: `ssh <user>@<hostname>.local`.

Continue with [First boot](../03-setup/01-first-boot.md) → then run `scripts/bootstrap.sh`.

## Verifying a headless Pi without a monitor

- Can't find it on the network? Boot with a monitor+keyboard once, log in locally, run `ip -br addr`, confirm `NetworkManager` is managing the interface (`nmcli device status`).
- Still blind? Reflash with a known-good keyboard-layout + password — wrong locale keyboard on first flash is a classic "wrong password" cause.

## Troubleshooting the flash itself

| Symptom | Cause / fix |
|---|---|
| "Write failed / permission denied" writing the card | Card reader or card is faulty/dirty; try another reader; re-insert |
| Verification fails repeatedly | Counterfeit or dying card — run `f3write/f3read` |
| Pi doesn't boot, ACT LED steady or off | Re-seat the card; check [Power](../01-hardware/02-power.md); confirm you flashed an OS for the right model (64-bit needs Pi 3+; Zero 2 W ok) |
| Rainbow screen stuck | Corrupt flash or unsupported image → reflash |
| Green LED blinks 4 long, 4 short (Pi 4/5) | Bad SD / can't read card — reseat/reformat/reflash |
| ssh: connection refused 20+ min after boot | First-boot init still running or SSH wasn't enabled in customization — wait 2 more minutes, then reflash with the Services tab double-checked |
| `hostname.local` doesn't resolve | mDNS (avahi) missing on the *client*: install `avahi`/Bonjour; or use the router DHCP list |

Legacy manual methods (`touch /boot/ssh`, `userconf.txt`, hand-written `wpa_supplicant.conf`) still exist as fallbacks — documented in [Alternative flash methods](03-alternative-flash-methods.md), but Imager customization is the standard.
