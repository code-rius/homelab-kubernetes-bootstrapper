# Tailscale Kubernetes Operator

Expose Kubernetes services securely via Tailscale mesh network (WireGuard VPN).

## Prerequisites

1. **[Tailscale account](https://tailscale.com/)** (free)
2. **[OAuth credentials](https://login.tailscale.com/admin/settings/oauth)**
   - Generate OAuth client with `devices:write` scope
3. **[ACL tags](https://login.tailscale.com/admin/acls)**
   ```json
   {
     "tagOwners": {
       "tag:k8s-operator": [],
       "tag:k8s": []
     }
   }
   ```

## Setup

```bash
# 1. Configure OAuth
cp ansible/resources/tailscale-oauth.env.example ansible/resources/tailscale-oauth.env
vim ansible/resources/tailscale-oauth.env  # Add CLIENT_ID and CLIENT_SECRET

# 2. Deploy operator
make tailscale

# 3. Verify
kubectl get pods -n tailscale
```

## Expose Services

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    tailscale.com/hostname: "my-app"
spec:
  type: LoadBalancer
  loadBalancerClass: tailscale
  ports:
  - port: 80          # External (use 80 to avoid :port in URL)
    targetPort: 8080  # Internal
```

Access at: `http://my-app.tail060ef.ts.net`

**Traffic flow**: Browser → Tailscale mesh (WireGuard) → Proxy pod → Service → App pod

## Management

```bash
# Check resources
kubectl get all -n tailscale
kubectl get svc <svc-name> -n <namespace>  # Check external IP

# View logs
kubectl logs -n tailscale ts-<service>-xxx-0

# Cleanup old devices
make cleanup-tailscale-device
```

## Troubleshooting

**Service not accessible**:
```bash
kubectl get svc -n <namespace> <service>  # Verify external IP
kubectl get pods -n tailscale              # Check proxy pod
kubectl logs -n tailscale ts-<service>-xxx-0
```

**Device creation fails** (`tags invalid` error):
- Add ACL tags (see Prerequisites)

**Hostname conflict** (e.g., "firefly-1" instead of "firefly"):
```bash
make cleanup-tailscale-device
kubectl delete svc <service> -n <namespace>
kubectl apply -f <service-file>.yml
```

**Security**: HTTP over Tailscale is secure (WireGuard encryption at network layer)

## Resources
- [Operator Docs](https://tailscale.com/kb/1236/kubernetes-operator)
- [OAuth Clients](https://tailscale.com/kb/1215/oauth-clients)
- [ACLs](https://tailscale.com/kb/1018/acls)
