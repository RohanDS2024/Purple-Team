# Day 11 — Thursday: Resume + LinkedIn Update

**Goal:** Translate everything you've built into resume bullets, a LinkedIn project entry, and an interview narrative.

**Time budget:** 2 hours.

---

## Resume bullet variants

Pick the bullet that fits your resume's tone. All three describe the same project — choose based on space and the role you're targeting.

### Long version (3 lines, for security-focused resumes)

> **Purple Team Home Lab** — Designed and deployed an enterprise-style Active Directory environment on Proxmox (Server 2022 DC, Windows 11) with Wazuh + Elastic SIEM and Sysmon endpoint telemetry. Executed 5 adversary technique chains (Kerberoasting, AS-REP, password spray, BloodHound, DCSync) and authored 12 Sigma detection rules covering 12 MITRE ATT&CK techniques. Built Python validation framework that re-runs Atomic Red Team tests against rules, achieving 87% detection coverage with documented tuning of 3 false negatives.

### Medium version (2 lines, balanced resume)

> **Purple Team Home Lab (Proxmox + Wazuh + Sigma)** — Built AD lab, executed 5 attack chains, authored 12 Sigma detections covering 12 ATT&CK techniques, and validated coverage with Atomic Red Team automation. [github.com/<user>/purple-team-lab]

### Short version (1 line, when space is tight)

> Built purple team home lab (Proxmox/Wazuh/Sigma) with 12 detection rules across 12 MITRE ATT&CK techniques, validated by Atomic Red Team automation. [github.com/<user>/purple-team-lab]

### Skills section additions

Add to your skills list (if not already there):
- **SIEM:** Wazuh, Elasticsearch, Kibana
- **Detection engineering:** Sigma, MITRE ATT&CK, Atomic Red Team
- **Endpoint telemetry:** Sysmon (SwiftOnSecurity), auditd
- **AD security:** Kerberoasting, AS-REP roasting, DCSync, BloodHound
- **Virtualization:** Proxmox VE, ZFS

---

## LinkedIn project entry

Add to LinkedIn → Profile → Add section → Recommended → Add project.

**Title:** Purple Team Home Lab

**Description:**
```
A purple team home lab that combines enterprise-style infrastructure, real adversary techniques, and detection engineering — built end-to-end on Proxmox.

What I built:
• Active Directory environment (Server 2022 DC + Windows 11) with realistic users, OUs, and Kerberoastable service accounts
• Wazuh + Elastic + Kibana SIEM with Sysmon (SwiftOnSecurity config) on all endpoints
• 5 adversary technique chains: Kerberoasting, AS-REP roasting, password spray, BloodHound enumeration, DCSync
• 12 Sigma detection rules covering 12 MITRE ATT&CK techniques, deployed as Wazuh custom rules
• Python validation framework that automatically runs Atomic Red Team tests and verifies alert generation

Key outcomes:
• 87% detection coverage validated against the Atomic Red Team test suite
• Identified and remediated 3 false negatives via rule tuning
• Full documentation, scripts, and detection rules published to GitHub

Stack: Proxmox VE, ZFS, Wazuh, Elasticsearch, Sysmon, Sigma, Atomic Red Team, MITRE ATT&CK, Impacket, BloodHound, hashcat, Python.
```

**Skills:** Tag the same skills as on resume.

**Link:** GitHub repo URL.

---

## Interview narrative — practice this

You'll be asked about this project. Practice these answers OUT LOUD before interviews:

### "Walk me through the project."

> I built a purple team home lab to learn detection engineering hands-on. The setup is an enterprise AD environment on Proxmox with a Wazuh SIEM and Sysmon endpoint telemetry. I executed 5 attack chains — Kerberoasting, AS-REP roasting, password spray, BloodHound, and DCSync — and wrote Sigma rules to detect each. Then I validated my detections against the Atomic Red Team test suite and got 87% coverage, with three false negatives that I tuned out. The whole thing is on GitHub.

### "Why those 5 attacks?"

> They cover the core AD attack chain that almost every red team and real APT uses: get a foothold (password spray), enumerate (BloodHound), get credentials (Kerberoasting/AS-REP), and escalate to domain compromise (DCSync). If I can detect those 5, I've got coverage on the most common AD intrusion playbook.

### "Walk me through Kerberoasting."

> Any authenticated domain user can request a service ticket for any account with an SPN. The ticket is encrypted with the service account's password hash. With RC4 encryption — which is still allowed for backward compat — I can request the ticket, extract the hash, and crack it offline with hashcat. Modern AD defaults to AES, so my detection logic is: Event ID 4769, encryption type 0x17 (RC4), targeting a non-machine account that isn't krbtgt. Filtering machine accounts and krbtgt is essential because legitimate replication generates 4769 for them constantly.

### "What's your false positive rate?"

> Most rules are under 5% on a normal day. The noisiest one was BloodHound LDAP detection — legitimate AD admin tools fire it. I tuned it to require 50+ LDAP queries from one source within 60 seconds, which cleanly separates BloodHound's enumeration from normal admin activity. Password spray was originally too sensitive too — I require 10+ failures across distinct users within 60 seconds, same source.

### "What would you add if you had more time?"

> Five things — phase plan in the README. Adding a Linux victim with auditd telemetry, a CI/CD pipeline that validates rules on every commit, MITRE Caldera for continuous adversary emulation, a Pi 4B as a Zeek/Suricata network sensor, and MISP integration for threat intel.

### "What did you learn?"

> Three biggest lessons. One — Sysmon configuration is the highest-impact decision. Default Windows logs hide most attacker behavior, SwiftOnSecurity's config exposes it. Two — stateful detections like password spray don't fit Sigma's stateless model cleanly. Wazuh's frequency rules and `if_matched_sid` solve what Sigma alone can't. Three — testing against your own attacks gives false confidence. Atomic Red Team's third-party tests caught gaps in my rules I would never have found otherwise.

---

## End-of-day checklist

- [ ] Resume updated with chosen bullet
- [ ] Skills section updated
- [ ] LinkedIn project added with description and link
- [ ] GitHub repo pinned on profile
- [ ] Practiced narrative answers OUT LOUD at least once
- [ ] Lab journal updated

---

## Files in this folder

- `resume-bullets.md` — three length variants
- `linkedin-project.md` — copy-paste content
- `interview-prep.md` — common questions with answer outlines
