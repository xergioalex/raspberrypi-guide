# VNC & RDP — remote desktop

Full graphical access to a Pi desktop from another computer.

> **Applies to:** Raspberry Pi OS **Desktop** images (Lite has no GUI to share)
> **Related:** [SSH](01-ssh.md) · [raspi-config](../03-setup/02-raspi-config.md)

## VNC (RealVNC server, preinstalled)

Enable:

```bash
sudo raspi-config nonint do_vnc 0       # Interface Options → VNC → Yes
sudo systemctl status vncserver-x11-serviced
```

Connect: install [RealVNC Viewer](https://www.realverrypi.com) on your computer → connect to `pi-desktop.local`. Your Imager-created user logs in normally.

**Headless desktop** (no monitor attached) — the virtual desktop must have a resolution:

- `raspi-config` → Display → VNC Resolution → e.g. 1920×1080, or:
  ```bash
  sudo raspi-config nonint do_vnc_resolution 1920x1080 60
  ```

Bookworm runs Wayland (Wayfire): RealVNC supports it; screen-sharing quirks (black screen) are usually the resolution setting above or a Wayland/X11 mismatch — switch to "X11" session at the login screen if a tool misbehaves (gear icon → Raspberry Pi OS on X11).

## RDP (xrdp)

Microsoft's protocol — good when connecting from Windows boxes with mstsc:

```bash
sudo apt install -y xrdp
sudo systemctl enable --now xrdp
sudo adduser xrdp sslcert             # per default docs, usually already right
```

Connect: Windows **Remote Desktop Connection** → `pi-desktop.local` → username/password.

⚠️ **xrdp + RealVNC conflict**: on Bookworm, xrdp's session may clash with an active local Wayland login (black screen on connect). Log out locally first, or dedicate the Pi to one method. Pick **one** of VNC/RDP per machine.

## Which one

| Situation | Use |
|---|---|
| Occasional admin of the desktop Pi, mixed client OS | **VNC** (preinstalled, zero setup) |
| Windows-heavy environment, want native client | **xrdp** |
| No GUI installed (Lite) | Neither — you want SSH (+ optionally X forwarding for single apps) |

## Bonus: single GUI apps over SSH (X11 forwarding)

Works from Linux clients, and from macOS with XQuartz installed:

```bash
ssh -X pi-desktop.local
rpicam-still -o shot.jpg && xdg-open shot.jpg   # GUI opens on your screen
```

Slow over WAN — for real remote use prefer Tailscale + VNC ([Tailscale](03-tailscale.md)).
