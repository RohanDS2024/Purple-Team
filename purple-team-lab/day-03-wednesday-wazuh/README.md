# Day 3 — Wednesday: Wazuh + Sysmon

**Goal:** Wazuh SIEM running, Sysmon installed on both Windows VMs, agents enrolled, telemetry visible in Kibana.

**Time budget:** 3–4 hours.

**End-of-day success criteria:**
- Wazuh dashboard accessible at `https://<wazuh-mgmt-ip>`
- Wazuh agents on DC01 and WS01 show "Active" in dashboard
- Sysmon is logging events on both Windows VMs
- You can search Sysmon Event ID 1 in Kibana and see process creation events

---

## Step 1 — Install Wazuh (1 hour)

SSH to the SIEM VM:
```bash
ssh wazuh@<wazuh-mgmt-ip>
sudo -i
```

### Run the all-in-one installer

```bash
# Download the installer
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh

# Run all-in-one install (Wazuh manager + Indexer + Dashboard, single node)
bash ./wazuh-install.sh -a
```

This takes 10–20 minutes. The installer outputs admin credentials at the end — **save them immediately** to your password manager:

```
INFO: --- Summary ---
INFO: You can access the web interface https://<wazuh-mgmt-ip>
    User: admin
    Password: <RANDOMLY GENERATED>
```

### Verify

From your laptop, browse to `https://<wazuh-mgmt-ip>` (accept self-signed cert), log in as `admin`.

You should see the Wazuh dashboard with 0 agents.

### Increase Elastic JVM heap (your Xeon needs this)

The default heap is small. Bump it for better stability on your hardware:

```bash
# Edit Indexer JVM options
sudo sed -i 's/^-Xms.*/-Xms4g/' /etc/wazuh-indexer/jvm.options
sudo sed -i 's/^-Xmx.*/-Xmx4g/' /etc/wazuh-indexer/jvm.options

# Restart
sudo systemctl restart wazuh-indexer
sudo systemctl restart wazuh-manager
sudo systemctl restart wazuh-dashboard

# Check status
systemctl status wazuh-indexer wazuh-manager wazuh-dashboard --no-pager | head -30
```

✅ **Verify:** All three services are `active (running)`.

---

## Step 2 — Install Sysmon on DC01 (45 min)

**This is the highest-impact step in the entire lab.** Without Sysmon, your Windows visibility is poor.

You need to get the Sysmon binary and SwiftOnSecurity config onto the DC. Since `vmbr1` is air-gapped, options:

### Option A: Temporary internet for DC (recommended)

In Proxmox, edit DC01's network: change bridge from `vmbr1` to `vmbr0` temporarily. Inside DC01:

```powershell
# As admin
# Download Sysmon
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "C:\Sysmon.zip"
Expand-Archive C:\Sysmon.zip -DestinationPath C:\Sysmon

# Download SwiftOnSecurity config
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" `
    -OutFile "C:\Sysmon\sysmonconfig.xml"

# Install Sysmon with config
C:\Sysmon\Sysmon64.exe -accepteula -i C:\Sysmon\sysmonconfig.xml

# Verify
Get-Service Sysmon64
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5
```

After Sysmon is installed, **switch DC01 back to vmbr1**. The Sysmon binary stays on disk; no internet needed for it to keep running.

### Option B: Copy via shared CD/ISO

Download Sysmon and config on Proxmox host, package as ISO, mount as CD on the VM, copy off.

Less convenient but keeps the air-gap intact.

### Verify Sysmon is logging

In DC01 PowerShell:
```powershell
# Generate a test event
notepad.exe
# Close notepad

# Check the most recent event
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 1 | Format-List
```

You should see Event ID 1 (Process Create) for notepad.

---

## Step 3 — Install Sysmon on WS01 (15 min)

Same procedure as DC01. Use Option A (temporary internet) — fastest.

---

## Step 4 — Deploy Wazuh agents (45 min)

### Get the agent installer on each Windows VM

On the Wazuh dashboard:
1. Go to **Agents → Deploy new agent**
2. Choose **Windows MSI 32/64**
3. Server address: enter the **lab-side** IP of Wazuh: `10.10.10.5`
4. Agent name: `dc01` (then repeat for `ws01`)
5. Copy the install command shown — it's a one-liner like:

```powershell
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.9.0-1.msi -OutFile $env:tmp\wazuh-agent.msi; `
    msiexec.exe /i $env:tmp\wazuh-agent.msi /q `
    WAZUH_MANAGER='10.10.10.5' WAZUH_AGENT_GROUP='default' WAZUH_AGENT_NAME='dc01'
```

Run on each Windows VM (with temp internet enabled). After install:

```powershell
NET START WazuhSvc
```

### Tell Wazuh agents to ingest Sysmon

The default agent config doesn't include Sysmon's event channel. Edit on each Windows VM:

`C:\Program Files (x86)\ossec-agent\ossec.conf`

Find the `<localfile>` block for `Application` channel and add this block AFTER it:

```xml
<localfile>
  <location>Microsoft-Windows-Sysmon/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
```

Restart the agent:
```powershell
Restart-Service WazuhSvc
```

### Verify in dashboard

Wazuh dashboard → **Agents** → both `dc01` and `ws01` should show **Active** (green).

---

## Step 5 — Confirm Sysmon events flowing (15 min)

In Wazuh dashboard:
1. Go to **Discover** (or **Threat Hunting → Events**)
2. Set time range to "Last 15 minutes"
3. Filter: `data.win.system.providerName : "Microsoft-Windows-Sysmon"`
4. On WS01, run something visible: `powershell.exe -Command "Get-Process"`
5. Refresh Discover — you should see Sysmon Event ID 1 events appear within ~30 seconds

✅ **Success looks like:** Multiple Sysmon events streaming in, `agent.name` = ws01 or dc01, `data.win.eventdata.image` showing process paths.

---

## End-of-day checklist

- [ ] Wazuh dashboard accessible
- [ ] All Wazuh services running
- [ ] Sysmon installed on DC01 and WS01 with SwiftOnSecurity config
- [ ] Both agents show Active in dashboard
- [ ] Sysmon events visible in Discover/Kibana
- [ ] Snapshot all VMs as `wazuh-ready`
- [ ] Lab journal updated

---

## Common pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| Agent shows "Disconnected" | Lab subnet can't reach Wazuh's lab IP | Verify Wazuh has `10.10.10.5/24` on its second NIC, no firewall blocking 1514/1515 |
| Sysmon events not in Wazuh | Agent config missing eventchannel | Add the `<localfile>` block above to ossec.conf |
| Wazuh installer hangs | Low memory | Bump VM RAM temporarily, retry |
| Dashboard shows "Could not connect to Wazuh API" | Indexer/manager not started | `systemctl status wazuh-*`, restart any not running |
| Sysmon download fails | DNS issue | Use raw IP via curl, or download on host and copy |
| Agent logs flood with junk | SwiftOnSecurity config tuning | Acceptable for lab; tune later |

## Useful commands for troubleshooting

```bash
# On Wazuh server
sudo tail -f /var/ossec/logs/ossec.log
sudo /var/ossec/bin/agent_control -l   # list agents
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard

# On Windows agent
Get-Service WazuhSvc
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 50
```
