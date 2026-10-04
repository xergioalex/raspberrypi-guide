# Home Assistant

Running Home Assistant on a Raspberry Pi: pick your install type, then the hardware that makes automations reliable.

> **Applies to:** HAOS 13+/2024+ releases, or HA Container on Docker
> **Related:** [OS choices](../02-imaging/02-os-choices.md) · [Compose patterns](../06-docker/02-compose-patterns.md) · [Docker install](../06-docker/01-installation.md)

## Choose the install type (this decision matters most)

| | **HAOS** (appliance OS via Imager) | **Container** (Docker on RPi OS) | Core (venv) |
|---|---|---|---|
| Best for | A Pi dedicated to home automation | A Pi that also runs other stacks | Dev/experiments |
| Add-on store (Point & click Mosquitto, Zigbee2MQTT, Node-RED…) | ✅ | ❌ (self-host companions in Docker) | ❌ |
| Supervisor / one-click updates+backups | ✅ | ❌ (your compose/routine) | ❌ |
| Shares box with media/web stacks | ❌ | ✅ | ✅ |
| Maintenance model | Managed like an appliance | You manage everything | You manage more |

**Fleet guidance**: dedicated Pi → **HAOS** (it's the first-class experience; flash it with [Imager](../02-imaging/01-raspberry-pi-imager.md) → *Other specific-purpose OS*). Shared Pi → **Container** on Docker, described below. Avoid Core for real use.

## Hardware

- Pi 5 (8 GB) or Pi 4 (4 GB+) for a real install; HAOS runs on a 2 GB machine but tightens fast with the recorder database growing. SD minimum 32 GB; **SSD/NVMe strongly recommended** (the recorder DB writes constantly — SD wear's worst customer).
- Radio hardware: a Zigbee coordinator (SLZB-06 PoE Ethernet coordinator, Sonoff ZBDongle-E) + optionally Z-Wave stick. Ethernet-attached coordinators (SLZB-06) survive container/OS churn better than USB ones.
- Reliable power + uptime; sensors reach you only if HA is alive ([Power](../01-hardware/02-power.md)).

## Option A — HAOS (dedicated Pi)

1. Imager → *Other specific-purpose OS* → *Home assistants* → *Home Assistant OS* → (pick machine variant, e.g. Pi 4/5) → write ([full walkthrough](../02-imaging/01-raspberry-pi-imager.md)). Customization (SSH/user) doesn't apply — HAOS manages its own users.
2. Boot, wait ~5–10 min (several internal reboots first boot), browse **`http://homeassistant.local:8123`**.
3. Onboarding wizard: create the HA admin user → set location/units → start adding integrations (it auto-discovers tons on your LAN).
4. Recommended early moves:
   - Settings → System → Backups → schedule + keep N; copy the `.tar` off-box ([Backups](../05-system/05-backups.md)).
   - Add-ons you'll likely want: **Mosquitto broker** (MQTT), **Zigbee2MQTT** (best Zigbee stack), Terminal & SSH, File editor.
   - Enable SSH on the underlying appliance: add-on (port 22222 path differs) — or the debug console; treat HAOS like firmware, not a Linux you customize.

Zigbee2MQTT add-on + a coordinator = pair devices without vendor hubs; network key backup lives in the HA backup.

## Option B — Home Assistant Container (Docker)

```bash
sudo mkdir -p /opt/homeassistant/config
cd /opt/homeassistant
```

`compose.yaml`:

```yaml
services:
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    restart: unless-stopped
    privileged: true               # HA wants broad device/net access; container-mode tradeoff
    network_mode: host             # discovery (mDNS/SSDP) needs host networking
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
      # USB coordinator, if any:
      # - /dev/serial/by-id/xyz:/dev/serial/by-id/xyz
    environment:
      - TZ=America/Bogota
```

```bash
docker compose up -d
# UI: http://<pi-ip>:8123  (onboarding as above)
```

Differences you own in container mode:

- **No add-on store.** Run companions as sibling containers (see [`examples/docker-compose/home-assistant.yml`](../../examples/docker-compose/home-assistant.yml): mosquitto + zigbee2mqtt alongside HA).
- Updates = `docker compose pull && up -d` ([Compose patterns](../06-docker/02-compose-patterns.md#updating-stacks)); HA's own one-click updater is unavailable.
- Backups: HA Settings → System → Backups still works (writes tars into `./config/backups`) — schedule + rsync off-box.

## Making it robust

- **Recorder DB**: default SQLite on SD is the classic slow-down-after-months. Move to an SSD, or add MariaDB as a companion container and point recorder at it. Purge keep_days to taste.
- **Watchdog the stack**: `restart: unless-stopped` + the systemd ordering pattern ([systemd](../05-system/04-systemd.md)).
- **Remote access**: don't port-forward. Tailscale ([doc](../04-remote-access/03-tailscale.md)) or Nabu Casa (funds HA development).
- **Backups off the box** — the config dir *is* your smart home (Zigbee network keys!): nightly rsync via [`scripts/backup.sh`](../../scripts/README.md).
- **Testing automations**: use HA's built-in "Trace" tool before blaming hardware.

## Troubleshooting quick hits

| Symptom | Likely |
|---|---|
| `homeassistant.local` unreachable after fresh HAOS flash | Still booting (10 min) / client lacks mDNS → use the IP |
| Discovery finds nothing (container mode) | Forgot `network_mode: host` |
| Zigbee devices drop after reboot | Coordinator on `/dev/ttyUSB0` (unstable path) → use `/dev/serial/by-id/` or Ethernet coordinator |
| UI slower every month | Recorder DB on SD → SSD/MariaDB + purge |
| "500" after update | Check `docker compose logs homeassistant` / restore last backup |
