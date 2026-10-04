# CLAUDE.md — Agent guide for this repository

Guidance for any AI agent (Claude, Copilot, etc.) working **on** this repo or answering questions **from** it. Human contributors: these rules apply to you too.

## What this repo is

The canonical documentation set for owning and operating Raspberry Pis (Pi 3, Pi 4, Pi 5, Zero 2 W): imaging, setup, security, networking, Docker, Home Assistant, media servers, web development, monitoring, backups, and recovery. Content must stay useful to two audiences at once: a human following steps, and an agent that needs precise, unambiguous, current instructions.

## Repository layout

```
README.md            # Entry point + documentation map
CLAUDE.md            # This file
docs/
  00-quick-reference.md   # Cheat sheet — keep in sync with the rest
  01-hardware/            # Models, power, storage, GPIO/peripherals
  02-imaging/             # Raspberry Pi Imager, OS choices, alternative flash methods
  03-setup/               # First boot, raspi-config, users/security, networking
  04-remote-access/       # SSH, VNC/RDP, Tailscale
  05-system/              # Updates/firmware, performance, storage, systemd, backups
  06-docker/              # Install, compose patterns, ARM compatibility
  07-services/            # Home Assistant, media, file sharing, web dev
  08-maintenance/         # Monitoring, troubleshooting
scripts/              # bootstrap.sh, backup.sh, healthcheck.sh (+ scripts/README.md)
examples/             # docker-compose stacks, systemd unit templates
```

Numbered prefixes define reading order inside each folder. Cross-link related docs instead of duplicating content — one topic, one home.

## Hard rules

1. **Never fake device state.** If instructions depend on the user's actual Pi (OS version, model, running services), verify live — `cat /etc/os-release`, `uname -m`, `docker ps` — before advising. Don't assume.
2. **Destructive commands require confirmation.** Flashing, `dd`, `mkfs`, `rm -rf`, wiping partitions, `rpi-eeprom-update` changes, disabling services in production: state the blast radius and get explicit user approval first. The `dd` target is the #1 way to destroy the wrong disk.
3. **Bookworm-era tooling is the default.** NetworkManager (`nmcli`), not hand-edited `wpa_supplicant.conf` (legacy fallback only, and say so). OS customization via Imager, not `boot/ssh` files (legacy). `docker compose` (v2 plugin), not `docker-compose`.
4. **No default credentials.** Modern Raspberry Pi OS has no default `pi` user; users are created in Imager or `userconf.txt`. Never suggest flashing without setting credentials.
5. **English only**, GitHub-flavored Markdown, fenced blocks with a language tag. `<angle-brackets>` for placeholders the reader must replace.
6. **Verify platform compatibility** before recommending any Docker image or package: `arm64` (Pi 4/5, Pi 3, Zero 2 W on 64-bit OS), `arm/v7` (32-bit OS on Pi 3/4/Zero 2 W), `arm/v6` (Pi 1/Zero). amd64-only images silently fail — see `docs/06-docker/03-arm-compatibility.md`.
7. **Keep the quick reference in sync.** Anything added to `docs/00-quick-reference.md` must not contradict the detailed docs. When you change a command in a detail doc, grep the quick reference for the old form.

## Writing standards

- Every doc starts with: `# Title`, then a one-line purpose, then `> **Applies to:**` / `> **Related:**` context lines.
- Prefer **verified commands with expected output** over prose descriptions.
- Include a **Rollback / Undo** section for anything that changes system state.
- Include a ⚠️ line immediately above commands that can destroy data or lock the user out (e.g. SSH hardening before keys work).
- Prefer copy-pasteable heredocs/one-liners over "open the file and edit".
- Assume a mixed fleet: flag model-specific differences (Pi 5 power/PCIe, Pi 4 EEPROM boot, Zero 2 W memory limits) instead of writing only for one device.
- Pin or date version-sensitive claims (e.g. "Raspberry Pi OS Bookworm (Debian 12)") and prefer version-agnostic commands.

## Maintenance workflow

- Docs-only change: edit, link-check (`grep -rn '](docs/' README.md docs/ CLAUDE.md | ...`), commit.
- Script change: run `bash -n scripts/<file>.sh` at minimum; smoke-test on a Pi before documenting new behavior.
- Update `scripts/README.md` and the relevant doc whenever a script's flags change.
- Commit message format: `docs: <area>: <summary>` / `scripts: <summary>`.
