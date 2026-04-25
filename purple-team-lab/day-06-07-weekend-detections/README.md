# Days 6-7 — Weekend: Sigma Rules Sprint

**Goal:** Write 12 Sigma rules covering the 5 attacks from Day 4 (and a few extras), convert them to Wazuh rule format, deploy them, and verify each one fires when you re-run the attack.

**Time budget:** 6–8 hours over the weekend.

**End-of-weekend success criteria:**
- 12 Sigma rules in `sigma-rules/` folder of this repo
- Equivalent Wazuh rules deployed in `/var/ossec/etc/rules/local_rules.xml`
- Each rule has been validated by re-running its corresponding attack
- Screenshots of each alert firing in Wazuh dashboard

---

## Approach

Don't write rules from scratch. **Fork from SigmaHQ**, adapt, validate.

For each rule:
1. Look at the events you captured on Day 4
2. Identify the unique fingerprint (Event ID + specific field values)
3. Find a matching SigmaHQ template
4. Adapt it to your environment
5. Convert to Wazuh format
6. Deploy + reload
7. Re-run attack, verify alert fires
8. Screenshot

---

## Rule list

| # | Rule | ATT&CK | Source |
|---|------|--------|--------|
| 1 | Kerberoasting (RC4 service ticket request) | T1558.003 | Day 4 Attack 1 |
| 2 | AS-REP Roasting (no preauth ticket) | T1558.004 | Day 4 Attack 2 |
| 3 | Password spray (many failed logons) | T1110.003 | Day 4 Attack 3 |
| 4 | DCSync (replication GUIDs) | T1003.006 | Day 4 Attack 5 |
| 5 | BloodHound enumeration (LDAP queries) | T1087.002 | Day 4 Attack 4 |
| 6 | Suspicious PowerShell encoded command | T1059.001 | Day 5 bonus |
| 7 | LSASS process access (Mimikatz pattern) | T1003.001 | Day 5 bonus |
| 8 | Domain Admins membership change | T1098 | Detect future privesc |
| 9 | Service creation (persistence) | T1543.003 | Built-in Sysmon |
| 10 | Scheduled task creation | T1053.005 | Built-in Sysmon |
| 11 | WMI process creation (lateral movement) | T1047 | Sysmon Event 19/20/21 |
| 12 | New local administrator account | T1136.001 | Built-in Security |

---

## Day 6 (Saturday): Write rules 1-6

Start with the 5 attack-validated ones (1-5), then add the bonus (6) before the easier ones.

### Folder structure

In your local repo:
```
sigma-rules/
  T1558.003_kerberoasting.yml
  T1558.004_asrep_roasting.yml
  T1110.003_password_spray.yml
  T1003.006_dcsync.yml
  T1087.002_bloodhound.yml
  T1059.001_powershell_encoded.yml
  T1003.001_lsass_access.yml
  T1098_domain_admins_change.yml
  T1543.003_service_creation.yml
  T1053.005_scheduled_task.yml
  T1047_wmi_lateral.yml
  T1136.001_local_admin_create.yml

wazuh-rules/
  local_rules.xml      # combined rules to deploy
```

### Starter Sigma rules (4 templates)

I've written 4 templates for you in `starter-rules/` in this folder. They're real, working rules. Use them as patterns to write the other 8.

### Convert Sigma → Wazuh

Sigma rules don't natively work in Wazuh — you need to convert them. Two options:

**Option A (recommended): Translate by hand**
Wazuh rules are XML. The mapping is straightforward:
- Sigma `EventID` → Wazuh `<field name="win.system.eventID">`
- Sigma `process.command_line` → Wazuh `<field name="win.eventdata.commandLine">`

See `starter-rules/wazuh-equivalents.xml` for hand-translated versions.

**Option B: Use sigma-cli**
```bash
pip install pysigma pysigma-backend-elasticsearch
# Convert to Elastic query (close enough to use as Wazuh logic source)
sigma convert -t elasticsearch -f json sigma-rules/T1558.003_kerberoasting.yml
```

For 12 rules, hand-translation is faster and you'll learn more.

### Deploy to Wazuh

```bash
# SSH to Wazuh server
ssh wazuh@<wazuh-mgmt-ip>
sudo -i

# Edit local rules (custom rules go here, never edit /var/ossec/ruleset/rules/)
vim /var/ossec/etc/rules/local_rules.xml

# Paste your <group>...</group> block of custom rules
# Save

# Reload Wazuh manager
systemctl restart wazuh-manager

# Watch logs for any rule loading errors
tail -f /var/ossec/logs/ossec.log
```

If you see `Error reading rules file`, the XML has a syntax issue. The error message includes the line number.

### Validate each rule

For each rule:
1. Re-run the matching attack from Day 4
2. Wait 30 seconds
3. In Wazuh dashboard → **Threat Hunting → Events** filter `rule.id : <YOUR_RULE_ID>`
4. Verify alert appears
5. Screenshot to `screenshots/rule-NN-fired.png`

---

## Day 7 (Sunday): Write rules 7-12 + tune

Apply the same pattern to the remaining 6 rules. By now you should have a workflow rhythm.

### Tuning

Some rules will fire too often (false positives). Common cases:
- **Rule 5 (BloodHound LDAP)**: legitimate AD admin tools fire this. Tune by:
  - Excluding processes like `mmc.exe`, `dsa.msc`
  - Requiring high-volume LDAP query rate
- **Rule 9 (Service creation)**: some legitimate software creates services. Tune by:
  - Excluding common installers
  - Alerting only on services pointing to non-standard paths

Document tuning decisions in the rule's YAML comments — interviewers will ask about your false positive rate.

### Final validation pass

Run all 5 attacks again, end-to-end, and verify ALL relevant rules fire with no false positives. This is your "production readiness" check.

---

## End-of-weekend checklist

- [ ] 12 Sigma rules written and saved to `sigma-rules/`
- [ ] Wazuh rules deployed and `systemctl status wazuh-manager` is active
- [ ] All 5 attacks re-run, all corresponding rules fired
- [ ] 12 screenshots in `screenshots/` (one per rule firing)
- [ ] False positives tuned to <5% on a normal day
- [ ] Lab journal documents tuning decisions
- [ ] Snapshot `12-rules-deployed` taken on Wazuh VM

---

## What "good" looks like

Open Wazuh dashboard → **Discover** with filter `rule.groups : "purple_lab"` (you'll add this group tag). You should see:
- 12 distinct rule IDs firing across recent attack runs
- Mapped MITRE techniques visible in `rule.mitre.id` field
- Severity levels (your custom rules are level 10+)

This is the screenshot you'll feature on your README.

---

## Common pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| Rule doesn't fire on attack replay | Wrong field name in rule | Check actual field path in raw event JSON via Discover |
| `wazuh-manager` won't start after rule deploy | XML syntax error | `tail /var/ossec/logs/ossec.log` for line number |
| Rule fires constantly with no attack | Too generic match | Add a more specific field, e.g. require RC4 + non-machine account |
| Sigma rule has fields Wazuh doesn't have | Sigma's logsource model differs | Map manually using the actual event fields |
| Validation: "I see the event but no alert" | Rule didn't load, or threshold not met | Check `/var/ossec/logs/alerts/alerts.json` |

## Useful Wazuh commands

```bash
# Test a rule against a sample log
echo '<test event>' | /var/ossec/bin/wazuh-logtest

# Check loaded rules (should include yours)
/var/ossec/bin/ossec-logtest -t

# Watch alerts in real time
tail -f /var/ossec/logs/alerts/alerts.json | jq '{rule: .rule.id, level: .rule.level, desc: .rule.description}'
```
