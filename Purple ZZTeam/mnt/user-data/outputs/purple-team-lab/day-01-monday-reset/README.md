# Day 1 — Monday Reset

**Goal:** Bare metal → Proxmox installed, configured, with Wazuh SIEM VM provisioned and Ubuntu installed inside it.

**Time budget:** 6–8 hours.

**End of day success criteria:**
- Proxmox web UI accessible at `https://<proxmox-ip>:8006`
- ZFS mirror healthy (`zpool status` shows ONLINE for both disks)
- `vmbr1` lab bridge created
- All 6 ISOs uploaded
- Wazuh SIEM VM exists with Ubuntu installed and SSH working

---

## Phase 1 — Proxmox install (1.5 hours)

1. Boot Proxmox installer USB
2. Select **"Install Proxmox VE (Graphical)"**
3. Accept EULA
4. **Disk selection screen** — this is the important one:
   - Click **Options**
   - Filesystem: **zfs (RAID1)**
   - Select both 600GB SSDs (uncheck any other drives)
   - ashift: 12 (default, leave it)
   - compress: lz4 (default)
   - checksum: on (default)
   - copies: 1 (default — RAID1 already gives redundancy)
   - hdsize: leave at max
   - Click OK
5. Country/timezone/keyboard
6. Password + email (use a real email — system alerts go here)
7. Network:
   - Pick the right NIC (the one connected to your home network)
   - Hostname FQDN: `pve-lab.lan` (or whatever; the hostname before `.` is what shows in UI)
   - IP: from your network plan
   - Gateway + DNS: from your network plan
8. Confirm summary, click **Install**
9. Reboot when prompted, **remove USB**
10. Wait ~2 minutes for first boot

✅ **Verify:** From your laptop, browse to `https://<proxmox-ip>:8006` — accept the self-signed cert, log in as `root@pam`.

---

## Phase 2 — Post-install config (1 hour)

SSH into Proxmox:
```bash
ssh root@<proxmox-ip>
```

### Run the post-install script

Copy-paste the entire block below in one go:

```bash
# 1. Remove enterprise repos (paid subscription required, you don't have one)
rm -f /etc/apt/sources.list.d/pve-enterprise.list
rm -f /etc/apt/sources.list.d/ceph.list

# 2. Add no-subscription repo
cat > /etc/apt/sources.list.d/pve-no-sub.list <<'EOF'
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

# 3. Update everything
apt update
apt full-upgrade -y

# 4. Install useful tools
apt install -y vim htop iftop tmux git curl wget ethtool

# 5. Suppress the "no valid subscription" nag in the web UI
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void(\{ \/\/\1/g" \
  /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy

# 6. Verify ZFS pool health
zpool status
zpool list

# 7. Verify available memory
free -h
```

✅ **Verify:** `zpool status` shows `state: ONLINE` for both disks. `free -h` shows ~40GB total.

---

## Phase 3 — Network setup (45 min)

### Create the isolated lab bridge

```bash
# Back up current config
cp /etc/network/interfaces /etc/network/interfaces.bak

# Append vmbr1 (DO NOT replace the file — only add this block at the end)
cat >> /etc/network/interfaces <<'EOF'

auto vmbr1
iface vmbr1 inet static
    address 10.10.10.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    # No gateway = isolated from internet by default
    # Lab VMs can reach each other and reach Proxmox at 10.10.10.1
EOF

# Apply
ifreload -a

# Verify
ip addr show vmbr1
brctl show
```

✅ **Verify:** `ip addr show vmbr1` shows the interface with IP `10.10.10.1/24`.

### Why no internet on vmbr1?

The lab is intentionally air-gapped. Real attacks shouldn't be able to call out to the real internet. Later, when you need Windows updates or to install Kali tools, you'll temporarily NAT through `vmbr0`. Day-to-day, it stays isolated.

---

## Phase 4 — Upload ISOs (30 min)

Via the **web UI**: `Datacenter → pve-lab → local → ISO Images → Upload`.

Upload all 6 ISOs from your USB drive:
- proxmox-ve_8.x.iso (you can skip — already used)
- WindowsServer2022.iso
- Windows11.iso
- ubuntu-22.04-server.iso
- kali-linux-installer.iso
- virtio-win.iso

Or from CLI (if your USB is mounted on Proxmox):
```bash
# Example — adjust path to your USB mount point
cp /mnt/usb/*.iso /var/lib/vz/template/iso/
ls -lh /var/lib/vz/template/iso/
```

✅ **Verify:** All 5 OS ISOs + virtio-win visible in the Proxmox web UI under `local` storage.

