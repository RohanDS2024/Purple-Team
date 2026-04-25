# MITRE ATT&CK — Cheat Sheet

The 14 enterprise tactics with the most-referenced techniques per tactic. Memorize the bolded ones for interviews.

## TA0043 — Reconnaissance
External info gathering before getting into the network. Mostly off-network so SIEMs rarely catch it.

## TA0042 — Resource Development
Attacker prep: domains, infrastructure, payloads. Pre-attack.

## TA0001 — Initial Access
- T1078 Valid Accounts
- T1190 Exploit Public-Facing Application
- **T1566 Phishing** (still #1 initial access vector in 2026)
- T1133 External Remote Services

## TA0002 — Execution
- **T1059 Command and Scripting Interpreter**
  - T1059.001 PowerShell
  - T1059.003 Windows Command Shell
  - T1059.004 Unix Shell
  - T1059.005 Visual Basic
  - T1059.006 Python
- **T1047 Windows Management Instrumentation** (WMI)
- T1053 Scheduled Task/Job
- T1569 System Services

## TA0003 — Persistence
- **T1543 Create or Modify System Process**
  - T1543.003 Windows Service
- **T1053 Scheduled Task/Job**
- **T1136 Create Account**
  - T1136.001 Local Account
  - T1136.002 Domain Account
- T1098 Account Manipulation
- T1547 Boot or Logon Autostart Execution
- T1574 Hijack Execution Flow

## TA0004 — Privilege Escalation
- **T1068 Exploitation for Privilege Escalation**
- T1055 Process Injection
- T1078 Valid Accounts (privilege abuse)
- T1134 Access Token Manipulation

## TA0005 — Defense Evasion
- T1027 Obfuscated Files or Information
- T1070 Indicator Removal
- T1112 Modify Registry
- T1140 Deobfuscate/Decode Files or Information
- T1218 System Binary Proxy Execution (LOLBins)
- T1562 Impair Defenses (disable AV, etc.)

## TA0006 — Credential Access (the juicy one for AD attacks)
- **T1003 OS Credential Dumping**
  - T1003.001 LSASS Memory (Mimikatz)
  - T1003.006 DCSync
- **T1110 Brute Force**
  - T1110.001 Password Guessing
  - T1110.003 Password Spraying
  - T1110.004 Credential Stuffing
- **T1558 Steal or Forge Kerberos Tickets**
  - T1558.001 Golden Ticket
  - T1558.002 Silver Ticket
  - T1558.003 Kerberoasting
  - T1558.004 AS-REP Roasting
- T1555 Credentials from Password Stores

## TA0007 — Discovery
- T1018 Remote System Discovery
- T1033 System Owner/User Discovery
- T1046 Network Service Scanning
- T1057 Process Discovery
- T1069 Permission Groups Discovery
- T1083 File and Directory Discovery
- **T1087 Account Discovery**
  - T1087.002 Domain Account
- T1135 Network Share Discovery

## TA0008 — Lateral Movement
- **T1021 Remote Services**
  - T1021.001 RDP
  - T1021.002 SMB/Windows Admin Shares
  - T1021.006 Windows Remote Management
- **T1550 Use Alternate Authentication Material**
  - T1550.002 Pass the Hash
  - T1550.003 Pass the Ticket
- T1570 Lateral Tool Transfer

## TA0009 — Collection
- T1005 Data from Local System
- T1039 Data from Network Shared Drive
- T1056 Input Capture
- T1113 Screen Capture
- T1119 Automated Collection

## TA0011 — Command and Control
- T1071 Application Layer Protocol
- T1090 Proxy
- T1095 Non-Application Layer Protocol
- T1572 Protocol Tunneling

## TA0010 — Exfiltration
- T1041 Exfiltration Over C2 Channel
- T1048 Exfiltration Over Alternative Protocol
- T1567 Exfiltration Over Web Service

## TA0040 — Impact
- T1486 Data Encrypted for Impact (ransomware)
- T1490 Inhibit System Recovery
- T1485 Data Destruction
- T1489 Service Stop

---

## Common interview questions

**"What ATT&CK tactic is Kerberoasting?"** → Credential Access (TA0006). Specifically T1558.003.

**"What's the difference between TA, T, and sub-T?"** → Tactics (TA####) are the WHY (goals). Techniques (T####) are the HOW. Sub-techniques (T####.###) are specific variations of a technique.

**"Why use ATT&CK instead of just a rule count?"** → Coverage measurement. "I have 50 rules" doesn't tell you anything about your blind spots. "I cover 60% of credential access techniques relevant to my threat model" does.

**"What's a threat model?"** → A defined adversary profile and the techniques they use. E.g., "ransomware operators targeting healthcare" → specific subset of techniques (initial access via phishing or RDP exposure, credential dumping, lateral movement via SMB, data destruction via T1486). You build detections that prioritize that subset.

**"What's the ATT&CK Navigator?"** → A web tool for visualizing your detection coverage as a heatmap over the ATT&CK matrix. Color-code techniques by your coverage level. Free at attack.mitre.org/navigator.

---

## Pro tip for the lab

Tag every rule with its ATT&CK technique using the `<mitre>` element. Wazuh surfaces this in dashboards. When you screenshot the dashboard for your README, the ATT&CK tags make it look immediately professional.
