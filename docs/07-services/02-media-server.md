# Media server

Jellyfin (or Plex) + the arr-stack + qBittorrent on a Pi, with realistic expectations about transcoding.

> **Applies to:** Pi 4 (4 GB+) / Pi 5 (8 GB recommended); SSD strongly recommended
> **Related:** [Compose patterns](../06-docker/02-compose-patterns.md) · [File sharing](03-file-sharing.md) · [Models](../01-hardware/01-models.md) (video codec tables)

## Set expectations first: transcoding on a Pi

- **Pi 5** has **no hardware video codec blocks** — all decode/encode is software on the CPU. It plays 4K60 HEVC, but *transcoding* (decoding + re-encoding simultaneously) a single 1080p stream can already saturate it.
- **Pi 4** has HW H.264 encode/decode + HEVC 4K60 decode; containers/drivers expose it poorly. Treat it as direct-play-only too.
- **Strategy: eliminate transcoding.** Direct-play to capable clients (modern TVs, phones, browsers handle H.264/HEVC fine), keep library files in client-friendly formats, and let the Pi be a file/server brain, not a video furnace. If you truly need transcodes, that workload wants an x86 box/GPU.

## The stack

| Component | Image | Notes |
|---|---|---|
| Jellyfin | `jellyfin/jellyfin` (FOSS, arm64) | Our default: no accounts/licensing, great clients |
| Plex | `plexinc/pms-docker` (arm64) | If you're already in the Plex ecosystem; hardware transcode on Pi is not a thing |
| Sonarr/Radarr | `linuxserver/sonarr` / `radarr` | TV/movie automation managers |
| Prowlarr | `linuxserver/prowlarr` | Indexer manager for the *arrs |
| qBittorrent | `linuxserver/qbittorrent` | Downloads; WebUI on 8080 |
| Bazarr/Whisper… | linuxserver images | Optional subs/etc. |

Full file: [`examples/docker-compose/media-stack.yml`](../../examples/docker-compose/media-stack.yml) — Jellyfin + Sonarr + Radarr + Prowlarr + qBittorrent wired together (shared network, hardlink-friendly paths).

## Quick start (Jellyfin only)

```bash
sudo mkdir -p /opt/media/jellyfin/config
# put media on a mounted disk: /mnt/media/{movies,tv}
cd /opt/media && $EDITOR compose.yaml   # from the example above
docker compose up -d
```

UI: `http://<pi>:8096`. Wizard: set language → add libraries pointing at `/media/movies`, `/media/tv` (the in-container paths from the compose file) → done. Clients: apps for iOS/Android/Android TV/Fire TV/Roku, plus the web UI.

## The path-mapping rule (avoid double-storage)

Keep one canonical media root and expose it **identically** in every container:

```yaml
    volumes:
      - /mnt/media:/data          # qbittorrent writes /data/downloads
                                   # sonarr/radarr see /data/tv, /data/movies
                                   # jellyfin reads /data/movies, /data/tv
```

Same `/data` prefix everywhere → hardlinks work (instant "move" from downloads to library, zero copy) and no path-remap confusion in the *arrs' settings.

## Library etiquette for Pi-friendly playback

- Prefer H.264/H.265 MP4/MKV with common audio (AAC/AC3) → direct play everywhere.
- Keep subtitle files external (`.srt`) — burning subs into the image forces transcode.
- 4K HDR rips will humble a Pi client-side too; standardize on 1080p unless every client is 4K-capable.

## Operations

```bash
cd /opt/media
docker compose pull && docker compose up -d       # monthly-ish updates
docker compose logs -f jellyfin
docker stats                                      # RAM/pressure check
```

qBittorrent WebUI first-login password is in its logs (`docker compose logs qbittorrent | grep -i password`) — change it immediately, and bind the WebUI to LAN/Tailscale only.

VPN for the torrent client: route qBittorrent through `gluetun` (`qmcgaw/gluetun`, arm64) as its network — see gluetun's docs; the pattern is `network_mode: "service:gluetun"` on the qBittorrent service.

## Storage & backups for this role

- Downloads hammer disks: **SSD or NVMe**, not SD ([Storage](../01-hardware/03-storage.md)).
- Media itself is re-fetchable — back up the *arrs' configs (`./sonarr/config` etc., the databases of what you have/want) and skip the media files ([Backups](../05-system/05-backups.md)).
- Serve the same `/mnt/media` over Samba/NFS for TVs that play from shares directly: [File sharing](03-file-sharing.md).
