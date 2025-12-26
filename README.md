# Homelab Kubernetes Bootstrapper

Automated Kubernetes cluster setup on Proxmox VMs using Ansible and kubeadm.

## Prerequisites
- Hardware with Proxmox installed
- SSH access to Proxmox
- 4 Ubuntu VMs provisioned (1 master, 3 workers)

## Quick Setup

```bash
# 1. Test connectivity
make ping

# 2. Configure hostnames
make hostnames

# 3. Install Kubernetes components
make install

# 4. Initialize cluster
make init

# 5. Check cluster status
make status
```

That's it! Your cluster should be ready in ~10 minutes.

## Commands

- `make ping` - Test Ansible connectivity
- `make hostnames` - Configure /etc/hosts on all nodes
- `make install` - Install kubeadm, kubelet, kubectl
- `make init` - Initialize cluster and join workers
- `make status` - Check cluster status
- `make clean` - Reset cluster (destructive!)

## Manual Setup (The Hard Way)

For learning purposes, manual setup playbooks are in `ansible/playbooks/manual-setup/`:
- `make certificates` - Generate TLS certificates manually
- `make kubeconfigs` - Create kubeconfig files manually

These help understand Kubernetes internals but aren't needed for a working cluster.

## Cluster Details

- **Master**: k8s-master (192.168.1.201)
- **Workers**: k8s-worker-01/02/03 (192.168.1.202-204)
- **Pod Network**: 10.200.0.0/16 (Calico CNI)
- **Service Network**: 10.32.0.0/24
- **Kubernetes Version**: 1.35

