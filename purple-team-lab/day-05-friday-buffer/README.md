# Day 5 — Friday: Buffer Day

**Goal:** Catch up on anything that slipped Mon–Thu. If you're on track, polish.

**Time budget:** 2–3 hours.

---

## Decision tree

### If you completed everything Mon–Thu ✅
Use today to:
- Re-run any attack where Wazuh telemetry was thin
- Document your lab journal for Days 1–4 properly
- Add 2 more "bonus" attacks to your evidence pack:
  - **Mimikatz simulation** on WS01 (test LSASS access detection)
  - **Suspicious PowerShell** with `-EncodedCommand`
- Read ahead: Sigma rule syntax basics

### If you're 1 day behind 🟡
Focus on completing **at least 3 of 5 attacks**. Quality > quantity. A strong evidence pack for 3 attacks beats a weak one for 5.

### If you're 2+ days behind 🔴
Triage hard. The MVP can survive with:
- 2 working attacks (Kerberoasting + BloodHound is the easiest pair)
- 6 Sigma rules instead of 12
- Skip validation script and demo video on Days 9–12

You'll still have a real, demoable project. The resume bullet just gets less specific.

---

## Common issues from the first 4 days

### Wazuh agents flapping (active → disconnected → active)

Cause: Network issue between agent and manager on the lab subnet.

```bash
# On Wazuh server, check incoming connections
sudo ss -tunlp | grep -E '1514|1515'

# Check agent's view from inside Windows VM
Test-NetConnection 10.10.10.5 -Port 1514
```

Common fixes:
- Wazuh's lab NIC didn't get the `10.10.10.5` IP — `ip a` to check
- Windows Defender Firewall blocking — temporarily disable for testing: `Set-NetFirewallProfile -All -Enabled False`

### Sysmon events visible in Event Viewer but NOT in Wazuh

Cause: `<localfile>` block missing in `ossec.conf`.

```powershell
# Verify the block exists
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.conf" | Select-String "Sysmon"
```

If empty, see Day 3 README — add the eventchannels block, restart agent.

### Kali can't reach DC01

```bash
# From Kali
ip a                              # verify 10.10.10.x address
ping 10.10.10.10                  # ping DC
nslookup dc01.lab.local 10.10.10.10  # DNS check
```

If ping fails, the Kali VM is on the wrong bridge. Fix in Proxmox VM hardware.

### Hashcat won't crack the Kerberoast hash

```bash
# Make sure rockyou is uncompressed
ls -la /usr/share/wordlists/rockyou.txt

# If gzipped:
gunzip /usr/share/wordlists/rockyou.txt.gz

# Use --force on CPU
hashcat -m 13100 hashes.txt /usr/share/wordlists/rockyou.txt --force
```

The lab passwords (e.g., `Password1!`, `Welcome123`, `Summer2024!`) are in rockyou. If you don't get a hit, the hash format is wrong — re-extract.

### Wazuh dashboard slow / unresponsive

Cause: Elastic Indexer running out of heap on the Xeon E5620.

```bash
# Increase heap (already done in Day 3 but verify)
grep -E '^-Xms|^-Xmx' /etc/wazuh-indexer/jvm.options
# Should show 4g for both

# Check actual memory pressure
free -h
sudo systemctl status wazuh-indexer | head -20
```

If it's still slow, drop log retention:
```bash
# In /etc/wazuh-indexer/opensearch.yml, add:
indices.fielddata.cache.size: "20%"
```

### Domain join fails

99% of the time it's DNS. WS01 must use 10.10.10.10 as its primary DNS.

```powershell
# On WS01
ipconfig /all | Select-String "DNS"
# If wrong, fix:
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.10.10.10
```

---

## "Bonus" attacks if you have time

### Mimikatz-style LSASS access (T1003.001)

You don't need actual Mimikatz — Defender will block it. Use a **benign LSASS read** for telemetry:

From WS01 PowerShell as admin:
```powershell
# Open handle to lsass with PROCESS_VM_READ — same access pattern Mimikatz uses
$lsass = Get-Process lsass
# This generates Sysmon Event 10 (ProcessAccess)

# View the event
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[EventID=10]]" -MaxEvents 5
```

### Suspicious PowerShell encoded command

From WS01:
```powershell
# Encode a benign command
$cmd = "Get-Process"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
$encoded = [Convert]::ToBase64String($bytes)
powershell.exe -EncodedCommand $encoded
```

Look in Wazuh for: `data.win.eventdata.commandLine: "*-EncodedCommand*"` or `*-enc*`

---

## Polishing checklist (if everything worked)

- [ ] Each attack has a screenshot folder with before/during/after evidence
- [ ] Lab journal has timestamps for every major event
- [ ] All VMs have at least 2 named snapshots (clean + post-attack)
- [ ] You can articulate, in plain English, what each attack does and why
- [ ] You've taken a "where is everything" inventory: IPs, credentials, snapshot names

---

## Read-ahead for the weekend

To save time Saturday:
- Skim **SigmaHQ rules**: https://github.com/SigmaHQ/sigma/tree/master/rules/windows — specifically `builtin/security/win_security_alert_credential_dumping.yml` and similar
- Read 1 page on **Sigma syntax**: https://github.com/SigmaHQ/sigma/wiki/Specification
- Skim how Wazuh rules look: https://documentation.wazuh.com/current/user-manual/ruleset/ruleset-xml-syntax/rules.html
