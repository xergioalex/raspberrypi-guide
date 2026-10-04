# Users & security hardening

Turn a fresh install into a defensible server: keys-only SSH, firewall, brute-force protection, automatic updates.

> **Applies to:** Raspberry Pi OS Bookworm+; safe for any fleet Pi exposed to a LAN
> **Related:** [SSH](../04-remote-access/01-ssh.md) · [First boot](01-first-boot.md)

## Users and sudo

Modern Raspberry Pi OS has **no default user** — you created one in Imager. Verify the fleet standard: a personal admin user + key auth.

```bash
whoami && id
sudo usermod -aG sudo myuser        # ensure sudo (usually already)
# Add a teammate (if ever needed)
sudo adduser alice && sudo usermod -aG sudo alice
# Remove a user and their home
sudo deluser --remove-home alice
```

`sudo` is passwordless for the first user via the `sudo` group on Raspberry Pi OS; keep it that way for servers, but understand it means anyone with that shell owns the box.

## SSH: keys only

⚠️ **Do not disable password login until key login is proven working**, or you lock yourself out.

1. On your **computer**: generate + install a key (or select "allow public-key auth" in Imager):
   ```bash
   ssh-keygen -t ed25519 -C "xergioalex@laptop"
   ssh-copy-id myuser@pi-server.local
   ssh myuser@pi-server.local         # must work WITHOUT a password now
   ```
2. On the **Pi**, harden sshd:
   ```bash
   sudo tee /etc/ssh/sshd_config.d/10-hardening.conf <<'EOF'
   PermitRootLogin no
   PasswordAuthentication no
   KbdInteractiveAuthentication no
   X11Forwarding no
   EOF
   sudo sshd -t && sudo systemctl restart ssh    # sshd -t validates before restart
   ```
3. Keep the current session open; open a **new** terminal and confirm key login still works before closing anything.

Full SSH doc (client config, jump hosts, agent): [SSH](../04-remote-access/01-ssh.md).

## Firewall (ufw)

```bash
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'      # ALWAYS allow SSH before enabling
sudo ufw enable
sudo ufw status verbose
```

Add per role — remember Docker **bypasses ufw** for published ports (see [Docker install](../06-docker/01-installation.md#ufw-and-docker)):

```bash
sudo ufw allow 80,443/tcp   comment 'web'
sudo ufw allow from 192.168.1.0/24 to any port 8096 comment 'jellyfin LAN only'
```

## Brute-force protection (fail2ban)

```bash
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd        # see banned IPs / stats
```

Defaults protect sshd (10 min ban after 5 failures in 10 min) — sane for a LAN. Tune in `/etc/fail2ban/jail.local` (never edit `jail.conf`).

## Automatic security updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades   # enable security updates
```

## Other quick wins

```bash
# Unused software off (Lite is already minimal)
sudo apt purge -y --autoremove wolfram-engine chromium-browser   # desktop images only

# Check listening services — every open port should be intentional
sudo ss -tulpn

# Avahi/mDNS: fine on home LAN, disable on hostile networks
# Bluetooth: off if unused
sudo systemctl disable --now bluetooth
```

## What "hardened" means for this fleet (target state)

- [x] User with strong password/key created via Imager (no default creds)
- [x] SSH: keys only, root login off
- [x] ufw on, default-deny incoming, explicit per-service allows
- [x] fail2ban running on sshd
- [x] unattended-upgrades for security patches
- [x] No services listening that you can't name (`ss -tulpn` clean)
- [ ] Optional: [Tailscale](../04-remote-access/03-tailscale.md) instead of exposing anything beyond the LAN

`scripts/bootstrap.sh` applies all of this in one run.
