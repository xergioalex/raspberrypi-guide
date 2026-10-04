# Compose patterns

How we structure and operate Docker Compose stacks on the Pis — layouts, updates, logging, and the conventions that keep `docker compose up -d` boring.

> **Applies to:** Docker Compose v2 (`docker compose`, no hyphen)
> **Related:** [Installation](01-installation.md) · [systemd integration](../05-system/04-systemd.md#docker-dependency-ordering) · [examples/](../../examples/docker-compose/)

## Standard layout (fleet convention)

```
/opt/<stack>/                    # e.g. /opt/media, /opt/homeassistant
├── compose.yaml                  # the stack (compose.yaml is the v2 default name)
├── .env                          # secrets + tunables (chmod 600, git-ignored)
└── <service>/                    # bind-mount data per service
    └── config/                   # the container's /config or equivalent
```

- **Bind mounts, not named volumes**, so backup = rsync the directory ([Backups](../05-system/05-backups.md)) and nothing hides in `/var/lib/docker/volumes`.
- One stack per *role*; unrelated services get separate dirs so `down`/update blast radius is small.
- `.env` never committed — commit `compose.yaml` + a `.env.example`.

## Minimal solid compose.yaml

```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest       # pin in prod if you prefer
    container_name: jellyfin
    restart: unless-stopped               # the fleet default
    user: "1000:1000"                     # match host user, avoid root-owned files
    ports:
      - "192.168.1.50:8096:8096"          # bind to LAN IP only (see install doc)
    volumes:
      - ./jellyfin/config:/config
      - /mnt/media:/media:ro              # bulk media stays on its mount, read-only
    environment:
      - TZ=${TZ:-America/Bogota}
```

Conventions encoded above:

| Choice | Why |
|---|---|
| `restart: unless-stopped` | survives reboots + crashes; a manual `stop` stays stopped |
| `user: "1000:1000"` | no root-owned bind-mount files; match with `id -u` |
| Interface-bound `ports` | explicit exposure, no accidental 0.0.0.0 |
| `TZ` env | logs and schedulers agree with wall-clock |
| Relative bind mounts (`./...`) | the whole stack is one self-contained, movable directory |

## Networks

Compose creates a per-stack bridge network — services reach each other by **service name** (`http://jellyfin:8096`), never by host IP. That's the DNS you should use in every inter-container URL.

Share a stack with the host LAN properly (e.g. Home Assistant discovery, media casting):

```yaml
services:
  homeassistant:
    network_mode: host        # only when genuinely needed; publishes nothing, sees all
```

Default bridge + published ports is the default; `host` mode is the documented exception for mDNS/discovery-dependent services.

## Updating stacks

```bash
cd /opt/media
docker compose pull                  # newer images
docker compose up -d                 # recreate changed containers
docker image prune -f                # drop orphaned layers
```

Watchtower automates this (`containrrr/watchtower`, multi-arch) — convenient and slightly risky (auto-updates can break things at 3 a.m.). Fleet stance: manual/scripted updates for stacks you care about, Watchtower only on throwaway tooling.

## Logs (keep them bounded)

If `daemon.json` doesn't already cap logs globally ([Installation](01-installation.md)), cap per-service:

```yaml
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "3" }
```

Read them: `docker compose logs -f --tail=100 jellyfin`.

## Devices & hardware passthrough

USB dongles (Zigbee/Z-Wave) and GPUs need explicit access:

```yaml
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0       # serial dongle
    volumes:
      - /dev/vchiq:/dev/vchiq           # (Pi camera/GPU access where applicable)
```

Stable device paths via udev symlink (dongles move between ttyUSB0/1 across reboots):

```bash
# /etc/udev/rules.d/99-usb-serial.rules
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zwave"
```

…then use `/dev/zwave` in compose. (SiLabs CP2102 example — adapt ids from `lsusb -v` or `udevadm info`.)

## Scheduling stack operations

See the [systemd template](../05-system/04-systemd.md#docker-dependency-ordering) to order stacks after mounts, and timers for scheduled `pull && up -d`.

## Debugging checklist

```bash
docker compose ps                      # what's actually running/exit codes
docker compose logs --tail=50 <svc>    # usually answers it
docker inspect <ctr> --format '{{.State.Error}}'
docker exec -it <ctr> sh               # shell inside (if the image has one)
docker stats                           # live CPU/RAM per container
```
