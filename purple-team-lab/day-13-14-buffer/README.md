# Days 13–14 — Weekend: Buffer + Interview Prep

**Goal:** Polish anything that slipped, deeply prep for interview questions about this project.

---

## Saturday: Polish

Whatever didn't get done in Days 1–12, today is the catch-up. Common items:
- Finished only 8 rules instead of 12 → write the remaining 4
- Validation script not running → debug it
- README missing pieces → fill in
- Screenshots scattered → organize into `screenshots/`
- Lab journal incomplete → backfill from memory + git history

If you're truly done, use today to **commit polish**:
- Re-take any blurry/cluttered screenshots
- Add a 1-line description to each Sigma rule explaining the detection logic
- Write 1 short blog post on your portfolio site (the most valuable polish item)

---

## Sunday: Interview prep

This is where the project pays dividends. Practice these questions until you can answer them fluently.

### Project-specific questions

**Q: "Why did you build this?"**

Honest answer: "I wanted hands-on detection engineering experience that I couldn't get from coursework alone, and I wanted something concrete to talk about in interviews. Building a real attack-defense loop was the fastest way to learn how detection rules actually work in practice — including the messy parts like false positives and tuning."

**Q: "Walk me through the architecture."**

Short version, no rambling. 30 seconds:
"Proxmox hypervisor on a Xeon with 40 gigs of RAM. Inside it: a Server 2022 domain controller, a Windows 11 workstation joined to the domain, and a Wazuh SIEM running on Ubuntu. The lab subnet is isolated from the internet by default. Sysmon ships endpoint telemetry to Wazuh. Kali is the attacker on the same lab network."

**Q: "Pick your favorite detection rule. Walk me through how it works."**

Pick DCSync — it's the most senior-feeling answer.
"DCSync abuses replication permissions to dump password hashes for any account, including krbtgt — total domain compromise. The detection is on Event ID 4662, looking for one of three replication GUIDs being accessed: DS-Replication-Get-Changes, DS-Replication-Get-Changes-All, and DS-Replication-Get-Changes-In-Filtered-Set. The hard part is filtering false positives — legitimate domain controllers replicate to each other constantly using these same GUIDs. So I exclude any subject account ending in `$`, which catches machine accounts, and I exclude `MSOL_` prefix accounts which is Azure AD Connect. After that, any account exercising replication rights is highly suspicious."

**Q: "What did you find most surprising?"**

"How important Sysmon configuration is. Out of the box, Windows logs miss most attacker behavior — process creation events don't include command line by default, network connections aren't logged at all. SwiftOnSecurity's Sysmon config is the single highest-impact change you can make to a Windows endpoint for detection engineering. Without it, my rules wouldn't have anything to fire on."

**Q: "What's missing? What would you do with more time?"**

Don't be defensive — this is your roadmap, you've already thought about it:
"Five things on my list. First, multi-platform — adding a Linux victim with auditd telemetry. Second, CI/CD — turning my validation script into a full GitHub Actions pipeline that tests rules on every commit. Third, MITRE Caldera for continuous adversary emulation. Fourth, a Raspberry Pi as a network sensor running Zeek and Suricata to add a network detection layer. Fifth, MISP for threat intel integration."

### Concept questions (could be asked even if not project-specific)

**Q: "What's the difference between Kerberoasting and AS-REP roasting?"**

"Kerberoasting targets accounts with SPNs — any authenticated user can request a service ticket and get an encrypted hash they can crack offline. AS-REP roasting targets accounts that have Kerberos pre-authentication disabled, which is rare but happens with legacy applications. With AS-REP roasting you don't even need authenticated access — you can request the AS-REP for any user with preauth disabled and get a crackable hash. Detection-wise: Kerberoasting is Event 4769 with RC4, AS-REP is Event 4768 with PreAuthType 0."

**Q: "What's MITRE ATT&CK?"**

