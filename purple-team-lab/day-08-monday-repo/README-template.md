# Purple Team Home Lab

[![Detection Coverage](https://img.shields.io/badge/ATT%26CK_Techniques-12-red)](docs/attack-coverage.md)
[![Sigma Rules](https://img.shields.io/badge/Sigma_Rules-12-blue)](sigma-rules/)
[![SIEM](https://img.shields.io/badge/SIEM-Wazuh_4.9-green)](https://wazuh.com)

A purple team home lab simulating an enterprise Active Directory environment with full SIEM coverage and detection engineering. Built end-to-end on Proxmox in 2 weeks as a portfolio project.

## What this is

A full-stack security lab where I:
- Built an Active Directory enterprise environment (Server 2022 DC + Windows 11 workstation) on Proxmox
- Deployed Wazuh + Elastic + Kibana as the SIEM with Sysmon endpoint telemetry
- Executed 5 real adversary techniques against the environment
- Authored 12 custom Sigma rules covering 12 MITRE ATT&CK techniques
- Validated detection efficacy by re-running attacks and verifying alert generation

## Architecture

![Architecture](docs/architecture.png)

## Stack

| Layer | Technology |
|-------|-----------|
| Hypervisor | Proxmox VE 8.x on Xeon E5620 / 40GB RAM / 1.2TB ZFS mirror |
| Domain | Windows Server 2022 (AD DS, DNS, DHCP) |
| Endpoint | Windows 11 Enterprise (domain-joined) |
| Endpoint telemetry | Sysmon w/ SwiftOnSecurity config |
| SIEM | Wazuh 4.9 + Elasticsearch + Kibana |
| Attacker | Kali Linux + Impacket + BloodHound |
| Rule format | Sigma → Wazuh XML rules |

## Detection coverage

| # | ATT&CK ID | Technique | Severity | Rule |
|---|-----------|-----------|----------|------|
| 1 | T1558.003 | Kerberoasting | High | [yml](sigma-rules/T1558.003_kerberoasting.yml) |
| 2 | T1558.004 | AS-REP Roasting | High | [yml](sigma-rules/T1558.004_asrep_roasting.yml) |
| 3 | T1110.003 | Password Spraying | High | [yml](sigma-rules/T1110.003_password_spray.yml) |
| 4 | T1003.006 | DCSync | Critical | [yml](sigma-rules/T1003.006_dcsync.yml) |
| 5 | T1087.002 | Domain Account Discovery | Medium | [yml](sigma-rules/T1087.002_bloodhound.yml) |
| 6 | T1059.001 | PowerShell (Encoded) | High | [yml](sigma-rules/T1059.001_powershell_encoded.yml) |
| 7 | T1003.001 | LSASS Credential Dump | Critical | [yml](sigma-rules/T1003.001_lsass_access.yml) |
| 8 | T1098 | Privileged Group Modification | High | [yml](sigma-rules/T1098_domain_admins_change.yml) |
| 9 | T1543.003 | Service Persistence | High | [yml](sigma-rules/T1543.003_service_creation.yml) |
| 10 | T1053.005 | Scheduled Task Persistence | Medium | [yml](sigma-rules/T1053.005_scheduled_task.yml) |
| 11 | T1047 | WMI Lateral Movement | High | [yml](sigma-rules/T1047_wmi_lateral.yml) |
| 12 | T1136.001 | Local Account Creation | Medium | [yml](sigma-rules/T1136.001_local_admin_create.yml) |

See [`docs/attack-coverage.md`](docs/attack-coverage.md) for the full ATT&CK Navigator heatmap and validation evidence.

## Attack chain examples

Each attack was executed end-to-end and validated against the corresponding detection. Detail in [`docs/attack-chain.md`](docs/attack-chain.md).

**Kerberoasting:**
```bash
impacket-GetUserSPNs lab.local/jsmith:'<pw>' -dc-ip 10.10.10.10 -request
hashcat -m 13100 hashes.txt rockyou.txt
```
→ Wazuh fires rule 100100 on Event ID 4769 with RC4 encryption type.

**DCSync:**
```bash
impacket-secretsdump lab.local/cdavis:'<pw>'@10.10.10.10 -just-dc-user krbtgt
```
→ Wazuh fires rule 100104 on Event ID 4662 with replication GUID access.

## Quick start

To replicate this lab, follow the step-by-step day folders (Day 0 → Day 12). Hardware: Proxmox host with at least 32GB RAM and 400GB storage.

1. **[Day 0 — Sunday Prep](day-00-sunday-prep/)** — Downloads and planning
2. **[Day 1 — Proxmox + SIEM VM](day-01-monday-reset/)** — Hypervisor and base infra
3. **[Day 2 — Active Directory](day-02-tuesday-ad/)** — Lab AD with realistic users
4. **[Day 3 — Wazuh + Sysmon](day-03-wednesday-wazuh/)** — SIEM and telemetry
5. **[Day 4 — Attack execution](day-04-thursday-attacks/)** — 5 attack chains
6. **[Days 6-7 — Detection sprint](day-06-07-weekend-detections/)** — 12 Sigma rules
7. **[Day 9 — Validation](day-09-tuesday-validation/)** — Automated rule testing

## Lessons learned

- **Sysmon configuration is the single highest-impact decision.** Default Windows logs hide most attacker behavior; SwiftOnSecurity's config exposes it.
- **RC4 vs AES is the cleanest Kerberoasting signal in 2026.** Modern Windows defaults to AES — RC4 service ticket requests almost always indicate hash extraction.
- **Password spray detection requires correlation, not single-event rules.** A single 4625 means nothing; 10 across distinct users from one source in 60 seconds is unmistakable.
- **DCSync's `4662` events are noisy** because legitimate DC-to-DC replication uses the same GUIDs. Filtering machine accounts and AAD Connect is essential.
- **Wazuh and Sigma have an impedance mismatch** for stateful detections. Frequency rules and `if_matched_sid` solve what Sigma alone can't express.

## Roadmap

This MVP is Phase 0 of an ongoing project. Planned expansions:

- [ ] **Phase 1** — Multi-platform: Ubuntu victim with auditd telemetry
- [ ] **Phase 2** — Detection-as-code: GitHub Actions CI/CD validating rules on every commit
- [ ] **Phase 3** — Continuous adversary emulation with MITRE Caldera
- [ ] **Phase 4** — Network detection layer with Zeek/Suricata on Raspberry Pi 4B
- [ ] **Phase 5** — Threat intelligence integration with MISP and public dashboard

## Contact

Rohan — MS Computer Science, Florida Atlantic University, Cybersecurity specialization.

[Portfolio](https://your-portfolio.com) · [LinkedIn](https://linkedin.com/in/...) · [Blog post](https://your-portfolio.com/blog/purple-team-lab)

## License

MIT — see [LICENSE](LICENSE).
