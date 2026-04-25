# Kerberos Attacks — Quick Reference

Quick-glance reference for interview questions and detection logic.

## Kerberos basics (1-minute version)

Kerberos is the auth protocol AD uses. Three actors:
- **Client** (you, the user)
- **KDC** (Key Distribution Center, lives on the DC)
- **Service** (the resource you want to access)

Three-step dance:
1. Client → KDC: "I'm Alice, give me a TGT" (AS-REQ → AS-REP, returns a TGT)
2. Client → KDC: "I have my TGT, give me a service ticket for service X" (TGS-REQ → TGS-REP)
3. Client → Service: "Here's my service ticket, let me in"

The cryptography: each ticket is encrypted with a key derived from the password hash of the entity being targeted.
- TGT is encrypted with **krbtgt**'s hash → if you compromise krbtgt, you can forge any TGT (Golden Ticket)
- Service ticket is encrypted with the **service account's** hash → if you can crack a service ticket offline, you get the service account password

## The attacks

### 1. Kerberoasting (T1558.003)

**What:** Request service tickets for any account with an SPN. The ticket is encrypted with that account's password hash. Take it offline, crack it.

**Why it works:** Any authenticated user can request a service ticket for any SPN. The ticket itself contains an encrypted blob you can attack offline without touching the network again.

**Why RC4 matters:** Modern AD uses AES (event ticketEncryptionType 0x12). RC4 (0x17) is much faster to crack. Attackers explicitly request RC4 to speed up cracking.

**Tools:** `impacket-GetUserSPNs`, Rubeus (`kerberoast`), PowerView (`Invoke-Kerberoast`)

**Detection:** Event 4769, encryption type 0x17, target is a user (not a machine ending in `$`), not krbtgt.

**Defense:**
- Long random passwords (25+ chars) on service accounts — exponentially harder to crack
- Use Group Managed Service Accounts (gMSAs) — auto-rotated complex passwords
- Disable RC4 across the domain via GPO if backward compat allows
- Audit accounts with SPNs regularly

---

### 2. AS-REP Roasting (T1558.004)

**What:** Find users with "Do not require Kerberos pre-authentication" set. Request their AS-REP. Get an encrypted blob containing data encrypted with their password hash. Crack offline.

**Why it works:** Pre-authentication is the protection that prevents you from getting an AS-REP for any user. Without it, anyone can request the AS-REP and crack it.

**Tools:** `impacket-GetNPUsers`, Rubeus (`asreproast`)

**Detection:** Event 4768, PreAuthType = 0, target is a user.

**Defense:**
- Don't disable pre-authentication — it's a setting from the days of legacy apps
- Audit `DoesNotRequirePreAuth` accounts regularly
- Strong passwords on any accounts that legitimately need it

---

### 3. Pass-the-Hash (T1550.002)

**What:** Use an NTLM hash to authenticate as a user without knowing their plaintext password.

**Why it works:** NTLM accepts the hash as proof of password knowledge — by design.

**Tools:** `impacket-psexec`, `impacket-wmiexec`, CrackMapExec, Mimikatz

**Detection:** Hard. The hash is valid. Look for:
- Logon Type 9 (NewCredentials) on the source
- Lateral movement patterns (admin logons across many machines from one account)
- Anomalous source IPs for privileged accounts

**Defense:**
- Disable NTLM where possible (force Kerberos)
- Protected Users group
- Credential Guard
- LAPS (random local admin passwords per machine)

---

### 4. Pass-the-Ticket (T1550.003)

**What:** Steal a Kerberos ticket from memory and reuse it on another machine.

**Why it works:** Tickets are bearer tokens — possession proves access.

**Tools:** Mimikatz (`sekurlsa::tickets`, `kerberos::ptt`), Rubeus

**Detection:**
- Logon events with anomalous TGT lifetimes
- Service ticket requests where the source IP doesn't match recent TGT requests
- Very long-lived TGTs

**Defense:**
- Reduce TGT lifetime
- Credential Guard
- Don't log on as Domain Admin to workstations (no DA tickets in workstation memory)

---

### 5. DCSync (T1003.006)

**What:** Pretend to be a domain controller and ask another DC to replicate password data.

**Why it works:** AD replication uses MS-DRSR protocol. Any account with replication permissions (Domain Admins by default; sometimes delegated more broadly) can request password hashes for any account, including krbtgt.

