#!/usr/bin/env bash
# healthcheck.sh — one-shot fleet health report for a Raspberry Pi.
# Exit code 0 = healthy, 1 = at least one check failed (cron/agent friendly).
# Docs: docs/08-maintenance/01-monitoring.md
#
# Usage: ./healthcheck.sh [--quiet]
set -uo pipefail

QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

FAILED=0
section() { [[ $QUIET -eq 0 ]] && printf '\n\033[1m== %s ==\033[0m\n' "$*"; }
ok()      { [[ $QUIET -eq 0 ]] && printf '  \033[1;32mOK\033[0m  %s\n' "$*"; }
bad()     { [[ $QUIET -eq 0 ]] && printf '  \033[1;31mBAD\033[0m %s\n' "$*"; FAILED=1; }
na()      { [[ $QUIET -eq 0 ]] && printf '  n/a  %s\n' "$*"; }

# ------------------------------------------------------------------ temp ---
section "Temperature"
if command -v vcgencmd >/dev/null; then
  TEMP_NUM="$(vcgencmd measure_temp 2>/dev/null | tr -dc '0-9.')"
  if [[ -n ${TEMP_NUM:-} ]]; then
    TEMP_INT="${TEMP_NUM%%.*}"
    if   (( TEMP_INT >= 80 )); then bad "SoC ${TEMP_NUM}°C — cooling failing"
    elif (( TEMP_INT >= 70 )); then ok  "SoC ${TEMP_NUM}°C (warm, acceptable)"
    else                          ok  "SoC ${TEMP_NUM}°C"
    fi
  else
    bad "vcgencmd measure_temp returned nothing"
  fi
else
  na "vcgencmd unavailable"
fi

# ------------------------------------------------------------- throttling ---
section "Power/Throttle"
if command -v vcgencmd >/dev/null; then
  THR="$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2)"
  case "${THR:-}" in
    0x0) ok  "throttled=0x0 (clean power history)" ;;
    "")  na  "get_throttled unavailable" ;;
    *)   bad "throttled=$THR — decode in docs/01-hardware/02-power.md" ;;
  esac
fi

# ------------------------------------------------------------------ disk ---
section "Disk"
while read -r mnt cap pct; do
  [[ -z $mnt ]] && continue
  USE_INT="${pct%\%}"
  if   (( USE_INT >= 90 )); then bad "$mnt: ${pct} used of ${cap}"
  elif (( USE_INT >= 80 )); then ok  "$mnt: ${pct} used of ${cap} (tightening)"
  else                          ok  "$mnt: ${pct} used of ${cap}"
  fi
done < <(df -h --output=target,size,pcent -x tmpfs -x devtmpfs 2>/dev/null | tail -n +2)

# ---------------------------------------------------------------- memory ---
section "Memory"
AVAIL_KB="$(free | awk '/^Mem:/ {print $7}')"
TOTAL_KB="$(free | awk '/^Mem:/ {print $2}')"
ok "RAM:  $(free -h | awk '/^Mem:/ {print $7 " available of " $2}')"
ok "Swap: $(free -h | awk '/^Swap:/ {print $3 " used of " $2}')"
if (( TOTAL_KB > 0 && AVAIL_KB * 10 < TOTAL_KB )); then
  bad "less than 10% RAM available — check docker stats / free"
fi

# ----------------------------------------------------------------- units ---
section "Failed systemd units"
FAILED_UNITS="$(systemctl --failed --no-legend 2>/dev/null | head -5)"
if [[ -n $FAILED_UNITS ]]; then
  printf '       %s\n' "$FAILED_UNITS"
  bad "failed units present (see systemctl --failed)"
else
  ok "no failed units"
fi

# --------------------------------------------------------------- docker ---
section "Docker"
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  ok "$(docker ps -q | wc -l | tr -d ' ') container(s) running"
  while read -r name status; do
    [[ -n $name ]] && bad "container: $name ($status)"
  done < <(docker ps -a --filter status=restarting --filter status=dead \
                  --filter status=exited --format '{{.Names}} {{.Status}}')
else
  na "docker not running"
fi

# -------------------------------------------------------------- backups ---
section "Backup freshness"
MARKERS_FOUND=0
for MARKER in /mnt/backup/*/LAST_BACKUP /opt/*/LAST_BACKUP; do
  [[ -f $MARKER ]] || continue
  MARKERS_FOUND=1
  AGE_H=$(( ( $(date +%s) - $(stat -c %Y "$MARKER") ) / 3600 ))
  WHO="$(basename "$(dirname "$MARKER")")"
  if   (( AGE_H > 48 )); then bad "$WHO: last backup ${AGE_H}h ago"
  elif (( AGE_H > 26 )); then ok  "$WHO: last backup ${AGE_H}h ago (aging)"
  else                       ok  "$WHO: last backup ${AGE_H}h ago"
  fi
done
(( MARKERS_FOUND )) || na "no LAST_BACKUP markers found (see scripts/backup.sh)"

[[ $QUIET -eq 0 ]] && printf '\n'
if (( FAILED )); then
  [[ $QUIET -eq 0 ]] && printf 'Result: \033[1;31mATTENTION NEEDED\033[0m\n'
  exit 1
fi
[[ $QUIET -eq 0 ]] && printf 'Result: \033[1;32mHEALTHY\033[0m\n'
exit 0
