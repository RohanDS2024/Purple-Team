# Day 2 — Tuesday: Active Directory Build

**Goal:** Working AD domain `lab.local` with realistic users, groups, and Kerberoastable service accounts. Windows 11 workstation joined.

**Time budget:** 3–4 hours.

**End-of-day success criteria:**
- Domain Controller promoted, AD DS + DNS + DHCP running
- 15+ users in realistic OUs
- 2 service accounts with SPNs and weak passwords
- Windows 11 joined to domain
- You can log into Win11 with a domain user

---

## Step 1 — Create Win Server 2022 VM (45 min)

Use these settings (web UI → Create VM):

| Setting | Value |
|---------|-------|
| VM ID | 101 |
| Name | dc01 |
| ISO | WindowsServer2022.iso |
| Machine | q35, OVMF (UEFI), EFI disk on local-zfs |
| Pre-Enroll keys | **YES** (Windows needs MS keys) |
| SCSI Controller | VirtIO SCSI single |
| Disk | 80 GiB, local-zfs, Discard + SSD emulation ON |
| CPU | 2 cores, host |
| Memory | 6144 MiB, ballooning OFF |
| Network 1 | **vmbr1** (lab only — DC has no internet by default) |
| QEMU Agent | YES |

### Install Windows Server

1. Boot the VM, attach `virtio-win.iso` as second CD/DVD if needed
2. During install, click "Load driver" when partitioning fails to see disk:
   - Browse virtio-win → vioscsi → 2k22 → amd64
3. Choose **Windows Server 2022 Standard (Desktop Experience)**
4. Custom install, all default
5. Set Administrator password (strong, save it)
6. Login

### Post-install on DC

1. Open Device Manager — install any unknown device drivers from `virtio-win.iso`:
   - Network adapter → driver → browse → `virtio-win\NetKVM\2k22\amd64`
   - Balloon, Serial, etc.
2. Install QEMU Guest Agent: from `virtio-win.iso` → `guest-agent\qemu-ga-x86_64.msi`
3. Set static IP (Server Manager → Local Server → Ethernet):
   - IP: **10.10.10.10**
   - Subnet: 255.255.255.0
   - Gateway: (blank — isolated)
   - DNS: 127.0.0.1 (will become DC after promotion)
4. Rename computer to **DC01** → restart
5. Take snapshot: `pre-promotion`

---

## Step 2 — Promote to Domain Controller (45 min)

Two options — pick one.

### Option A: GUI (slower but visual)

Server Manager → Manage → Add Roles and Features → Active Directory Domain Services → install. Then click the yellow flag → "Promote this server to a domain controller."

- Add new forest: **lab.local**
- DSRM password: from network plan
- DNS delegation: skip warnings
- NetBIOS name: LAB
- Paths: defaults
- Install, reboot

### Option B: PowerShell (faster, scriptable) — RECOMMENDED

Open PowerShell as Administrator, run `provision-dc.ps1` from this folder.

```powershell
# From this folder, copy provision-dc.ps1 onto the VM via shared clipboard or RDP
# Then run as Administrator:
.\provision-dc.ps1
```

The VM will reboot automatically after promotion.

✅ **Verify after reboot:** Open Server Manager → AD DS shows green. `nltest /dsgetdc:lab.local` succeeds.

---

## Step 3 — Create users and OUs (30 min)

After DC promotion completes and you've logged back in as `LAB\Administrator`:

```powershell
# From this folder, run:
.\create-lab-users.ps1
```

This creates:
- OUs: HR, IT, Engineering, Finance, Service Accounts
- 15 normal users with realistic names and weak/reused passwords
- 2 Kerberoastable service accounts with SPNs (these are your attack targets)
- 1 user with "Do not require Kerberos preauthentication" (AS-REP roasting target)
- 1 user added to Domain Admins (for DCSync attack chain)

✅ **Verify:** `Get-ADUser -Filter * | Select Name, Enabled` lists all users.

---

## Step 4 — DHCP scope for lab subnet (20 min)

The DC will hand out IPs to the Win11 workstation.

