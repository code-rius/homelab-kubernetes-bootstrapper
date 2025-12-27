# Homelab Kubernetes Bootstrapper

Automated Kubernetes cluster setup on Proxmox VMs with NFS storage, Tailscale networking, and application deployments.

## Prerequisites

- **Proxmox** with 4 Ubuntu VMs (1 master + 3 workers)
- **NFS share** at `pve:/ZFS01/nfs-storage`
- **Ansible** on your local machine
- **[Tailscale account](https://tailscale.com/)** with [OAuth credentials](https://login.tailscale.com/admin/settings/oauth)

## Quick Start

```bash
# 1. Configure Ansible inventory
vim ansible/inventory/hosts

# 2. Configure Tailscale OAuth
cp ansible/resources/tailscale-oauth.env.example ansible/resources/tailscale-oauth.env
vim ansible/resources/tailscale-oauth.env

# 3. Setup entire cluster (10-15 min)
make setup

# 4. Deploy Firefly III
cd apps/firefly-iii
cp secrets.env.example secrets.env
cp postgres-secrets.env.example postgres-secrets.env
# Generate: openssl rand -base64 32 / openssl rand -base64 24
vim secrets.env postgres-secrets.env
cd ../..
make deploy-firefly-tailscale
```

Access at: `http://firefly.tail060ef.ts.net`

## Commands

### Cluster
```bash
make setup              # Full automated setup
make status             # Check cluster health
make clean              # Reset cluster
```

### Apps
```bash
make deploy-firefly-tailscale  # Deploy with Tailscale
make deploy-firefly            # Deploy with NodePort
make cleanup-tailscale-device  # Remove old devices
```

### Individual Steps
```bash
make ping               # Test connectivity
make hostnames          # Configure /etc/hosts
make install            # Install Kubernetes
make init               # Initialize cluster
make storage            # Deploy NFS provisioner
make tailscale          # Install Tailscale operator
```

## Architecture

- **Kubernetes**: 1.35 with kubeadm
- **CNI**: Flannel (10.244.0.0/16)
- **Runtime**: containerd
- **Storage**: NFS client provisioner
- **Network**: Tailscale LoadBalancer

### Data Persistence

All data on NFS survives VM recreation:
- PostgreSQL: `/firefly-iii-postgres-data-xxx/`
- Uploads: `/firefly-iii-firefly-upload-xxx/`

Rebuild workflow:
```bash
make setup && make deploy-firefly-tailscale  # ~15 min, data persists!
```

## Documentation

- [apps/firefly-iii/README.md](apps/firefly-iii/README.md) - Firefly III deployment guide
- [docs/TAILSCALE-GUIDE.md](docs/TAILSCALE-GUIDE.md) - Tailscale setup and troubleshooting

## Network Configuration

- Master: k8s-master-1 (192.168.1.201)
- Workers: k8s-worker-1/2/3 (192.168.1.202-204)
- NFS: pve (192.168.1.150)