---

## Phase 5 — Create the Wazuh SIEM VM (1.5 hours)

This is the most important VM, build it carefully. Web UI → top right → **Create VM**.

### General tab
- VM ID: 100
- Name: `wazuh-siem`
- Resource Pool: (leave blank)

### OS tab
- Use CD/DVD disc image (ISO): `ubuntu-22.04-server.iso`
- Type: Linux
- Version: 6.x - 2.6 Kernel

### System tab
- Graphic card: Default
- Machine: **q35**
- BIOS: **OVMF (UEFI)**
- Add EFI Disk: **YES** (storage: local-zfs)
- Pre-Enroll keys: **NO** (uncheck — Linux doesn't need MS keys)
- SCSI Controller: **VirtIO SCSI single**
- Qemu Agent: **YES** (check)

### Disks tab
- Bus/Device: SCSI 0
- Storage: local-zfs
- Disk size: 150 GiB
- Cache: Default (No cache)
- Discard: **YES** (check — important for SSD)
- SSD emulation: **YES** (check)

### CPU tab
- Sockets: 1
- Cores: 4
- Type: **host** (gives best performance and exposes CPU features)

### Memory tab
- Memory: 12288 (MiB) = 12 GB
- Minimum memory: 12288 (same — disable ballooning for SIEM)
- Ballooning Device: **uncheck**

### Network tab
- Bridge: **vmbr0** (management network)
- Model: **VirtIO (paravirtualized)**
- Firewall: uncheck (lab convenience)

Click **Confirm** → **Finish**.

### Add second NIC for lab

After creation, select the VM → Hardware → Add → Network Device:
- Bridge: **vmbr1**
- Model: VirtIO

### Start the VM and install Ubuntu

1. Select VM 100 → **Start**
2. Click **Console**
3. Install Ubuntu Server with these choices:
   - Language: English
   - Network: configure both NICs
     - Primary (vmbr0 side): static IP from network plan, gateway, DNS
     - Secondary (vmbr1 side): static `10.10.10.5/24`, NO gateway
   - Storage: use entire disk, LVM, no encryption
   - Profile: name=`wazuh`, hostname=`wazuh-siem`
   - **Install OpenSSH server: YES**
   - No additional snaps
4. Wait for install (~15 min)
5. Reboot when prompted

### Verify SSH works

From laptop:
```bash
ssh wazuh@<wazuh-mgmt-ip>
# enter password
sudo apt update && sudo apt upgrade -y
```

### Snapshot it

Back in Proxmox web UI → VM 100 → Snapshots → Take Snapshot:
- Name: `clean-install`
- Description: "Fresh Ubuntu 22.04, SSH enabled, before Wazuh"

✅ **Verify:** SSH works, snapshot exists.

---

## End-of-day checklist

- [ ] Proxmox web UI accessible
- [ ] ZFS mirror healthy
- [ ] `vmbr1` bridge created at 10.10.10.1/24
- [ ] All ISOs uploaded
- [ ] Wazuh VM exists, Ubuntu installed, SSH working
- [ ] Snapshot `clean-install` taken
- [ ] Lab journal updated with anything weird that happened

---

## If you fall behind

**Hard priority order — finish in this order:**

1. ✅ Proxmox installed and reachable (Phase 1)
2. ✅ vmbr1 bridge exists (Phase 3)
3. ⚠️ ISOs uploaded (Phase 4) — if missing, do tomorrow morning
4. ⚠️ Wazuh VM provisioned (Phase 5) — slip to Tuesday morning if needed

If you only get through Phase 1–3 today, the schedule still works. If you don't get Phase 1 done, that's a real problem — debug it tonight or tomorrow morning before Day 2 work.

---

## Common pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| Proxmox install fails partway | USB is bad / corrupted ISO | Reflash USB, verify ISO checksum |
| Can't reach web UI after install | Wrong IP / gateway | Console in, `ip addr`, fix `/etc/network/interfaces` |
| `apt update` fails | Wrong repo URL or no internet | Check `/etc/apt/sources.list.d/`, verify gateway |
| Subscription nag still appears after sed command | Browser cache | Hard refresh (Ctrl+Shift+R) |
| `vmbr1` doesn't appear | Forgot `ifreload -a` | Run it, or reboot |
| Ubuntu install hangs at "configuring storage" | VirtIO SCSI issue | Verify SCSI Controller is "VirtIO SCSI single" |
| VM extremely slow | CPU type not "host" | Edit VM → CPU → change to host |
