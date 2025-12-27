# Firefly III Deployment

Personal finance manager with PostgreSQL, NFS storage, and Tailscale access.

## Quick Deploy

```bash
cd apps/firefly-iii

# 1. Configure secrets
cp secrets.env.example secrets.env
cp postgres-secrets.env.example postgres-secrets.env
echo "APP_KEY=base64:$(openssl rand -base64 32)"
echo "DB_PASSWORD=$(openssl rand -base64 24)"
vim secrets.env postgres-secrets.env  # Add generated values

# 2. Deploy
cd ../..
make deploy-firefly-tailscale  # Tailscale (recommended)
# OR
make deploy-firefly            # NodePort (home network only)
```

**Access**:
- Tailscale: `http://firefly.tail060ef.ts.net`
- NodePort: `http://192.168.1.201:30080`

## Secrets

**secrets.env**:
```bash
APP_KEY=base64:YOUR_KEY
DB_PASSWORD=YOUR_PASSWORD
DB_CONNECTION=pgsql
DB_HOST=postgres.firefly-iii.svc.cluster.local
DB_PORT=5432
DB_DATABASE=firefly
DB_USERNAME=firefly
```

**postgres-secrets.env**:
```bash
POSTGRES_USER=firefly
POSTGRES_PASSWORD=YOUR_PASSWORD  # Must match DB_PASSWORD!
POSTGRES_DB=firefly
```

## Storage (NFS)

- **postgres-data**: 10Gi at `/var/lib/postgresql/data/pgdata`
- **firefly-upload**: 5Gi at `/var/www/html/storage/upload`

Data survives pod restarts, node failures, and cluster recreation!

## Management

```bash
# Status
kubectl get all -n firefly-iii
kubectl get pvc -n firefly-iii

# Logs
kubectl logs -n firefly-iii -l app=firefly-iii -f
kubectl logs -n firefly-iii -l app=postgres -f

# Restart
kubectl rollout restart deployment/firefly-iii -n firefly-iii
kubectl rollout restart deployment/postgres -n firefly-iii

# Update secrets
vim secrets.env postgres-secrets.env
kubectl create secret generic postgres-secret --from-env-file=postgres-secrets.env -n firefly-iii --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic firefly-secret --from-env-file=secrets.env -n firefly-iii --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/{postgres,firefly-iii} -n firefly-iii
```

## Troubleshooting

```bash
# Firefly not loading
kubectl get pods -n firefly-iii
kubectl logs -n firefly-iii -l app=firefly-iii --tail=100

# Database issues
kubectl get pods -n firefly-iii -l app=postgres
kubectl logs -n firefly-iii -l app=postgres --tail=50

# Tailscale issues
kubectl get svc -n firefly-iii firefly-iii  # Check external IP
kubectl get pods -n tailscale
kubectl logs -n tailscale -l tailscale.com/parent-resource=firefly-iii

# Storage issues
kubectl get pvc -n firefly-iii  # Should show Bound
```

## Cleanup

```bash
kubectl delete namespace firefly-iii
make cleanup-tailscale-device
# NFS data persists - delete manually on Proxmox if needed
```