"It's a knowledge base of adversary tactics and techniques organized by stage of an attack — initial access, execution, persistence, privilege escalation, defense evasion, credential access, discovery, lateral movement, collection, command and control, exfiltration, and impact. Each technique has an ID like T1558.003, sub-techniques, and real-world examples. Detection engineers use it to map their rule coverage — instead of saying 'I have 50 rules,' you say 'I cover X% of the techniques relevant to my threat model.' It's the lingua franca of modern SOC work."

**Q: "What's Sysmon vs Windows Event Log?"**

"Windows Event Log is the built-in audit framework — Security log, System log, Application log. It captures things Microsoft decided are important. Sysmon is a separate Sysinternals tool that adds richer telemetry: full command lines, parent process relationships, network connections, file hashes, DLL loads, image loads, registry changes — basically everything a security analyst actually wants. Sysmon writes to its own event channel (`Microsoft-Windows-Sysmon/Operational`) which a SIEM agent can read. The combination of native Security log + Sysmon is the standard endpoint telemetry stack on Windows."

**Q: "What's the difference between IDS, IPS, and SIEM?"**

"IDS detects, IPS detects and blocks, SIEM aggregates and analyzes. An IDS like Suricata watches network traffic and alerts on known bad patterns. An IPS does the same but inline — it can drop traffic. A SIEM like Wazuh ingests logs from many sources — endpoints, network, cloud, applications — and runs correlation rules on top. SIEM is where detections that need context across multiple sources live. They're complementary, not alternatives."

**Q: "How would you tune a noisy rule?"**

"First, look at WHY it's firing. Is it firing on legitimate behavior, or is the rule too generic? Then narrow the match: add a process exclusion, require a specific user context, raise a threshold, or add a time-based correlation. The key is documenting WHY each tuning decision was made — never silently exclude something. In my lab, my BloodHound rule originally fired on legitimate AD admin tools. I tuned it to require 50 LDAP queries from one source within 60 seconds, which separates BloodHound's enumeration from normal activity. False positive rate went from 30% to under 5%."

### Behavioral questions

**Q: "Tell me about a time you debugged something hard."**

If you hit a real wall during the lab — e.g., Wazuh agents not connecting, Sysmon events not flowing — that's a STAR-format answer:
- **Situation:** "During my home lab build, my Wazuh agents wouldn't connect from the lab subnet."
- **Task:** "I had to figure out why before I could collect any telemetry."
- **Action:** "I checked agent logs, manager logs, network reachability with `ss` and `Test-NetConnection`, then realized Windows Defender Firewall was blocking outbound 1514 from the lab interface. I added an explicit allow rule and they connected immediately."
- **Result:** "Lab moved forward, and now I always check firewall rules first when agent connectivity is the symptom."

**Q: "What are you working on outside of school?"**

Lead with the lab, then SCALPEL. Both are recent, both are real.

---

## Reference cards

In the `reference/` folder of the repo, you have cheat sheets you can review:
- `kerberos-attacks.md` — quick reference on Kerberoasting/AS-REP/Pass-the-Hash
- `mitre-attack-cheatsheet.md` — common technique IDs by tactic
- `wazuh-rule-syntax.md` — Wazuh XML rule syntax quick ref

Read these once on Sunday so the technical vocab is fresh.

---

## End-of-prep checklist

- [ ] Practiced project walkthrough out loud 3+ times
- [ ] Can answer "favorite rule" question fluently
- [ ] Know your false positive numbers
- [ ] Have STAR-format answer ready for "tell me about a hard problem"
- [ ] Read reference cards
- [ ] Repo is clean, README is professional, demo video is uploaded
- [ ] LinkedIn updated
- [ ] Resume bullet finalized

---

## Mental prep

You did real work. You built a real lab, ran real attacks, wrote real rules, validated them with a real industry tool. You can talk about this project at the level of a junior SOC analyst with a year of experience — possibly higher in some areas. Going into interviews, you have authority on this material because you actually built it.

If an interviewer asks something you don't know, that's normal. Say "I haven't done that specifically — here's what I'd start with based on what I do know." That's a stronger answer than pretending to know.