```powershell
# Add DHCP role
Install-WindowsFeature DHCP -IncludeManagementTools

# Authorize DHCP server in AD
Add-DhcpServerInDC -DnsName "dc01.lab.local" -IPAddress 10.10.10.10

# Create scope
Add-DhcpServerv4Scope -Name "Lab Scope" `
    -StartRange 10.10.10.50 `
    -EndRange 10.10.10.200 `
    -SubnetMask 255.255.255.0 `
    -State Active

# Set DNS option
Set-DhcpServerv4OptionValue -ScopeId 10.10.10.0 `
    -DnsServer 10.10.10.10 `
    -DnsDomain lab.local

# Restart service
Restart-Service DHCPServer

# Verify
Get-DhcpServerv4Scope
```

---

## Step 5 — Create Win 11 workstation VM (30 min)

| Setting | Value |
|---------|-------|
| VM ID | 102 |
| Name | ws01 |
| ISO | Windows11.iso |
| Machine | q35, OVMF (UEFI), EFI disk on local-zfs |
| Pre-Enroll keys | YES |
| TPM | **Add** (Hardware → Add → TPM State, v2.0, on local-zfs) |
| SCSI Controller | VirtIO SCSI single |
| Disk | 80 GiB, Discard + SSD emulation ON |
| CPU | 2 cores, host |
| Memory | 6144 MiB |
| Network 1 | vmbr1 (lab) |

### Install Windows 11

Win11 requires TPM 2.0 — you added that above. If install still complains, press **Shift+F10** to open cmd, then:
```
regedit
```
Navigate to `HKEY_LOCAL_MACHINE\SYSTEM\Setup`, create key `LabConfig`, add DWORDs `BypassTPMCheck` = 1, `BypassRAMCheck` = 1, `BypassSecureBootCheck` = 1.

During OOBE:
- Don't connect to a network (Shift+F10 → `OOBE\BYPASSNRO`)
- Local account: name=`ws-local`, password=anything
- Decline all telemetry

### Post-install

1. Install VirtIO drivers (network adapter, balloon, etc.)
2. Set static-from-DHCP or let DHCP assign — should get 10.10.10.50ish
3. Verify ping: `ping 10.10.10.10`
4. Verify DNS: `nslookup dc01.lab.local`

### Join to domain

```powershell
# As local admin
Add-Computer -DomainName lab.local -Credential (Get-Credential) -Restart
# Enter LAB\Administrator credentials
```

After reboot, log in as `LAB\j.smith` (or any user from create-lab-users.ps1).

✅ **Verify:** You're logged in as a domain user. `whoami /groups` shows `LAB\Domain Users`.

### Snapshot both VMs

- VM 101 (DC01): snapshot **`ad-ready`**
- VM 102 (WS01): snapshot **`domain-joined-clean`**

---

## End-of-day checklist

- [ ] DC01 promoted, `lab.local` domain healthy
- [ ] 15+ users created across OUs
- [ ] 2 Kerberoastable service accounts (verify with `Get-ADUser -Filter * -Properties ServicePrincipalNames | Where SPN -ne $null`)
- [ ] AS-REP roastable user exists (verify `Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true}`)
- [ ] WS01 joined to domain, can log in as domain user
- [ ] Both VMs snapshotted
- [ ] Lab journal updated

---

## Common pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| WS01 can't ping DC01 | Wrong subnet, wrong NIC bridge | Verify both VMs on vmbr1 |
| WS01 can't resolve `dc01.lab.local` | DHCP not handing out DNS | Verify scope DNS option = 10.10.10.10 |
| Domain join fails: "domain not found" | DNS on WS01 not pointing to DC | `ipconfig /renew` or set static DNS |
| Win11 install rejects hardware | Missing TPM | Add TPM 2.0 in Hardware tab, or use bypass regedit |
| Win Server install can't see disk | Missing VirtIO SCSI driver | Load driver from virtio-win ISO during partitioning |
| `Get-ADUser` says "term not recognized" | RSAT/AD module not installed | `Install-WindowsFeature RSAT-AD-PowerShell` |
