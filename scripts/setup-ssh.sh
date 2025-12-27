#!/bin/bash

# Setup SSH for Kubernetes cluster nodes
# Removes old SSH keys and establishes new connections

set -e

IPS=(192.168.1.201 192.168.1.202 192.168.1.203 192.168.1.204)
NAMES=("k8s-master-1" "k8s-worker-1" "k8s-worker-2" "k8s-worker-3")
USER="coderius"

echo "=== Cleaning old SSH host keys ==="
for ip in "${IPS[@]}"; do
    echo "Removing $ip from known_hosts..."
    ssh-keygen -R "$ip" 2>/dev/null || true
done

echo ""
echo "=== Establishing new SSH connections ==="
for i in "${!IPS[@]}"; do
    ip="${IPS[$i]}"
    name="${NAMES[$i]}"
    echo "Connecting to $name ($ip)..."
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$USER@$ip" "hostname" || {
        echo "  ⚠️  Failed to connect to $ip"
        continue
    }
    echo "  ✅ Connected to $name"
done

echo ""
echo "=== SSH setup complete! ==="
echo "You can now run: make ping"
