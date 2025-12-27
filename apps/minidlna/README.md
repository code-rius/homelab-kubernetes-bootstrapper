# MiniDLNA Media Server

DLNA/UPnP media server for streaming to TVs and other DLNA clients.

## Quick Deploy

```bash
# 1. Create NFS directory on Proxmox
ssh coderius@192.168.1.150 "sudo mkdir -p /ZFS01/nfs-storage/media/{movies,tv,music,photos} && sudo chmod -R 777 /ZFS01/nfs-storage/media"

# 2. Deploy
make deploy-minidlna
```

**Access**:
- Web Interface: `http://192.168.1.201:30200`
- DLNA: Auto-discovered by TVs and media players on your network

## Adding Media

### Via NFS from your Mac

```bash
# Mount NFS share
sudo mkdir -p /mnt/homelab-media
sudo mount -t nfs -o resvport 192.168.1.150:/ZFS01/nfs-storage/media /mnt/homelab-media

# Copy files
cp -r ~/Movies/* /mnt/homelab-media/movies/
cp -r ~/Music/* /mnt/homelab-media/music/

# Unmount when done
sudo umount /mnt/homelab-media
```

### Via SSH to Proxmox

```bash
# Direct copy to NFS server
scp -r ~/Movies/* coderius@192.168.1.150:/ZFS01/nfs-storage/media/movies/
```

### Directory Structure

Organize media in subdirectories:
```
/ZFS01/nfs-storage/media/
├── movies/
├── tv/
├── music/
└── photos/
```

## Storage (NFS)

- **minidlna-media**: 500Gi at `/media`
- Persists across pod restarts and cluster recreation
- Accessible from any node via NFS

## Client Setup

### Smart TV
1. Open media app on your TV
2. Look for "Homelab Media Server" in DLNA/UPnP devices
3. Browse and play content

### VLC
1. View → Playlist → Universal Plug'n'Play
2. Find "Homelab Media Server"
3. Browse content

### iOS/Android
Install DLNA/UPnP apps like:
- VLC
- Plex (DLNA mode)
- BubbleUPnP (Android)

## Management

```bash
# Status
kubectl get all -n minidlna
kubectl get pvc -n minidlna

# Logs
kubectl logs -n minidlna -l app=minidlna -f

# Restart (rescan media)
kubectl rollout restart deployment/minidlna -n minidlna

# Force rescan
kubectl exec -n minidlna deployment/minidlna -- rm -rf /var/cache/minidlna/*
kubectl rollout restart deployment/minidlna -n minidlna

# Shell access
kubectl exec -n minidlna -it deployment/minidlna -- /bin/sh
```

## Supported Formats

- **Video**: MP4, AVI, MKV, MOV, WMV
- **Audio**: MP3, FLAC, AAC, WAV, OGG
- **Images**: JPG, PNG, GIF, BMP

## Troubleshooting

```bash
# Pod not starting
kubectl get pods -n minidlna
kubectl logs -n minidlna -l app=minidlna --tail=100

# TV not discovering server
# Check that pod is on master node with host network
kubectl get pods -n minidlna -o wide
# Ensure firewall allows UDP 1900 (SSDP)

# Web interface not accessible
curl http://192.168.1.201:30200
# Should show MiniDLNA status page

# Storage issues
kubectl get pvc -n minidlna  # Should show Bound
```

## Performance Tips

- Use H.264/AAC MP4 for best TV compatibility
- Keep file names simple (avoid special characters)
- Organize by media type (movies, tv, music)
- MiniDLNA auto-scans on file changes (inotify enabled)

## Cleanup

```bash
kubectl delete namespace minidlna
# NFS data persists - delete manually on Proxmox if needed
```

## Notes

- Uses `hostNetwork: true` for proper DLNA discovery
- Pinned to master node (192.168.1.201) for consistent IP
- Media database cached in pod (rebuilt on restart)
- No transcoding - direct streaming only
