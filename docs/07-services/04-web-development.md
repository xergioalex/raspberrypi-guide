# Web development on the Pi

Using a Pi as a deployment target and light dev box: Node, Python, reverse proxies, TLS, and serving your projects.

> **Applies to:** Raspberry Pi OS Lite (64-bit); Pi 4/5 class machines
> **Related:** [systemd](../05-system/04-systemd.md) (run your app) · [Compose patterns](../06-docker/02-compose-patterns.md) (or containerize instead)

## Two supported shapes

1. **Native service**: app on disk + systemd unit + reverse proxy. Lowest overhead, instant restarts. Good default for one or two apps.
2. **Container**: compose stack per app ([patterns](../06-docker/02-compose-patterns.md)). Best when the app ships a Dockerfile anyway.

Either way, the reverse-proxy front door is the same.

## Runtimes

### Node.js

```bash
# Via nodesource (system-wide, apt-managed)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
node -v && npm -v

# Global install dir without sudo (optional)
mkdir -p ~/.npm-global && npm config set prefix '~/.npm-global'
```

(Per-user `nvm` is fine for tinkering; for a server prefer the system install so systemd units get a stable `/usr/bin/node` path.)

Run your app as a service — [`examples/systemd/myapp.service`](../../examples/systemd/myapp.service):

```bash
sudo systemctl enable --now myapp
curl -s localhost:3000/health
```

### Python

```bash
sudo apt install -y python3-venv python3-pip
python3 -m venv /opt/myapp/.venv
/opt/myapp/.venv/bin/pip install -r requirements.txt
# point the systemd unit's ExecStart at /opt/myapp/.venv/bin/gunicorn ...
```

`uv` (fast modern pip alternative, arm64-native) is a fine upgrade: `curl -LsSf https://astral.sh/uv/install.sh | sh`.

### Static sites / PHP

- Static: drop files, let the reverse proxy serve them.
- PHP: `sudo apt install -y php-fpm` + proxy pass to the php-fpm socket.

## Reverse proxy

### Caddy (our default — automatic HTTPS)

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy
```

`/etc/caddy/Caddyfile`:

```caddy
# Real domain (needs port 80/443 forwarded to the Pi):
app.example.com {
    reverse_proxy localhost:3000
}

# LAN-only, self-signed-free HTTPS via internal CA:
pi-server.local {
    tls internal
    reverse_proxy localhost:3000
}
```

```bash
sudo systemctl reload caddy
```

Certificates/renewals/redirects: all automatic.

### nginx (when you want classic)

```bash
sudo apt install -y nginx
sudo tee /etc/nginx/sites-available/myapp <<'EOF'
server {
    listen 80;
    server_name app.example.com;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

Add TLS with certbot: `sudo apt install -y certbot python3-certbot-nginx && sudo certbot --nginx`.

## Deployment workflow (git → Pi)

On your computer:

```bash
ssh pi-server 'mkdir -p /opt/myapp && git init --bare /srv/git/myapp.git'   # one-time, or use GitHub
# simplest: pull from GitHub on the Pi
```

On the Pi (repeatable update):

```bash
cd /opt/myapp && git pull
npm ci --omit=dev && npm run build
sudo systemctl restart myapp
```

Wrap those three lines in a `deploy.sh` in the repo and you have CI-lite. For real CI, GitHub Actions self-hosted runner runs fine on a Pi 5 (arm64).

## Exposing services beyond the LAN

In preference order (safest first):

1. **Tailscale-only** ([doc](../04-remote-access/03-tailscale.md)) — zero exposure, great for personal tools.
2. **Cloudflare Tunnel** (`cloudflared`, arm64) — public hostname without opening ports.
3. **Port-forward 80/443 + Caddy automatic TLS** — the classic; only for things that must be public.

## Dev-on-the-Pi itself

VS Code Remote-SSH makes the Pi a first-class target: install the extension on your computer, `code` → Connect to Host → `pi-server` → full editor with the Pi's runtime. Compiling big projects: cross-compile or build Docker images elsewhere — the Pi is happy to *run*, less to *build* ([Performance](../05-system/02-performance.md)).
