# Networking

NetworkManager (`nmcli`) configuration — the Bookworm-era standard: Wi-Fi, static IPs, diagnostics.

> **Applies to:** Raspberry Pi OS Bookworm+ (NetworkManager is the default network manager)
> **Related:** [First boot](01-first-boot.md) · [Tailscale](../04-remote-access/03-tailscale.md) · [Troubleshooting](../08-maintenance/02-troubleshooting.md)

## Concepts

- **NetworkManager (NM)** owns all interfaces. Old `dhcpcd.conf` / `interfaces` advice is obsolete — don't follow it.
- Connections are profiles stored in `/etc/NetworkManager/system-connections/`; `nmcli` edits them.
- Ethernet + Wi-Fi profiles can coexist; NM prefers Ethernet when both are up.
- `.local` hostnames come from **avahi/mDNS** (preinstalled) — that's how `ssh pi-server.local` works.

## Status & diagnosis

```bash
nmcli device status                 # per-interface state
nmcli connection show               # saved profiles
ip -br addr                         # addresses in one line per iface
ip route                            # default gateway
resolvectl status                   # DNS servers in use
ping -c3 1.1.1.1                    # raw connectivity
ping -c3 raspberrypi.com            # DNS
```

## Wi-Fi

```bash
# Scan
nmcli device wifi list

# Join + save profile (auto-reconnects)
sudo nmcli device wifi connect "MySSID" password "MyPassword"

# Hidden SSID
sudo nmcli device wifi connect "MySSID" password "MyPassword" hidden yes

# Change the saved Wi-Fi password
sudo nmcli connection modify "MySSID" wifi-sec.psk "NewPassword"
nmcli connection up "MySSID"

# Prefer 5 GHz band where available (Pi 4/5 support it)
sudo nmcli connection modify "MySSID" 802-11-wireless.band a

# Regulatory domain (must be right or radio is blocked)
sudo iw reg set CO                  # verify: iw reg get
```

## Static IP

**Preferred method: DHCP reservation in your router** (MAC address → fixed IP). Survives reflashing and keeps all config in one place. The Pi's MAC:

```bash
cat /sys/class/net/eth0/address
```

If you must set it on the box:

```bash
sudo nmcli connection modify "preconfigured" \
  ipv4.method manual \
  ipv4.addresses 192.168.1.50/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "1.1.1.1,9.9.9.9"
sudo nmcli connection up "preconfigured"
```

DNS caveat: if `/etc/resolv.conf` says `127.0.0.53`-style local stub, NM's `ipv4.dns` feeds it correctly — do not hand-edit `resolv.conf` (it's generated).

## Hostname

```bash
sudo raspi-config nonint do_hostname "pi-media"
sudo reboot
# then reachable as pi-media.local (mDNS cache can take a minute to refresh on clients)
```

## Ethernet-specific

- Pi 3B+ / 4 / 5 have true GigE (3B+'s is bus-limited to ~300 Mbps — see [Models](../01-hardware/01-models.md)).
- Link status/speed: `sudo ethtool eth0`.
- USB-Ethernet/Wi-Fi dongles show up as regular NM devices (`enx…`, `wlx…` names).

## Sharing / bridging (advanced)

- **Wi-Fi hotspot** on the Pi: `nmcli device wifi hotspot ssid "PiAP" password "changeme123"` (WPA2, needs 8+ char password).
- **Bridge** for VM/containers: create a `bridge` NM profile; used rarely — Docker handles its own networking.

## Ports and listening services

```bash
sudo ss -tulpn                      # who listens where
sudo ufw status verbose             # firewall view — see Users & security
```
