#!/usr/bin/env bash
# bootstrap.sh — post-flash provisioning for a Raspberry Pi OS machine.
# Applies the fleet standard from docs/03-setup/03-users-and-security.md.
#
# Usage: sudo ./bootstrap.sh [--hostname NAME] [--docker] [--tailscale] [--yes]
# Safe to re-run (idempotent).
set -euo pipefail

# ---------------------------------------------------------------- helpers ---
log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "run with sudo: sudo $0"

ASSUME_YES=0
WANT_HOSTNAME="" WANT_DOCKER=0 WANT_TAILSCALE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hostname)  WANT_HOSTNAME="${2:?}"; shift 2 ;;
    --docker)    WANT_DOCKER=1; shift ;;
    --tailscale) WANT_TAILSCALE=1; shift ;;
    --yes|-y)    ASSUME_YES=1; shift ;;
    -h|--help)   sed -n '2,5p' "$0"; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
done

confirm() {  # confirm <prompt>
  [[ $ASSUME_YES -eq 1 ]] && return 0
  read -rp "$(printf '\033[1m%s\033[0m [y/N] ' "$1")" ans
  [[ "${ans,,}" == y* ]]
}

on_pi() { grep -q Raspberry /proc/device-tree/model 2>/dev/null; }
on_pi || warn "not a Raspberry Pi — Pi-specific steps still attempted"

# ------------------------------------------------------------ hostname ---
if [[ -n $WANT_HOSTNAME ]]; then
  log "Setting hostname to '$WANT_HOSTNAME'"
  raspi-config nonint do_hostname "$WANT_HOSTNAME"
fi

# ------------------------------------------------------------- packages ---
log "Updating OS (apt update + full-upgrade)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get -y full-upgrade

log "Installing baseline packages"
apt-get install -y \
  git curl wget htop vim tmux jq unzip \
  raspi-utils ufw fail2ban unattended-upgrades \
  avahi-daemon

if command -v raspi-config >/dev/null; then
  log "Checking bootloader EEPROM (Pi 4/5)"
  rpi-eeprom-update -a || warn "rpi-eeprom-update failed — continue and check later"
fi

# ------------------------------------------------------------- sshd ---
log "Hardening SSH (root login off, password auth off IF a key exists)"
mkdir -p /etc/ssh/sshd_config.d
if grep -qE '^\S' /root/.ssh/authorized_keys 2>/dev/null \
   || grep -qE '^\S' ~"${SUDO_USER:-root}"/.ssh/authorized_keys 2>/dev/null; then
  tee /etc/ssh/sshd_config.d/10-hardening.conf >/dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
X11Forwarding no
EOF
  sshd -t
  systemctl restart ssh
  log "SSH: keys-only enforced (verified a key exists first)"
else
  warn "No authorized_keys found — NOT disabling password auth. Install a key:"
  warn "  ssh-copy-id ${SUDO_USER:-root}@$(hostname)"
fi

# ------------------------------------------------------------ firewall ---
log "Configuring ufw (deny incoming, allow outgoing, allow SSH)"
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw --force enable

# ------------------------------------------------------------ fail2ban ---
log "Enabling fail2ban (sshd jail defaults)"
systemctl enable --now fail2ban

# -------------------------------------------------- unattended-upgrades ---
log "Enabling unattended-upgrades (security)"
dpkg-reconfigure -f noninteractive -plow unattended-upgrades

# ---------------------------------------------------------------- docker ---
if [[ $WANT_DOCKER -eq 1 ]]; then
  if command -v docker >/dev/null; then
    log "Docker already installed: $(docker --version)"
  else
    log "Installing Docker Engine + Compose plugin"
    curl -fsSL https://get.docker.com | sh
    # Bounded container logs — saves SD cards (docs/06-docker/01-installation.md)
    mkdir -p /etc/docker
    if [[ ! -f /etc/docker/daemon.json ]]; then
      tee /etc/docker/daemon.json >/dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
    fi
    systemctl enable --now docker
  fi
  if [[ -n ${SUDO_USER:-} ]] && id "$SUDO_USER" >/dev/null 2>&1; then
    usermod -aG docker "$SUDO_USER"
    log "Added '$SUDO_USER' to docker group (re-login to use without sudo)"
  fi
fi

# ------------------------------------------------------------- tailscale ---
if [[ $WANT_TAILSCALE -eq 1 ]]; then
  if command -v tailscale >/dev/null; then
    log "Tailscale already installed"
  else
    log "Installing Tailscale"
    curl -fsSL https://tailscale.com/install.sh | sh
    warn "Run 'sudo tailscale up' to authenticate this machine"
  fi
fi

# ------------------------------------------------------------- finish ---
log "Pruning unused packages"
apt-get autoremove -y

cat <<'EOF'

Bootstrap complete. Suggested next steps:
  1. reboot (hostname / EEPROM changes want it):  sudo reboot
  2. health check:                               scripts/healthcheck.sh
  3. add your stacks under /opt/<name>/compose.yaml  (docs/06-docker/02-compose-patterns.md)

EOF