**Tools:** Mimikatz (`lsadump::dcsync`), `impacket-secretsdump`

**Detection:** Event 4662 with replication GUIDs in the Properties field, where SubjectUserName isn't a machine account or AAD Connect.

**Defense:**
- Audit who has Replicating Directory Changes / Replicating Directory Changes All rights
- Tier 0 admin model (DA accounts only used on DCs)
- Detection is the primary defense — DCSync is hard to prevent without blocking legitimate replication

---

### 6. Golden Ticket (T1558.001)

**What:** With krbtgt's hash, forge a TGT for any user with any privileges. Effectively domain god mode for ~10 years (default lifetime) until krbtgt is rotated twice.

**Why it works:** TGTs are signed and encrypted by krbtgt. If you have krbtgt's hash, you can mint your own.

**Tools:** Mimikatz (`kerberos::golden`), Rubeus

**Detection:** Hard. Look for:
- TGT lifetime anomalies (forged tickets often have non-standard lifetimes)
- Service ticket requests for accounts that never requested TGTs (because the TGT was forged offline)
- Logon events for users that don't actually exist

**Defense:**
- Rotate krbtgt password TWICE (once invalidates current, twice invalidates anything still cached)
- Detect via TGT lifetime anomalies
- This is post-compromise — golden tickets mean you've already lost the domain. Detection is about finding the persistence.

---

### 7. Silver Ticket (T1558.002)

**What:** Forge a service ticket directly using a compromised service account's hash. Bypasses the KDC entirely.

**Tools:** Mimikatz (`kerberos::golden /service:...`)

**Detection:** Hard. Service authenticates the ticket locally without checking back with the KDC. Look for service usage with no preceding TGT request.

**Defense:**
- Strong service account passwords + gMSAs
- PAC validation enabled
- Detection via correlation: service ticket use without recent KDC interaction

---

## ATT&CK technique map

| Attack | ATT&CK | Tactic |
|--------|--------|--------|
| Kerberoasting | T1558.003 | Credential Access |
| AS-REP Roasting | T1558.004 | Credential Access |
| Golden Ticket | T1558.001 | Credential Access |
| Silver Ticket | T1558.002 | Credential Access |
| Pass-the-Hash | T1550.002 | Defense Evasion / Lateral Movement |
| Pass-the-Ticket | T1550.003 | Defense Evasion / Lateral Movement |
| DCSync | T1003.006 | Credential Access |

## Cheat-sheet: encryption type values

| Value | Algorithm |
|-------|-----------|
| 0x1 | DES-CBC-CRC (legacy) |
| 0x3 | DES-CBC-MD5 (legacy) |
| 0x11 | AES128-CTS-HMAC-SHA1-96 |
| 0x12 | AES256-CTS-HMAC-SHA1-96 |
| 0x17 | RC4-HMAC ← Kerberoasting indicator |
| 0x18 | RC4-HMAC-EXP |

## Common Event IDs

| Event ID | Meaning |
|----------|---------|
| 4624 | Successful logon |
| 4625 | Failed logon |
| 4634 | Logoff |
| 4647 | User-initiated logoff |
| 4662 | Object access (DCSync uses this) |
| 4670 | Permissions on object changed |
| 4672 | Special privileges assigned |
| 4720 | User account created |
| 4728 | Member added to security-enabled global group |
| 4732 | Member added to security-enabled local group |
| 4756 | Member added to security-enabled universal group |
| 4768 | TGT request (AS-REP, AS-REP roasting) |
| 4769 | Service ticket request (Kerberoasting) |
| 4771 | Pre-authentication failed |
| 4776 | Domain controller validated credentials (NTLM) |

## Key sub-status codes (4625)

| Code | Meaning |
|------|---------|
| 0xc000005e | No logon servers available |
| 0xc0000064 | User does not exist |
| 0xc000006a | Bad password ← password spray indicator |
| 0xc000006d | Other (often bad workstation name) |
| 0xc000006f | User logon outside of authorized hours |
| 0xc0000070 | User logon from unauthorized workstation |
| 0xc0000071 | Password expired |
| 0xc0000072 | Account disabled |
| 0xc0000133 | Time skew between machine and DC |
| 0xc0000193 | Account expired |
| 0xc0000234 | Account locked out |
