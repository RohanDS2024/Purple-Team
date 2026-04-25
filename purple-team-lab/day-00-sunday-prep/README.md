# Day 0 — Sunday Prep

**Goal:** Have everything ready so Monday's reset is just execution. No hardware changes today.

**Time budget:** 4–6 hours, mostly waiting on downloads.

---

## Checklist

### Downloads (start these FIRST — they take hours)

Save all to a USB drive or external storage that survives the reset.

- [ ] **Proxmox VE 8.x ISO** (~1.3GB) — https://www.proxmox.com/en/downloads/category/iso-images-pve
- [ ] **Windows Server 2022 Evaluation** (~5GB) — https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022
- [ ] **Windows 11 Enterprise Evaluation** (~6GB) — https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise
- [ ] **Ubuntu Server 22.04 LTS** (~2GB) — https://ubuntu.com/download/server
- [ ] **Kali Linux Installer** (~4GB) — https://www.kali.org/get-kali/#kali-installer-images
- [ ] **VirtIO Windows drivers ISO** (~600MB) — https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

> **Why VirtIO drivers matter:** Without them, Windows VMs on Proxmox use slow IDE/E1000 emulation. With them, you get near-native disk and network speed. Most "Windows is slow on my Proxmox" complaints are missing VirtIO drivers.

### Backup what you have (existing server)

- [ ] List current VMs/LXCs you want to recreate later — see `existing-state.md` template in this folder
- [ ] Push any local git repos to GitHub (verify SCALPEL is pushed)
- [ ] Export SSH keys, certificates, anything irreplaceable to external storage
- [ ] Anything personal on the server → external drive or cloud

### Bootable USB

- [ ] Find a USB drive ≥2GB (8GB+ ideal — you can store the other ISOs on it too)
- [ ] Flash Proxmox ISO with **balenaEtcher** (Mac/Linux/Windows) OR **Rufus** (Windows)
  - If using Rufus: when prompted, choose **DD mode**, NOT ISO mode. The Proxmox ISO is hybrid and Rufus's default ISO mode breaks it.
- [ ] Verify the USB boots: plug into the server, check BIOS sees it (don't actually install yet)

### Network plan (write this down on paper)

Fill in the table in `network-plan.md` (see template in this folder). You need:

- [ ] Proxmox host IP on your home network
- [ ] Wazuh SIEM management IP on your home network
- [ ] Lab subnet for `vmbr1` (recommended: 10.10.10.0/24)
- [ ] Your home network's gateway and DNS

### Account/key prep

- [ ] GitHub account ready
- [ ] Decide repo name (suggested: `purple-team-lab`)
- [ ] Generate SSH key for Proxmox if you don't have one: `ssh-keygen -t ed25519 -C "rohan@purple-lab"`
- [ ] Pick a strong root password — you'll type it many times. Memorable + strong.
- [ ] Save credentials in a password manager NOW, not after the install

### Read-ahead (~45 minutes total)

Don't skip this — these save hours during the install.

- [ ] Skim **Proxmox VE Installation Guide**: https://pve.proxmox.com/wiki/Installation — focus on the "Advanced ZFS Options" section
- [ ] Read **Wazuh quickstart**: https://documentation.wazuh.com/current/quickstart.html — understand the all-in-one installer
- [ ] Read **SwiftOnSecurity Sysmon README**: https://github.com/SwiftOnSecurity/sysmon-config — understand what's logged

---

## Files in this folder

- `network-plan.md` — Template to fill in your IP addresses
- `existing-state.md` — Inventory of what's on the server now
- `download-checklist.md` — Quick-reference download URLs

---

## End of Day 0 success criteria

- [ ] All 6 ISOs downloaded and on external storage
- [ ] Bootable Proxmox USB ready
- [ ] Network IPs decided and written down
- [ ] Existing server contents backed up
- [ ] You've read the install guides

If all boxes are checked, Monday's reset will go smoothly. If any aren't, finish them tonight before bed.

---

## Common pitfalls

- **Downloading on Monday morning** — ISOs are huge, you'll lose 2+ hours waiting
- **Forgetting VirtIO drivers** — you'll discover this at 11pm Tuesday when Windows install is grinding
- **Not testing the USB boots** — finding out at install time wastes 30 min
- **Picking "tank" or "rpool" as ZFS pool name** — fine, but be consistent (default `rpool` is recommended)
