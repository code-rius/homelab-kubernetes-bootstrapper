# qBittorrent Web Client

BitTorrent client with web UI, accessible via Tailscale. Downloads saved to shared media storage.

## Quick Deploy

```bash
# 1. Create NFS directories on Proxmox
ssh root@192.168.1.150 "mkdir -p /ZFS01/nfs-storage/{media/downloads,qbittorrent/config} && chmod -R 777 /ZFS01/nfs-storage/media /ZFS01/nfs-storage/qbittorrent"

# 2. Deploy
make deploy-qbittorrent
```

**Access**: `http://qbittorrent.tail060ef.ts.net`

## First Login

**Default credentials**:
- Username: `admin`
- Password: Check logs for temporary password

```bash
kubectl logs -n qbittorrent -l app=qbittorrent | grep "password"
```

**Change password immediately**: Tools → Options → Web UI → Authentication

## Configuration

### Download Location

In Web UI:
1. Tools → Options → Downloads
2. Default Save Path: `/downloads` (maps to `/ZFS01/nfs-storage/media`)
3. Organize by category (optional):
   - `/downloads/movies`
   - `/downloads/tv`
   - `/downloads/music`

### Connection Settings

Port `6881` is exposed on all nodes:
1. Tools → Options → Connection
2. Port: `6881` (already configured)
3. Use UPnP: Disabled (manual port forward if needed)

### Network

Downloads happen inside Kubernetes cluster, then saved to NFS. No VPN configured by default.

## Storage (NFS)

- **downloads**: 500Gi at `/downloads` (shared with MiniDLNA at `/ZFS01/nfs-storage/media`)
- **config**: 1Gi at `/config` (qBittorrent settings at `/ZFS01/nfs-storage/qbittorrent/config`)

All data persists across pod restarts and cluster recreation!

## Management

```bash
# Status
kubectl get all -n qbittorrent
kubectl get pvc -n qbittorrent

# Logs
kubectl logs -n qbittorrent -l app=qbittorrent -f

# Restart
kubectl rollout restart deployment/qbittorrent -n qbittorrent

# Shell access
kubectl exec -n qbittorrent -it deployment/qbittorrent -- /bin/bash
```

## Integration with MiniDLNA

Downloads go to `/ZFS01/nfs-storage/media`, same location MiniDLNA scans:

```
/ZFS01/nfs-storage/media/
├── downloads/      ← qBittorrent downloads here
├── movies/         ← Move completed movies here
├── tv/             ← Move completed TV shows here
└── music/          ← Move completed music here
```

MiniDLNA will auto-detect new files via inotify.

### Automatic Organization

Set up categories in qBittorrent:
1. Tools → Options → Downloads → Default Save Path
2. Check "When Category changed" → move files to `/downloads/{category}`
3. Manually move to MiniDLNA folders when complete

## Port Forwarding

If behind NAT/firewall, forward port `6881` (TCP+UDP) to any cluster node IP:
- 192.168.1.201 (master)
- 192.168.1.202 (worker-1)
- 192.168.1.203 (worker-2)  
- 192.168.1.204 (worker-3)

NodePort `30681` on all nodes maps to container port `6881`.

## Troubleshooting

```bash
# Pod not starting
kubectl get pods -n qbittorrent
kubectl logs -n qbittorrent -l app=qbittorrent --tail=100

# Can't access Web UI
kubectl get svc -n qbittorrent qbittorrent-webui  # Check Tailscale IP
kubectl get pods -n tailscale | grep qbittorrent

# Downloads not showing in MiniDLNA
# Check files are in /ZFS01/nfs-storage/media
ssh coderius@192.168.1.150 "ls -la /ZFS01/nfs-storage/media/downloads"

# Force MiniDLNA rescan
kubectl rollout restart deployment/minidlna -n minidlna

# Storage issues
kubectl get pvc -n qbittorrent  # Should show Bound
```

## Performance Tips

- Limit max connections in Web UI (Tools → Options → BitTorrent)
- Set upload limit to preserve bandwidth
- Use categories to organize downloads
- Move completed downloads to appropriate MiniDLNA folders

## Cleanup

```bash
kubectl delete namespace qbittorrent
make cleanup-tailscale-device
# Downloads and config persist - delete manually on Proxmox if needed
```

## Security Notes

- Web UI accessible only via Tailscale
- Change default password immediately
- No VPN configured - traffic visible to ISP
- Consider adding VPN sidecar for privacy
- Torrent port (6881) exposed on local network
