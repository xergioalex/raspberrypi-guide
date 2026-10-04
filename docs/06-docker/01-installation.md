# Docker installation (on Raspberry Pi OS)

Install Docker Engine + Compose v2 on Raspberry Pi OS, the supported way.

> **Applies to:** Raspberry Pi OS Bookworm+ (arm64 recommended)
> **Related:** [ARM compatibility](03-arm-compatibility.md) · [Compose patterns](02-compose-patterns.md) · [Users & security](../03-setup/03-users-and-security.md)

## Install (official convenience script)

```bash
curl -fsSL https://get.docker.com | sudo sh
```

This detects ARM (armv7/armv8), adds Docker's apt repo, installs `docker-ce` + the `docker-compose-plugin`. Verify:

```bash
sudo docker version
sudo docker compose version
docker info | grep -E 'Server Version|Architecture'    # Architecture: aarch64
```

## Run without sudo

```bash
sudo usermod -aG docker $USER
newgrp docker          # or log out/in
docker run --rm hello-world
```

⚠️ Note: docker-group membership is root-equivalent on that machine — fine for a personal fleet Pi, not for multi-tenant boxes.

## Enable at boot + resource check

```bash
sudo systemctl enable --now docker
docker info | grep -E 'Total Memory|CPUs'
```

For servers with modest RAM, cap the log files before any container runs — `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
```

```bash
sudo systemctl restart docker
```

(SD-card wear and "where did my disk go" — this one setting prevents most of it.)

## ufw and Docker

**Docker bypasses ufw** for published ports: `-p 8080:80` is reachable from the LAN regardless of `ufw deny`. Rules:

1. Treat `-p` as opening the port, period. Only publish what you mean to expose.
2. Prefer binding to specific interfaces: `-p 192.168.1.50:8096:8096` (LAN only) or `-p 127.0.0.1:8096:8096` (local only → tunnel via SSH/Tailscale).
3. If you need real firewall enforcement with Docker, use the `ufw-docker` tool or iptables `DOCKER-USER` chain — but (1)+(2) usually suffice for a home fleet.

## Unattended upgrades interplay

Docker's apt repo packages update like any other (`apt full-upgrade`). A new Engine version restarts the daemon — running containers survive (live-restore) but check:

```bash
docker info | grep -i live
```

Optionally add `"live-restore": true` to `daemon.json` to make daemon restarts less disruptive.

## Uninstall

```bash
sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker /var/lib/containerd
```

## Pi-specific notes

- 64-bit OS → `aarch64` images: the wide world of multi-arch. 32-bit OS → `armv7`: shrinking world ([ARM compatibility](03-arm-compatibility.md)). One more reason for the 64-bit default.
- Storage: put `/var/lib/docker` on SSD/NVMe if you'll pull many images ([Storage](../01-hardware/03-storage.md)) — image churn wears SD cards.
- Ubuntu hosts: `apt install docker.io docker-compose-v2` also works; we standardize on the upstream repo above for current versions.
