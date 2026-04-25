# Day 12 — Friday: Demo Video

**Goal:** A 3-minute screen recording showing attack → detection in action. This is what you send to recruiters who ask "tell me about a project."

**Time budget:** 2 hours.

**Output:** Unlisted YouTube link in the README, ready to share.

---

## Why a video matters

Recruiters and hiring managers spend ~10 seconds skimming a GitHub README. A 3-minute video that opens with a working SIEM dashboard catching a live attack will dramatically out-perform any text bullet.

Plus: practicing the demo IS interview prep. You'll articulate the project better in person after recording it.

---

## Structure (3 minutes total)

| Segment | Time | Content |
|---------|------|---------|
| Intro | 0:00–0:20 | Who you are, what this is, what you'll show |
| Architecture flash | 0:20–0:40 | Quick overview diagram, name the stack |
| Live attack 1 (Kerberoasting) | 0:40–1:30 | Run command on Kali, show events ingest, alert fires |
| Live attack 2 (DCSync) | 1:30–2:20 | Same flow, different attack — shows breadth |
| Coverage matrix / GitHub | 2:20–2:50 | Show the validation report and GitHub repo |
| Outro | 2:50–3:00 | Roadmap mention, link to repo |

3 minutes is short — write a script and rehearse before recording.

---

## Setup (45 min)

### Tools

- **OBS Studio** (free, all platforms) — best screen recorder
- **DaVinci Resolve** (free) for cuts, OR just record in one take
- USB headset/decent mic — DON'T use laptop built-in mic
- Quiet room, close other apps

### Pre-flight checks

Before recording:
- [ ] All VMs running, healthy, snapshotted to clean states
- [ ] Wazuh dashboard logged in, Discover open with appropriate filters
- [ ] Kali terminal open, command history cleared (`history -c`), commands ready in a notes file
- [ ] Browser zoomed to 110% so text is readable in the recording
- [ ] Notifications/Slack/Discord OFF
- [ ] Monitor at 1920x1080 (1440p shrinks too much when uploaded)

### Layout for recording

Two windows side-by-side:
- **Left:** Kali terminal (the attacker view)
- **Right:** Wazuh Discover (the defender view)

Plus a third window minimized: GitHub repo, ready to bring up at the end.

---

## Script (1 hour to write + rehearse)

Don't ad-lib. Write every word. Practice it out loud 3 times.

### Sample script

> [0:00] "Hi, I'm Rohan. This is Purple Lab — a home environment I built to learn detection engineering by running real adversary techniques against my own SIEM."

> [0:15] "Quick architecture: Proxmox host runs an Active Directory domain — Server 2022 controller, Windows 11 workstation. A Wazuh SIEM ingests Sysmon telemetry from both. Kali on the same lab network is the attacker."

> [0:35] "First attack: Kerberoasting. From Kali I'm authenticated as a low-privilege user. I'll request service tickets for accounts with SPNs..."
> [run: impacket-GetUserSPNs ...]

> [0:55] "...and I get encrypted hashes back. In a real attack I'd crack these offline."

> [1:05] "Watch the SIEM. I'm filtering for Event 4769 with RC4 encryption — the Kerberoasting fingerprint."
> [refresh Wazuh, alert appears]

> [1:20] "There it is — rule 100100 fired. Severity 12. Mapped to MITRE T1558.003. The detection works."

> [1:30] "Second attack — DCSync. I'll abuse a domain admin account to extract the krbtgt hash, which would let me forge tickets for any user."
> [run: impacket-secretsdump]

> [1:55] "Got the krbtgt hash. Total domain compromise. But..."
> [refresh Wazuh]

> [2:05] "...the SIEM caught it. Rule 100104 — replication GUID accessed by a non-machine account, severity 14. Critical alert."

> [2:20] "I built 12 of these rules total, covering 12 ATT&CK techniques. Each one validated by Atomic Red Team tests — I'm at 87% coverage right now."
> [show coverage matrix]

> [2:40] "Everything's on GitHub — Sigma rules, Wazuh configs, the validation script, and a 12-day build guide. Roadmap is to add a Caldera adversary emulation layer and a Zeek network sensor next."
> [show GitHub repo]

> [2:55] "Thanks for watching. Link's in the description."

---

## Recording (30 min)

1. Do 3 takes minimum. Best one wins.
2. Each take is full 3 minutes — don't pause/resume mid-take, just retry.
3. Speak slower than feels natural. Recording amplifies fast-talking.
4. Watch for: stuttering, "um/uh", looking down at notes too much.

If you're a non-native English speaker (you mentioned Bengaluru roots) or just nervous: that's fine, just be clear and steady. Hiring managers care about competence, not accent.

---

## Editing (15 min if needed)

If you got it in one take: skip editing, upload raw.

If you have multiple takes:
- DaVinci Resolve — drag clips, cut bad parts, render to MP4
- 1080p, H.264, ~10mbit bitrate — looks good on YouTube without huge file

Add minimal text overlays only if it helps clarity (e.g., highlight a rule ID with an arrow). Don't add music or fancy intros. Recruiters watching this don't want production value, they want signal.

---

## Upload (15 min)

YouTube → Upload → **Unlisted** (NOT public, NOT private).

- Title: "Purple Team Home Lab — Live Demo (Kerberoasting + DCSync detection)"
- Description: Brief project description + GitHub link + your contact info
- Thumbnail: A clean screenshot of Wazuh dashboard with an alert visible
- Tags: cybersecurity, detection-engineering, wazuh, sigma, mitre-attack, purple-team

Why unlisted? Public means random people can find/comment. Private means recruiters can't view. Unlisted = link works for anyone you share it with, no public discoverability.

### Update README

Add to your repo's README.md, near the top:

```markdown
## Demo

[![Watch the demo](docs/video-thumbnail.png)](https://youtu.be/YOUR_VIDEO_ID)

3-minute live demo showing Kerberoasting and DCSync detections.
```

---

## End-of-day checklist

- [ ] OBS configured, mic tested
- [ ] Script written and rehearsed
- [ ] 3 takes recorded, best one selected
- [ ] Edited if needed
- [ ] Uploaded to YouTube as unlisted
- [ ] README updated with thumbnail and link
- [ ] Watched the final video yourself end-to-end (cringe through it; this is part of the process)

---

## Common pitfalls

- **Bad audio** ruins everything. If your mic is bad, BUY a $30 USB mic before recording. Audio matters more than video quality.
- **Too long** — if it's 5+ minutes, recruiters bail. Cut ruthlessly.
- **No closing** — always end with the GitHub link visible
- **Reading from notes** — if your eyes drift down constantly, it shows. Memorize key transitions.
- **Recording at low resolution** — 720p looks dated. Use 1080p minimum.
- **Background noise** — close windows, kill the AC if needed for the take
