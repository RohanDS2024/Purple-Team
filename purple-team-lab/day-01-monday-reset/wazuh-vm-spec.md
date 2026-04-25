# Wazuh SIEM VM — Spec Reference

Quick reference for VM 100 settings. Use the web UI to create — these are the values to enter.

## VM 100: wazuh-siem

### General
- VM ID: **100**
- Name: **wazuh-siem**

### OS
- ISO: `ubuntu-22.04-server.iso`
- Type: Linux, 6.x - 2.6 Kernel

### System
| Setting | Value |
|---------|-------|
| Machine | q35 |
| BIOS | OVMF (UEFI) |
| Add EFI Disk | YES → local-zfs |
| Pre-Enroll keys | NO (uncheck) |
| SCSI Controller | VirtIO SCSI single |
| Qemu Agent | YES |

### Disk
| Setting | Value |
|---------|-------|
| Bus/Device | SCSI 0 |
| Storage | local-zfs |
| Disk size | 150 GiB |
| Cache | Default (No cache) |
| Discard | YES (check) |
| SSD emulation | YES (check) |

### CPU
| Setting | Value |
|---------|-------|
| Sockets | 1 |
| Cores | 4 |
| Type | host |

### Memory
| Setting | Value |
|---------|-------|
| Memory (MiB) | 12288 |
| Minimum memory | 12288 |
| Ballooning Device | UNCHECK |

### Network 1 (created at VM creation)
| Setting | Value |
|---------|-------|
| Bridge | vmbr0 (management) |
| Model | VirtIO (paravirtualized) |
| Firewall | uncheck |

### Network 2 (add AFTER creation: Hardware → Add → Network Device)
| Setting | Value |
|---------|-------|
| Bridge | vmbr1 (lab) |
| Model | VirtIO (paravirtualized) |
| Firewall | uncheck |

## Ubuntu install choices

- Language: English
- Keyboard: as appropriate
- Network:
  - Primary NIC (vmbr0): static, IP from network plan, gateway, DNS
  - Secondary NIC (vmbr1): static, **10.10.10.5/24, no gateway**
- Storage: Use entire disk, LVM, no encryption
- Profile:
  - Your name: Rohan
  - Server name: **wazuh-siem**
  - Username: **wazuh**
  - Password: strong, save in password manager
- **OpenSSH server: YES** (toggle on)
- Featured snaps: skip all
- Wait for install to complete, reboot

## Post-install verification

From your laptop:
```bash
ssh wazuh@<wazuh-mgmt-ip>
sudo apt update && sudo apt upgrade -y
sudo timedatectl set-timezone America/New_York   # or your TZ
ip -br addr   # verify both NICs have IPs
```

Both NICs should show:
- ens18 (or similar) — your home network IP
- ens19 (or similar) — 10.10.10.5/24

## Take snapshot

Web UI → VM 100 → Snapshots → Take Snapshot:
- Name: **clean-install**
- Description: "Fresh Ubuntu 22.04, SSH enabled, both NICs configured, before Wazuh install"

This snapshot is your fallback if the Wazuh install goes sideways on Day 3.
