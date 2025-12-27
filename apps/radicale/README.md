# Radicale CalDAV/CardDAV Server

Simple CalDAV and CardDAV server for calendars and contacts.

## Quick Deploy

```bash
# 1. Create NFS directory on Proxmox
ssh coderius@192.168.1.150 "sudo mkdir -p /ZFS01/nfs-storage/radicale-data && sudo chmod 777 /ZFS01/nfs-storage/radicale-data"

# 2. Deploy
make deploy-radicale

# 3. Create user
kubectl exec -n radicale -it deployment/radicale -- htpasswd -B -c /data/users myusername
```

**Access**: `http://radicale.tail060ef.ts.net`

## Storage (NFS)

- **radicale-data**: 5Gi at `/data`
- Contains: collections, users file, config

Data survives pod restarts, node failures, and cluster recreation!

## User Management

```bash
# Create first user
kubectl exec -n radicale -it deployment/radicale -- htpasswd -B -c /data/users username

# Add additional users
kubectl exec -n radicale -it deployment/radicale -- htpasswd -B /data/users username2

# View users
kubectl exec -n radicale deployment/radicale -- cat /data/users
```

## Client Setup

### iOS/macOS
1. Settings → Passwords & Accounts → Add Account → Other
2. Add CalDAV/CardDAV Account
3. Server: `radicale.tail060ef.ts.net`
4. Username/Password: created above
5. Port: 80 (or leave default)

### Thunderbird
1. Install CardBook add-on for contacts
2. Calendar: Right-click calendar list → New Calendar → On Network → CalDAV
3. URL: `http://radicale.tail060ef.ts.net/username/`
4. Contacts: CardBook → New Address Book → Remote → CardDAV
5. URL: `http://radicale.tail060ef.ts.net/username/`

## Management

```bash
# Status
kubectl get all -n radicale
kubectl get pvc -n radicale

# Logs
kubectl logs -n radicale -l app=radicale -f

# Restart
kubectl rollout restart deployment/radicale -n radicale

# Shell access
kubectl exec -n radicale -it deployment/radicale -- /bin/sh
```

## Troubleshooting

```bash
# Pod not starting
kubectl get pods -n radicale
kubectl logs -n radicale -l app=radicale --tail=100

# Tailscale issues
kubectl get svc -n radicale radicale  # Check external IP
kubectl get pods -n tailscale
kubectl logs -n tailscale -l tailscale.com/parent-resource=radicale

# Storage issues
kubectl get pvc -n radicale  # Should show Bound
```

## Cleanup

```bash
kubectl delete namespace radicale
make cleanup-tailscale-device
# NFS data persists - delete manually on Proxmox if needed
```

## Security Notes

- Radicale uses basic authentication (htpasswd)
- Traffic encrypted via Tailscale (WireGuard)
- Store users file in NFS persistent storage
- Consider using strong passwords
