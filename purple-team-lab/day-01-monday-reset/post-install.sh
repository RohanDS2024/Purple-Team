#!/bin/bash
# Day 1 — Proxmox post-install configuration
# Run on the Proxmox host as root, AFTER initial install completes
# Usage: ssh root@<proxmox-ip>, then: bash post-install.sh

set -e

echo "=== Proxmox post-install configuration ==="

# 1. Remove enterprise repos (paid subscription required)
echo "[1/6] Removing enterprise repos..."
rm -f /etc/apt/sources.list.d/pve-enterprise.list
rm -f /etc/apt/sources.list.d/ceph.list

# 2. Add no-subscription repo
echo "[2/6] Adding no-subscription repo..."
cat > /etc/apt/sources.list.d/pve-no-sub.list <<'EOF'
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

# 3. Update everything
echo "[3/6] Updating packages (this takes a few minutes)..."
apt update
apt full-upgrade -y

# 4. Install useful tools
echo "[4/6] Installing tools..."
apt install -y vim htop iftop tmux git curl wget ethtool

# 5. Suppress the subscription nag
echo "[5/6] Removing subscription nag..."
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void(\{ \/\/\1/g" \
  /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy

# 6. Verify ZFS pool health
echo "[6/6] ZFS pool status:"
zpool status
echo ""
echo "ZFS pool list:"
zpool list

echo ""
echo "Memory:"
free -h

echo ""
echo "=== Done. Proxmox is ready for VM provisioning. ==="
echo "Next step: configure /etc/network/interfaces to add vmbr1"
echo "See network-setup.sh in this folder."
