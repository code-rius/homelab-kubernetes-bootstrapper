# Tailscale Kubernetes Operator Setup

This sets up the Tailscale Kubernetes Operator to expose services with Tailscale hostnames.

## Prerequisites

1. Go to https://login.tailscale.com/admin/settings/oauth
2. Click **Generate OAuth client**
3. Add these scopes:
   - `devices:write`
4. Copy the Client ID and Client Secret

## Setup

1. Create OAuth credentials file:
   ```bash
   cp ansible/resources/tailscale-oauth.env.example ansible/resources/tailscale-oauth.env
   ```

2. Edit `tailscale-oauth.env` and add your credentials:
   ```
   OAUTH_CLIENT_ID=k...
   OAUTH_CLIENT_SECRET=tskey-client-...
   ```

3. Deploy Tailscale operator:
   ```bash
   make tailscale
   ```

## Exposing Services

To expose a service via Tailscale, add these annotations:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: my-namespace
  annotations:
    tailscale.com/expose: "true"
    tailscale.com/hostname: "my-app"  # Will become my-app.tailnet-xxx.ts.net
spec:
  type: ClusterIP  # Change from NodePort to ClusterIP
  # ... rest of service config
```

## Example: Firefly III with Tailscale

Deploy Firefly III with Tailscale:
```bash
kubectl apply -f apps/firefly-iii/firefly-tailscale.yml
```

Access at: `https://firefly.tailnet-xxx.ts.net` (from any device on your Tailnet)

## Verify

```bash
# Check operator status
kubectl get pods -n tailscale

# Check exposed services
kubectl get svc -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,TAILSCALE:.metadata.annotations.'tailscale\.com/expose'

# View Tailscale devices
# Go to https://login.tailscale.com/admin/machines
# You should see devices named after your services
```

## Benefits

- ✅ HTTPS by default (via Tailscale's certs)
- ✅ Access from anywhere on your Tailnet
- ✅ No port forwarding needed
- ✅ MagicDNS hostnames
- ✅ Per-service access control via Tailscale ACLs
