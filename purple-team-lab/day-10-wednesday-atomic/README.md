# Day 10 — Wednesday: Atomic Red Team Coverage Validation

**Goal:** Use Atomic Red Team (community-standard adversary tests) to validate your rules against industry-recognized test definitions, not just your own attacks. This is what real detection engineers do.

**Time budget:** 3 hours.

**End-of-day:** A coverage matrix showing how your rules perform against ART tests.

---

## Why this matters

Your validation script (Day 9) tests your rules against your own attacks — closed loop. **Atomic Red Team (ART)** tests them against **third-party defined adversary behaviors**, which is what real SOC teams use to benchmark detection efficacy.

Resume difference:
- Without ART: "I tested my rules against attacks I wrote."
- With ART: "I validated my detections against the MITRE-aligned Atomic Red Team test suite."

---

## What is Atomic Red Team?

Open-source library by Red Canary, maps to MITRE ATT&CK, contains thousands of small "atomic" tests for each technique. Each test is a script that performs ONE specific behavior.

Repo: https://github.com/redcanaryco/atomic-red-team
Framework: https://github.com/redcanaryco/invoke-atomicredteam (PowerShell)

---

## Setup on WS01 (45 min)

Temporarily enable internet on WS01 (or use offline install).

```powershell
# As admin on WS01
# Install Invoke-AtomicRedTeam framework
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing)
Install-AtomicRedTeam -getAtomics

# Verify
Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
Invoke-AtomicTest T1059.001 -ShowDetails
```

This downloads thousands of YAML test definitions covering most ATT&CK techniques.

---

## Run the relevant tests (1.5 hours)

For each technique your rules cover, find the corresponding ART tests and run them.

### Test plan

| Your Rule | ATT&CK | ART Tests to Run |
|-----------|--------|------------------|
| 100100 Kerberoasting | T1558.003 | `T1558.003-1` (Rubeus), `T1558.003-2` (PowerView) |
| 100101 AS-REP | T1558.004 | `T1558.004-1`, `T1558.004-3` |
| 100103 Password Spray | T1110.003 | `T1110.003-2`, `T1110.003-4` |
| 100104 DCSync | T1003.006 | `T1003.006-1`, `T1003.006-2` |
| 100106 BloodHound | T1087.002 | `T1087.002-1`, `T1087.002-9` |
| 100107 Pwsh Encoded | T1059.001 | `T1059.001-3`, `T1059.001-4` |
| 100108 LSASS | T1003.001 | `T1003.001-1`, `T1003.001-2` (these run Mimikatz — Defender will block; run with exclusions for lab) |
| 100109 DA Add | T1098 | `T1098-2`, `T1098-3` |
| 100110 Service Create | T1543.003 | `T1543.003-1`, `T1543.003-2` |
| 100111 Sched Task | T1053.005 | `T1053.005-1`, `T1053.005-2` |
| 100112 WMI | T1047 | `T1047-2`, `T1047-3` |
| 100113 Local Admin | T1136.001 | `T1136.001-1`, `T1136.001-2` |

### Run each test

```powershell
# Check prerequisites first
Invoke-AtomicTest T1558.003 -CheckPrereqs

# Get prerequisites if needed
Invoke-AtomicTest T1558.003 -GetPrereqs

# Run the test
Invoke-AtomicTest T1558.003 -TestNumbers 1

# Cleanup
Invoke-AtomicTest T1558.003 -Cleanup
```

Always run `-Cleanup` after — ART tests sometimes leave persistence artifacts.

### Defender exclusions for lab

Some tests will be blocked by Windows Defender. For lab purposes only:

```powershell
# Exclude AtomicRedTeam folder from real-time scanning
Add-MpPreference -ExclusionPath "C:\AtomicRedTeam"
# Some tests need full Defender disable temporarily
Set-MpPreference -DisableRealtimeMonitoring $true
# RE-ENABLE AFTER:
Set-MpPreference -DisableRealtimeMonitoring $false
```

---

## Build the coverage matrix (45 min)

For each test you ran, record:
- Did Wazuh see the events? (Should always be yes if Sysmon is correct)
- Did your rule fire? (Pass/Fail)
- Were there other rules that fired? (Bonus — multi-rule coverage is good)
- Was there a false positive on legitimate behavior afterwards? (Tune if yes)

Save as `docs/atomic-red-team-coverage.md` with this structure:

```markdown
# Atomic Red Team Coverage

| Technique | Test | Wazuh Saw | Your Rule | Other Rules | FP Tuning |
|-----------|------|-----------|-----------|-------------|-----------|
| T1558.003 | -1 (Rubeus) | ✓ | ✓ 100100 | — | None |
| T1558.003 | -2 (PowerView) | ✓ | ✓ 100100 | — | None |
| T1003.006 | -1 (Mimikatz DCSync) | ✓ | ✓ 100104 | 100107 (pwsh) | None |
| T1003.001 | -1 (Mimikatz logonpasswords) | ✓ | ✗ FAIL | — | Rule 100108 access mask too narrow; broaden 0x1010 to 0x1438 |
...
```

---

## Tune detected gaps (30 min)

Any test that didn't trigger your rule = a gap. For each gap:
1. Look at the actual events in Wazuh after the test ran
2. Find the diff between what fired and what your rule expects
3. Tune the rule
4. Re-run, confirm fix

Common gaps:
- Rule field expects exact match but ART variant uses different value
- Rule excludes something that ART doesn't trigger
- Rule fires on parent process X but ART variant uses parent Y

Document each tuning decision in commit messages — interviewers love this.

---

## End-of-day checklist

- [ ] Atomic Red Team installed on WS01
- [ ] Ran ART tests for all 12 techniques (24+ individual tests)
- [ ] Cleanup ran successfully after each
- [ ] Coverage matrix written
- [ ] Gaps identified and tuned where possible
- [ ] Final pass rate documented (aim for 80%+)

---

## What "good" looks like for the resume

> **Validated detection coverage against the Atomic Red Team test suite**, achieving 87% pass rate (21/24 tests) across 12 MITRE ATT&CK techniques; identified and remediated 3 false negatives via rule tuning, with all changes documented in commit history.

This is *senior SOC analyst* level claim. Backed up by your repo + coverage matrix.

---

## Common pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| Test "skipped" | Prereqs not met | `-GetPrereqs` first |
| Defender blocks test | Real-time protection | Add exclusion or temp disable |
| Test runs but no Wazuh event | Sysmon not catching it | Check Sysmon config — may need to add scenario |
| Test runs, Wazuh sees event, no alert | Rule too narrow | Broaden field match in rule |
| Many false positives after test | Cleanup didn't run | Run `-Cleanup` explicitly |
