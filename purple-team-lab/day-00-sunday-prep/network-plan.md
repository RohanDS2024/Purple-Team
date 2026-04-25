# Network Plan — Fill in BEFORE Monday

## Your home network (find these from your router)

| Item | Value |
|------|-------|
| Home subnet | _________________ (e.g., 192.168.1.0/24) |
| Gateway IP | _________________ (e.g., 192.168.1.1) |
| DNS server | _________________ (e.g., 192.168.1.1 or 1.1.1.1) |
| Free IP range | _________________ (e.g., 192.168.1.10–192.168.1.50) |

## Static IPs to assign

| Device | IP | Subnet | Notes |
|--------|----|----|-------|
| Proxmox host (mgmt) | _________________ | home | Web UI: https://<this-ip>:8006 |
| Wazuh SIEM (mgmt NIC) | _________________ | home | Kibana: https://<this-ip>:443 |
| Lab subnet (vmbr1) | 10.10.10.0/24 | isolated | No internet by default |
| Win Server DC | 10.10.10.10 | lab | Static, set during install |
| Win 11 workstation | DHCP from DC | lab | DC will run DHCP scope |
| Wazuh SIEM (lab NIC) | 10.10.10.5 | lab | Second NIC, for agent traffic |

## Domain info

| Item | Value |
|------|-------|
| Domain name | lab.local |
| NetBIOS name | LAB |
| DSRM password | _________________ (write down, don't lose) |
| Domain admin password | _________________ |

## Verification checklist (post-install)

- [ ] Can ping Proxmox web UI from laptop
- [ ] Can SSH into Proxmox from laptop
- [ ] Wazuh management IP reachable, lab IP NOT reachable from home network
- [ ] Lab subnet has no internet (test from inside a VM later)
