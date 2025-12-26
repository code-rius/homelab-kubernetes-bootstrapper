# Manual Kubernetes Setup (The Hard Way)

This directory contains playbooks for setting up Kubernetes manually, following "Kubernetes The Hard Way" methodology.

## Playbooks (in order)

1. `2-ssl-authority.yml` - Generate TLS certificates manually
2. `3-install-binaries.yml` - Download and install Kubernetes binaries manually
3. `4-generate-kubeconfigs.yml` - Create kubeconfig files manually

## Purpose

These playbooks are educational and help understand Kubernetes internals:
- Certificate generation and PKI infrastructure
- Binary installation and placement
- Kubeconfig file structure
- Component authentication

For a working cluster, use the kubeadm playbooks in the parent directory instead.
