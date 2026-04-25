# Day 9 — Tuesday: Validation Script

**Goal:** Build a Python script that automates "run an attack → check Wazuh saw it → record pass/fail." This becomes the foundation of full CI/CD in Phase 2.

**Time budget:** 3 hours.

**End-of-day:** A script that outputs a coverage report you can include in your README.

---

## What the script does

1. Reads a list of test cases (attack technique → expected Wazuh rule ID)
2. For each test case:
   - Triggers the attack (locally or remotely via WinRM/SSH)
   - Waits for log ingestion (60s)
   - Queries Wazuh API: did rule X fire?
   - Records result
3. Prints a coverage report

This is "detection-as-code lite" — not full CI/CD, but the core validation loop. Mention it on your resume as "automated detection validation framework."

---

## Components

- `validate_detections.py` — main script (in this folder)
- `test-cases.yaml` — list of attacks and expected rule IDs
- `attack_runners/` — small helper scripts to trigger each attack

---

## Setup

On the Wazuh server (or wherever you run the validation):

```bash
# Create a service account for the script
sudo /var/ossec/bin/manage_agents
# Or via API: create a user with read-only on alerts

# Install Python deps
pip3 install requests pyyaml impacket
```

You need a Wazuh API user. Easiest:
```bash
# Use the default admin (lab only — never in production)
# API URL: https://<wazuh-mgmt-ip>:55000
```

---

## Run it

```bash
python3 validate_detections.py \
    --wazuh-host 10.10.10.5 \
    --user wazuh-wui \
    --password '<your-api-pass>' \
    --tests test-cases.yaml \
    --output coverage-report.md
```

Output:
```
[1/12] T1558.003 Kerberoasting           ✓ PASS  (rule 100100, 1 alert)
[2/12] T1558.004 AS-REP Roasting         ✓ PASS  (rule 100101, 1 alert)
[3/12] T1110.003 Password Spray          ✓ PASS  (rule 100103, 1 alert)
[4/12] T1003.006 DCSync                  ✓ PASS  (rule 100104, 2 alerts)
[5/12] T1087.002 BloodHound              ⚠ WARN  (rule 100106 fired, but 50q threshold marginal)
[6/12] T1059.001 PowerShell Encoded      ✓ PASS  (rule 100107, 1 alert)
[7/12] T1003.001 LSASS Access            ✗ FAIL  (rule 100108 did not fire)
...

Summary: 10/12 PASS, 1 WARN, 1 FAIL
Coverage: 83% (10/12 techniques validated)
Report written to coverage-report.md
```

The FAIL case becomes your homework: tune the rule, re-run.

---

## Why this matters for the resume

Without this: "I wrote some Sigma rules."
With this: "I built an automated detection validation framework that re-runs adversary tests against my rules and reports coverage. Found and fixed a false negative on LSASS access."

The second one is **3 levels more senior**.

---

## Files in this folder

- `README.md` — this file
- `validate_detections.py` — the script
- `test-cases.yaml` — test definitions
- `attack_runners/` — helper scripts to trigger each attack

---

## Common pitfalls

- **API auth fails**: default Wazuh API listens on port 55000 with TLS. Use `verify=False` in requests for self-signed certs.
- **Alerts haven't ingested yet**: add a sleep between attack and query. 60s is safe.
- **Time skew**: if the script's timezone is different from Wazuh's, time-bounded queries miss events. Use UTC everywhere.
- **Rule ID mismatch**: if you renumbered rules, update test-cases.yaml.
