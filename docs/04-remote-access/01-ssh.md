# SSH

Everything from first connection to a comfortable multi-Pi workflow: keys, client config, agent forwarding, tunnels.

> **Applies to:** client = macOS/Linux/Windows(10+); server = Raspberry Pi OS with SSH enabled
> **Related:** [Users & security](../03-setup/03-users-and-security.md) (server-side hardening) · [First boot](../03-setup/01-first-boot.md)

## First connection

```bash
ssh myuser@pi-server.local
# or by IP
ssh myuser@192.168.1.42
```

The best way to set it up is Imager's *Services → Enable SSH → allow public-key auth* — key installed before first boot.

## Keys

```bash
# Generate (once per client machine)
ssh-keygen -t ed25519 -C "xergioalex@laptop"
# → ~/.ssh/id_ed25519 (private) + ~/.ssh/id_ed25519.pub (public — this is the one you paste)

# Install onto the Pi
ssh-copy-id myuser@pi-server.local
# macOS without ssh-copy-id:
cat ~/.ssh/id_ed25519.pub | ssh myuser@pi-server.local 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys'
```

Permissions matter: `~/.ssh` 700, `authorized_keys` 600, private key 600 — sshd refuses world-writable setups.

Then lock the server to keys-only: [Users & security](../03-setup/03-users-and-security.md#ssh-keys-only).

## Client config (`~/.ssh/config`) — the fleet workflow

One file makes every Pi one word away:

```sshconfig
Host pi-server pi-server.local
    HostName pi-server.local
    User myuser
    IdentityFile ~/.ssh/id_ed25519

Host pi-media
    HostName pi-media.local
    User myuser

Host pi-*
    User myuser
    ServerAliveInterval 60
    Compression yes

# Jump through the server to reach a Pi that's behind it
Host pi-lab-via-server
    HostName 10.8.0.5
    ProxyJump pi-server
```

Now `ssh pi-media` just works — same for `scp`, `rsync`, `sftp`.

## Useful one-offs

```bash
# Run one command, no shell
ssh pi-media 'vcgencmd measure_temp'

# Copy files
scp file.tar.gz pi-media:/tmp/
rsync -avh --progress photos/ pi-media:/mnt/data/photos/

# Mount over SSH (macOS: sshfs-mac; Linux: apt install sshfs)
sshfs pi-media:/mnt/data ~/mnt/pi-media

# Tunnel a web UI to localhost
ssh -L 8096:localhost:8096 pi-media          # then http://localhost:8096

# Reverse tunnel: expose a local dev port on the Pi
ssh -R 9000:localhost:3000 pi-server

# Agent forwarding (use your local key *on* the Pi, e.g. for git pulls)
ssh -A pi-server        # or ForwardAgent yes in ~/.ssh/config — only on hosts you trust
```

## Server-side essentials

```bash
sudo systemctl status ssh         # service name is `ssh` on Debian/RPi OS
sudo ss -tlnp | grep :22          # listening?
sudo journalctl -u ssh -e         # recent auth log
```

Debug a failing client: `ssh -v pi-media` (repeat `-v` for more).

## Key types & passphrases

- `ed25519` is the fleet default — fast, small, modern. RSA-4096 only for legacy targets.
- Protect the private key with a passphrase; let the ssh-agent cache it (`ssh-add`).
- Hardware keys (YubiKey FIDO2: `ssh-keygen -t ed25519-sk`) work fine with OpenSSH ≥ 8.2.

## Windows notes

Windows 10/11 ships OpenSSH (`ssh` in PowerShell/terminal) — everything above works. WSL behaves like Linux. PuTTY still works but its `.ppk` format needs conversion for standard OpenSSH keys (`puttygen`).
