# Firefly III Deployment

Personal finance manager deployed on Kubernetes with PostgreSQL.

## Prerequisites

- NFS storage class configured
- Kubernetes cluster running

## Quick Deploy

**First time setup**:

1. Create secrets from environment files:
   ```bash
   kubectl create namespace firefly-iii
   kubectl create secret generic postgres-secret --from-env-file=postgres-secrets.env -n firefly-iii
   kubectl create secret generic firefly-secret --from-env-file=secrets.env -n firefly-iii
   ```

2. Deploy the application:
   ```bash
   kubectl apply -f namespace.yml
   kubectl apply -f postgres.yml
   kubectl apply -f firefly.yml
   ```

Or use the Makefile:
```bash
make deploy-firefly
```

**Wait for pods to be ready**:
```bash
kubectl wait --for=condition=ready pod -l app=postgres -n firefly-iii --timeout=300s
kubectl wait --for=condition=ready pod -l app=firefly-iii -n firefly-iii --timeout=300s
```

## Access

Firefly III is exposed via NodePort on port 30080.

Access from your home network:
- http://192.168.1.201:30080 (or any worker node IP)

## Security Setup

**Secrets are stored in `.env` files (not committed to git)**:

1. Generate secure credentials:
   ```bash
   # Generate APP_KEY
   echo "base64:$(openssl rand -base64 32)"
   
   # Generate DB password
   openssl rand -base64 24
   ```

2. Update `secrets.env` and `postgres-secrets.env` with your values

3. The secrets are created automatically when you run `make deploy-firefly`

**Note**: `secrets.env` and `postgres-secrets.env` are gitignored and contain actual credentials. Example files are provided for reference.

## Management

```bash
# Check status
kubectl get pods -n firefly-iii
kubectl get pvc -n firefly-iii

# View logs
kubectl logs -n firefly-iii -l app=firefly-iii -f
kubectl logs -n firefly-iii -l app=postgres -f

# Delete everything
kubectl delete namespace firefly-iii
```

## Storage

- PostgreSQL: 10Gi on NFS (database data)
- Firefly: 5Gi on NFS (uploaded files, exports)

## Initial Setup

1. Visit http://192.168.1.201:30080
2. Follow the setup wizard
3. Create your first account
4. Start managing your finances!
