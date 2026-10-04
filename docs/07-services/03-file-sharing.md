# File sharing — Samba & NFS

Turn a Pi with a big disk into the household file server for Windows/macOS/Linux clients.

> **Applies to:** Raspberry Pi OS with a mounted data disk ([Storage & mounts](../05-system/03-storage-mounts.md))
> **Related:** [Media server](02-media-server.md) · [Storage hardware](../01-hardware/03-storage.md)

## Prep

```bash
# Disk mounted at /mnt/data per the storage doc, with a share dir per purpose
sudo mkdir -p /mnt/data/{media,photos,backups}
sudo chown -R myuser:myuser /mnt/data
```

## Samba (SMB — universal: Windows/macOS/Linux/TVs)

```bash
sudo apt install -y samba
```

Define a share (users must exist as **system** users; Samba then layers its own password store):

```bash
sudo smbpasswd -a myuser        # set the SMB password (can differ from login)

sudo tee -a /etc/samba/smb.conf <<'EOF'
[media]
   path = /mnt/data/media
   browseable = yes
   read only = yes              # media is read-only for clients
   guest ok = no

[photos]
   path = /mnt/data/photos
   browseable = yes
   read only = no
   valid users = myuser, alice
   create mask = 0664
   directory mask = 0775
EOF

testparm                       # validate config
sudo systemctl restart smbd
```

Open the firewall and connect:

```bash
sudo ufw allow from 192.168.1.0/24 to any app Samba
# (or ports: 139,445/tcp)
```

- macOS: Finder → ⌘K → `smb://pi-server.local/media`
- Windows: `\\pi-server.local\media`
- Linux: file manager `smb://…`, or mount: `sudo mount -t cifs //pi-server/media /mnt/pi -o username=myuser`

Per-share audit (recycle bin, hide dotfiles…) — see `smb.conf` docs; keep it minimal.

## NFS (Linux-to-Linux, fastest)

```bash
sudo apt install -y nfs-kernel-server

echo '/mnt/data/media 192.168.1.0/24(ro,sync,no_subtree_check)' | sudo tee -a /etc/exports
echo '/mnt/data/backups 192.168.1.0/24(rw,sync,no_subtree_check,root_squash)' | sudo tee -a /etc/exports

sudo exportfs -ra
sudo ufw allow from 192.168.1.0/24 to any port nfs
```

Client:

```bash
sudo mkdir -p /mnt/media
sudo mount -t nfs pi-server.local:/mnt/data/media /mnt/media
# fstab line for permanence — with the nofail/automount cautions from the storage doc
```

## Samba vs NFS

| | Samba | NFS |
|---|---|---|
| Windows/macOS | ✅ native | needs clients/mounting pain |
| Linux clients | ✅ | ✅ fastest, most transparent perms |
| Smart TVs / media players | ✅ | rarely |
| Auth | per-user passwords | IP-based trusts |

Household rule of thumb: **SMB for people, NFS for machines** (e.g. a Linux HTPC mounting the library).

## Performance notes

- GigE Pi (4/5) saturates ~110 MB/s over SMB from SSD; SD-card-hosted shares will crawl — keep shares on real disks.
- `rsync -avh --progress src/ pi-server:/mnt/data/photos/` is still the admin's friend for bulk moves.
- Time Machine: Samba can host a TM backup share (`fruit`/`time machine` vfs modules — modern samba: add `fruit:time machine = yes` to the share) — a nice Pi job for Mac households.
