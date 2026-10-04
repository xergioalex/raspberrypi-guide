# Tailscale — zero-config WireGuard mesh

Reach every Pi from anywhere, and let Pis reach each other, without port-forwarding or exposing anything to the internet.

> **Applies to:** any Pi; our standard answer to remote access
> **Related:** [Networking](../03-setup/04-networking.md) · [SSH](01-ssh.md)

## Why

- Installs in one command, no router changes, no open ports — outbound-only connections.
- WireGuard-based; negligible CPU on a Pi (unlike hosting an OpenVPN server).
- MagicDNS gives every device a stable name (`pi-server.tailnet-name.ts.net`).
- Free tier covers personal fleets (up to 100 devices / 3 users).

## Install (per Pi)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# prints a login URL → open it → auth with Google/GitHub/etc.
```

Verify:

```bash
tailscale status          # every device + IP
tailscale ip -4           # this machine's tailnet IP (100.x.y.z)
ping pi-media             # MagicDNS name, works from tailnet devices
```

Update (apt repo is added automatically):

```bash
sudo apt update && sudo apt install tailscale
```

## Useful flags

```bash
# Accept inbound connections but don't let this Pi reach others (lockdown mode for appliances)
sudo tailscale up --shields-up

# Advertise a subnet route (make your whole LAN reachable via one Pi)
sudo tailscale up --advertise-routes=192.168.1.0/24
#   then enable the route in the Tailscale admin console

# Expose a Pi service to the tailnet on a stable name/port
sudo tailscale serve https /jellyfin http://localhost:8096
```

## SSH over Tailscale

```bash
ssh myuser@pi-server.ts.net          # from laptop on cellular
# or Tailscale's built-in SSH (identity from your tailnet account):
sudo tailscale up --ssh
ssh myuser@pi-server                 # no keys needed, tailnet-authenticated
```

## Operation notes

- `tailscaled` is a systemd service: `systemctl status tailscaled`.
- Key expiry: devices re-auth periodically per your tailnet policy; disable expiry for 24/7 servers in the admin console (Machine → … → Disable key expiry) **before** going on vacation.
- Tailscale + Docker: containers use the host's tailnet via published ports; `tailscale serve` is the simplest way to publish an internal-only container UI.
- Troubleshooting: `tailscale status`, `tailscale ping <peer>` (shows whether it found a direct or relayed path), `sudo journalctl -u tailscaled -e`.
