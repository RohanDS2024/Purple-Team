#!/bin/bash
# Day 1 — Network setup: add isolated lab bridge vmbr1
# Run on the Proxmox host as root

set -e

echo "=== Setting up vmbr1 (isolated lab network) ==="

# Backup current config
cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%Y%m%d-%H%M%S)
echo "Backed up /etc/network/interfaces"

# Check if vmbr1 already exists
if grep -q "auto vmbr1" /etc/network/interfaces; then
    echo "vmbr1 already configured. Aborting to avoid duplicates."
    echo "Edit /etc/network/interfaces manually if you need to change it."
    exit 1
fi

# Append vmbr1 config
cat >> /etc/network/interfaces <<'EOF'

# === Lab network (isolated, no internet by default) ===
auto vmbr1
iface vmbr1 inet static
    address 10.10.10.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    # Lab VMs reach each other and reach Proxmox at 10.10.10.1
    # No gateway = no internet (intentional for attack lab)
EOF

echo "Added vmbr1 to /etc/network/interfaces"

# Apply
ifreload -a
echo "Reloaded network config"

# Verify
echo ""
echo "=== Verification ==="
ip addr show vmbr1
echo ""
brctl show

echo ""
echo "=== Done. vmbr1 is up at 10.10.10.1/24, isolated. ==="
