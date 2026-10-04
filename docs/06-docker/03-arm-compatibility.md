# ARM compatibility

Why some Docker images won't run on a Pi, how to check before you pull, and how to build ARM images from anywhere.

> **Applies to:** every Pi (all are ARM); most painful on 32-bit OSes
> **Related:** [Models](../01-hardware/01-models.md) · [Choosing an OS](../02-imaging/02-os-choices.md) (why 64-bit)

## The platform map

| Platform string | Runs on |
|---|---|
| `linux/arm64` (= `linux/arm64/v8`) | Pi 3/4/5/Zero 2 W **with 64-bit OS** (`uname -m` → `aarch64`) |
| `linux/arm/v7` | Any Pi 2+/3/4/5 with 32-bit OS (`armv7l`); *not* Pi 1/Zero(1) |
| `linux/arm/v6` | Pi 1 / Zero (1) |
| `linux/amd64` | **Not a Pi.** x86 servers — this is the one that breaks people |

Multi-arch images (`linux/amd64,linux/arm64,...`) just work — Docker picks your platform. **Single-arch amd64 images are the failure mode**: classic error on pull/run:

```
WARNING: The requested image's platform (linux/amd64) does not match the detected platform (linux/arm64/v8)
exec format error
```

`exec format error` = wrong architecture. No, it's not fixable with a flag — you need an ARM build of that software.

## Check before you commit

```bash
# What images does a repo publish?
docker manifest inspect ghcr.io/home-assistant/home-assistant:stable | grep -A2 platform

# What am I?
uname -m && docker version --format '{{.Server.Arch}}'

# Did an already-pulled image match?
docker image inspect <image> --format '{{.Os}}/{{.Architecture}}'
```

Rules of thumb:

- Big popular projects (linuxserver.io, jellyfin, home-assistant, traefik, caddy, postgres, redis, nginx, node, python) publish `arm64` — fine on our 64-bit default.
- Small/niche/self-published projects are often amd64-only. Check first; look for an ARM issue/PR; sometimes an alternative exists (e.g. `ghcr.io/linuxserver/...` rebuild).
- 32-bit (`arm/v7`, `arm/v6`) support is **shrinking** industry-wide — the strongest argument for the 64-bit fleet default.

## Emulation: run amd64-only images anyway (slow)

QEMU binfmt lets an ARM host execute amd64 binaries at ~5–20× slowdown. Emergency-only (a one-off CLI tool), not a service:

```bash
docker run --platform linux/amd64 <image>   # works if qemu binfmt is registered
```

Sometimes needed: `docker run --privileged --rm tonistiigi/binfmt --install amd64`.

## Building ARM images (from an x86 laptop, CI, or the Pi)

From your Mac/x86 box with buildx (multi-arch, the normal case):

```bash
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t user/app:latest --push .
```

On the Pi itself, builds are native (no emulation needed) — just slower than a beefy x86 builder. To cross-compile efficiently, use multi-stage builds with the compiler image for the *target* arch (Go/Rust cross-compile trivially; see Docker's multi-arch guides).

## ARM image quirks to remember

- Java apps: use `eclipse-temurin:*-jre` variants with the right arch tag (they're multi-arch anyway).
- Prebuilt binaries in Dockerfiles (`wget`-ing a release .tar.gz) are the #1 cause of broken "multi-arch" images — a Dockerfile can be arch-agnostic and still ship amd64 blobs.
- Electron/Chromium-in-container on ARM: painful; prefer native OS packages.
- Watch RAM, not just arch: a 512 MB Zero 2 W can run the arch-correct image and still OOM.
