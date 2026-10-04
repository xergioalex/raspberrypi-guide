#!/usr/bin/env bash
# backup.sh — rsync the system (config + /opt stacks + /home) to a target.
# Target: a mounted path (e.g. /mnt/backup) or an ssh destination (user@host:/path).
# Writes a LAST_BACKUP marker so scripts/healthcheck.sh can flag stale backups.
# Docs: docs/05-system/05-backups.md
#
# Usage: sudo ./backup.sh <target>
set -euo pipefail

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[[ $# -eq 1 ]] || { sed -n '2,8p' "$0"; exit 1; }
TARGET="${1:?}"
HOSTNAME_L="$(hostname)"

IS_REMOTE=0
if [[ $TARGET == *:* ]]; then
  IS_REMOTE=1
  REMOTE="${TARGET%%:*}"
  RPATH="${TARGET#*:}"
  command -v rsync >/dev/null || die "rsync not installed"
  ssh "$REMOTE" "mkdir -p '$RPATH/$HOSTNAME_L'" || die "cannot reach $REMOTE"
else
  [[ -d $TARGET ]] || die "target '$TARGET' is not a mounted directory"
fi

DEST="$TARGET/$HOSTNAME_L"

# System config + fleet stacks + users. Bulk media under /mnt is deliberately
# excluded (huge / re-fetchable) — adjust per site (docs/05-system/05-backups.md).
RSYNC_OPTS=(-aAXH --delete --numeric-ids --info=progress2,stats1)
INCLUDES=(/boot/firmware/config.txt /etc /opt /home /root /usr/local/bin)
EXCLUDES=(
  --exclude='/opt/**/node_modules'
  --exclude='/home/*/.cache'
  --exclude='/home/*/.npm'
)

log "Backing up ${INCLUDES[*]} → $DEST"
for src in "${INCLUDES[@]}"; do
  [[ -e $src ]] || { log "skip (absent): $src"; continue; }
  rsync "${RSYNC_OPTS[@]}" "${EXCLUDES[@]}" "$src" "$DEST/system/"
done

# Marker + package manifest (rebuild aid)
PKG_LIST="$(mktemp)"
dpkg --get-selections > "$PKG_LIST"
rsync "${RSYNC_OPTS[@]}" "$PKG_LIST" "$DEST/packages.txt"
rm -f "$PKG_LIST"

if (( IS_REMOTE )); then
  ssh "$REMOTE" "date +%s > '$RPATH/$HOSTNAME_L/LAST_BACKUP' && \
                  printf 'backup of $HOSTNAME_L at %(%F_%H%M)T\n' > '$RPATH/$HOSTNAME_L/LAST_BACKUP.txt'"
else
  date +%s > "$DEST/LAST_BACKUP"
  printf 'backup of %s at %(%F_%H%M)T\n' "$HOSTNAME_L" > "$DEST/LAST_BACKUP.txt"
fi

log "Done: $DEST"
log "Test a restore twice a year — an untested backup is a rumor (docs/05-system/05-backups.md)"
