# Purple Team Home Lab

A home lab simulating an enterprise Active Directory environment with full SIEM coverage, adversary emulation, and detection engineering. Built on Proxmox.

## Architecture (MVP scope)

```
                    ┌────────────────────────────────────────┐
                    │           PROXMOX HOST                 │
                    │   Xeon E5620 / 40GB RAM / 1.2TB SSD    │
                    │           ZFS mirror (RAID1)           │
                    │                                        │
   Real network ────┤  ┌────────────────────────┐            │
   (vmbr0)          │  │ Wazuh SIEM (Ubuntu)    │            │
                    │  │ 4 vCPU / 12GB / 150GB  │            │
                    │  │ Two NICs (mgmt + lab)  │            │
                    │  └────────────────────────┘            │
                    │                                        │
                    │       Lab network (vmbr1, isolated)    │
                    │  ┌──────────┐    ┌──────────────┐      │
                    │  │ Win Srv  │    │ Win 11       │      │
                    │  │ 2022 DC  │────│ Workstation  │      │
                    │  │ 6GB RAM  │    │ 6GB RAM      │      │
                    │  └──────────┘    └──────────────┘      │
                    └────────────────────────────────────────┘
                                      ▲
                                      │ attacks
                                      │
                              ┌───────────────┐
                              │  Kali Linux   │
                              │  (laptop or   │
                              │   small VM)   │
                              └───────────────┘
```

## Two-week MVP plan

| Day | Date | Focus | Hours |
|-----|------|-------|-------|
| 00  | Sunday | Prep: downloads, planning, no hardware | 4–6 |
| 01  | Monday | Proxmox install, network, SIEM VM | 6–8 |
| 02  | Tuesday | AD lab: DC + Win11 + users | 3–4 |
| 03  | Wednesday | Wazuh + Sysmon agents | 3–4 |
| 04  | Thursday | Run 5 attacks, capture telemetry | 4–5 |
| 05  | Friday | Buffer / catch-up | 2–3 |
| 06–07 | Sat/Sun | Sigma rules sprint (12 rules) | 6–8 |
| 08  | Monday | GitHub repo scaffold + README | 3 |
| 09  | Tuesday | Validation script | 3 |
| 10  | Wednesday | Atomic Red Team coverage | 3 |
| 11  | Thursday | Resume + LinkedIn update | 2 |
| 12  | Friday | Demo video | 2 |
| 13–14 | Sat/Sun | Buffer + interview prep | flex |

## Folder map

Each day folder contains exactly what you need for that day — runbooks, scripts, configs, expected outputs. No more, no less.

- `day-00-sunday-prep/` — Checklist, download links, network plan template
- `day-01-monday-reset/` — Proxmox install runbook, post-install config, SIEM VM creation
- `day-02-tuesday-ad/` — PowerShell scripts to build the AD environment
- `day-03-wednesday-wazuh/` — Wazuh installer commands, Sysmon deployment
- `day-04-thursday-attacks/` — 5 attack playbooks, copy-paste commands
- `day-05-friday-buffer/` — Common issues + fixes
- `day-06-07-weekend-detections/` — Sigma rule writing guide + 4 starter rules
- `day-08-monday-repo/` — GitHub repo template + README skeleton
- `day-09-tuesday-validation/` — Python validation script
- `day-10-wednesday-atomic/` — Atomic Red Team test execution guide
- `day-11-thursday-resume/` — Resume bullet templates, LinkedIn copy
- `day-12-friday-demo/` — Demo video script + recording guide
- `day-13-14-buffer/` — Interview prep questions
- `reference/` — Cheat sheets, ATT&CK mappings, glossary
- `scripts/` — Reusable scripts (build VMs, deploy agents, etc.)
- `sigma-rules/` — Final Sigma rules (populate during Days 6–7)
- `sysmon-config/` — SwiftOnSecurity config download instructions
- `screenshots/` — Evidence pack (populate as you go)

## Resume bullet you'll earn

> Built a purple team home lab on Proxmox with an Active Directory environment (Server 2022 DC, Windows 11) and a Wazuh + Elastic SIEM; executed 5 AD attack chains (Kerberoasting, AS-REP, DCSync, password spray, BloodHound) and authored 12 Sigma detection rules covering 12 MITRE ATT&CK techniques with automated validation against Atomic Red Team tests.

## After the MVP: expansion roadmap

| Phase | Focus | New capability |
|-------|-------|----------------|
| 1 | Add Linux victim + auditd | Multi-platform SIEM coverage |
| 2 | CI/CD for Sigma rules | Detection-as-code pipeline |
| 3 | MITRE Caldera | Continuous adversary emulation |
| 4 | Pi 4B as Zeek/Suricata sensor | Network detection layer |
| 5 | MISP threat intel + public dashboard | Portfolio centerpiece |

## Operational rules

1. **Snapshot before every attack.** ZFS makes this free. Use it.
2. **Lab subnet (vmbr1) is air-gapped.** Punch holes only when needed (Windows updates, Kali install).
3. **Document as you go.** `lab-journal.md` in each day folder gets your real-time notes.
4. **Screenshot everything.** Attack command, telemetry event, alert. Three screenshots per attack minimum.
5. **Don't skip Sysmon config.** It's the single highest-impact decision in the entire lab.

## Author

Rohan — MS Computer Science, Florida Atlantic University, Cybersecurity specialization.
