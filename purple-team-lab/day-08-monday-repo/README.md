# Day 8 — Monday: GitHub Repo Polish

**Goal:** Public GitHub repo with clear architecture, professional README, evidence pack ready for recruiters to skim.

**Time budget:** 3 hours.

**End-of-day:** A `purple-team-lab` repo on your GitHub that's pin-worthy on your profile.

---

## Step 1 — Repo structure (30 min)

Create the public repo (or reuse this one). Final structure:

```
purple-team-lab/
├── README.md                 # The most important file. Spend real time on it.
├── LICENSE                   # MIT or Apache 2.0
├── .gitignore
├── docs/
│   ├── architecture.png      # Diagram (use Excalidraw/draw.io)
│   ├── attack-chain.md       # All 5 attacks documented
│   └── attack-coverage.md    # ATT&CK technique mapping table
├── sigma-rules/              # All 12 Sigma rules (.yml)
├── wazuh-rules/
│   └── local_rules.xml       # Deployable Wazuh rules
├── sysmon-config/
│   └── README.md             # Notes on SwiftOnSecurity config + your tweaks
├── scripts/
│   ├── provision-dc.ps1      # AD setup
│   ├── create-lab-users.ps1  # User provisioning
│   └── deploy-rules.sh       # Push rules to Wazuh manager
├── screenshots/              # Evidence: attack + alert pairs
└── lab-journal.md            # Your build log (optional but valued)
```

**Important:** Sanitize first. Before pushing:
- [ ] No real passwords (lab passwords are fine — they're in rockyou anyway)
- [ ] No internal IPs from your home network (10.10.10.x is fine, 192.168.1.50 is not)
- [ ] No credentials in screenshots
- [ ] No personal info in commit messages
- [ ] No SSH private keys

---

## Step 2 — Architecture diagram (45 min)

Use **Excalidraw** (free, browser-based) or **draw.io**. Don't use ASCII art — it screams "didn't bother."

The diagram should show:
- Proxmox host with the VMs inside it
- Two networks: real network (vmbr0) and lab network (vmbr1)
- Wazuh's two NICs bridging both
- Kali as the attacker on vmbr1
- Arrows from attacker → victims → telemetry → SIEM

Export as PNG, save as `docs/architecture.png`. Reference in the README.

**Reference dimensions:** 1200x800 minimum so it's legible when embedded.

---

## Step 3 — README (1 hour) — THIS IS THE MOST IMPORTANT FILE

Use the template in `README-template.md` in this folder. Fill in:
- Project pitch (2 paragraphs)
- Architecture diagram (embed your PNG)
- Stack table (technologies used)
- Detection coverage table (ATT&CK ID → rule → screenshot)
- Setup instructions (high-level — no need to repeat every Day folder)
- Lessons learned section (this is what hiring managers read)
- Roadmap (your 5-phase expansion plan)

**Resume reality check:** Recruiters will look at your README for ~30 seconds. The first screen needs to communicate:
1. What this is
2. What technologies it uses
3. What you accomplished (numbers + screenshots)
4. Where to look for more

---

## Step 4 — Documentation pages (30 min)

`docs/attack-chain.md` — the 5 attacks in interview-ready prose. Each has:
- What the attack does
- Command run
- Expected event(s)
- Screenshot link
- ATT&CK technique
- Detection rule that catches it

`docs/attack-coverage.md` — table mapping all 12 rules to ATT&CK techniques. Include severity levels and links to MITRE.

---

## Step 5 — Push to GitHub (15 min)

```bash
cd ~/purple-team-lab
git init
git add .
git commit -m "Initial commit: 12 detections across 12 ATT&CK techniques"
git branch -M main
git remote add origin git@github.com:<yourusername>/purple-team-lab.git
git push -u origin main
```

Then on GitHub:
- [ ] Add repo description: "Purple team home lab on Proxmox: AD attacks, Sysmon telemetry, Wazuh SIEM, Sigma detections."
- [ ] Add topics: `cybersecurity`, `purple-team`, `wazuh`, `sigma`, `mitre-attack`, `detection-engineering`, `proxmox`, `homelab`
- [ ] Pin the repo on your profile

---

## End-of-day checklist

- [ ] Repo public on GitHub
- [ ] README with diagram, stack table, coverage table
- [ ] All 12 Sigma rules pushed
- [ ] Wazuh rules XML pushed
- [ ] Scripts pushed (provision-dc, create-lab-users, deploy-rules)
- [ ] Screenshots organized and pushed
- [ ] Description + topics set
- [ ] Repo pinned on profile

---

## Files in this folder

- `README-template.md` — fill-in-the-blanks README to copy to repo root
- `gitignore-template` — sensible defaults for this kind of project
- `LICENSE-MIT.txt` — drop in as `LICENSE`
