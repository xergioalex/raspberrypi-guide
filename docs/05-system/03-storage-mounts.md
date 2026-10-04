# Storage & mounts

Adding disks, mounting at boot, network shares as mounts, filesystem care.

> **Applies to:** Raspberry Pi OS; external USB/NVMe drives and network mounts
> **Related:** [Hardware: storage](../01-hardware/03-storage.md) · [Backups](05-backups.md) · [File sharing](../07-services/03-file-sharing.md)

## Inspect what's attached

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS,MODEL
sudo blkid                       # UUIDs — use these in fstab
findmnt /mnt/data                # options actually in effect for a path
df -h /mnt/data                  # free space
```

## Format a new drive

⚠️ Destroys everything on the target — verify `of=`/device twice.

```bash
# ext4 (default for Linux-only data)
sudo mkfs.ext4 -L data /dev/sda1

# exFAT (for media shared with Windows/macOS)
sudo apt install -y exfatprogs
sudo mkfs.exfat -n MEDIA /dev/sda1
```

## Mount at boot (fstab, the robust way)

```bash
sudo mkdir -p /mnt/data
sudo tee -a /etc/fstab <<EOF
UUID=xxxx-xxxx-xxxx  /mnt/data  ext4  defaults,nofail  0  2
EOF
sudo mount -a                     # mounts now; also validates the line
findmnt /mnt/data                 # confirm
```

`nofail` is **mandatory** on a server: a missing external disk then can't block boot. (Misconfigured fstab without nofail = boot to emergency shell.)

## Mount options cookbook

| FS / use | Options |
|---|---|
| ext4 data disk | `defaults,nofail` |
| SSD with heavy writes | add `noatime` (less metadata churn) |
| USB stick / SD (fatigue-prone) | `noatime,flush` |
| exFAT | `defaults,nofail,uid=1000,gid=1000` (make files user-owned) |
| NTFS (read/write) | install `ntfs-3g`; `defaults,nofail,uid=1000,gid=1000` — prefer ext4/exFAT for new disks |

## TRIM for SSDs

```bash
sudo systemctl enable --now fstrim.timer     # weekly discard — free-space GC
```

## Health

```bash
smartctl -a /dev/sda             # needs smartmontools; works over USB for many bridges
dmesg -w                         # watch for I/O errors / disconnects live
```

Random USB disconnects = power or cable — see [Power](../01-hardware/02-power.md).

## Network mounts (client side)

Mount a NAS share **on demand via systemd automount**, so boot never hangs when the NAS is down:

```fstab
//nas.local/share  /mnt/nas  cifs  credentials=/etc/samba/creds,uid=1000,gid=1000,nofail,x-systemd.automount,x-systemd.idle-timeout=60  0  0
```

```bash
sudo mkdir -p /mnt/nas
sudo chmod 600 /etc/samba/creds   # file contains: username=... / password=...
sudo mount -a
```

NFS equivalent: `nas.local:/export/media /mnt/nas nfs defaults,nofail,x-systemd.automount 0 0`.

**Docker + network mounts warning**: never put a database or anything doing locking/fsync on a CIFS/NFS mount — corrupts eventually. Network mounts are for media/read-mostly data ([Compose patterns](../06-docker/02-compose-patterns.md)).

## Full disk? The routine audit

```bash
df -h | sort -k5 -rn | head
sudo du -xh / --max-depth=2 2>/dev/null | sort -rh | head -20
docker system df                       # images/volumes often the answer
sudo journalctl --disk-usage           # logs creep
```
