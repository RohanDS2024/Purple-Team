# Wazuh Rule Syntax — Quick Reference

Custom rules go in `/var/ossec/etc/rules/local_rules.xml` on the manager. After editing, run `systemctl restart wazuh-manager`.

## Rule ID ranges

| Range | Use |
|-------|-----|
| 1–99,999 | Wazuh built-in (don't touch) |
| 100,000–199,999 | Your custom rules |
| 200,000+ | Available |

By convention, group your custom rules — e.g., 100100-100199 for AD detections, 100200-100299 for Linux, etc.

## Anatomy of a rule

```xml
<group name="windows,attack,my_lab,">
  <rule id="100100" level="12">
    <if_sid>60103</if_sid>                       <!-- parent rule (Windows event log) -->
    <field name="win.system.eventID">^4769$</field>
    <field name="win.eventdata.ticketEncryptionType">^0x17$</field>
    <description>Kerberoasting: RC4 service ticket requested</description>
    <mitre>
      <id>T1558.003</id>
    </mitre>
    <group>credential_access,</group>
  </rule>
</group>
```

## Common attributes

| Attribute | What it does |
|-----------|--------------|
| `id` | Unique numeric ID |
| `level` | 0–15 severity (0=ignore, 12=high, 14-15=critical) |
| `frequency` | Number of matches needed |
| `timeframe` | Time window for frequency, in seconds |
| `ignore` | After firing, ignore this rule for N seconds (anti-flood) |

## Common child elements

### `<if_sid>` and `<if_matched_sid>`

- `<if_sid>X</if_sid>` — only consider events that already matched rule X
- `<if_matched_sid>X</if_matched_sid>` — used in correlation/frequency rules

```xml
<!-- Single failed logon, level 3 -->
<rule id="100102" level="3">
  <if_sid>60103</if_sid>
  <field name="win.system.eventID">^4625$</field>
  <description>Failed logon</description>
</rule>

<!-- 10+ failures in 60s from same source = password spray -->
<rule id="100103" level="12" frequency="10" timeframe="60">
  <if_matched_sid>100102</if_matched_sid>
  <same_source_ip />
  <different_user />
  <description>Password spray detected</description>
</rule>
```

### `<field>`

Match a field with a regex. Without `name=`, matches the whole event.

```xml
<field name="win.eventdata.commandLine" type="pcre2">(?i)-encodedcommand</field>
<field name="win.eventdata.image" negate="yes">svchost\.exe$</field>
```

`type="pcre2"` enables Perl-compatible regex (recommended for complex patterns).

### `<match>`

Substring match — simpler than `<field>` regex. Use for quick string searches.

```xml
<match>svchost.exe</match>
```

### `<regex>`

Full regex match against the event log line.

```xml
<regex>(?i)mimikatz</regex>
```

### `<srcip>`, `<dstip>`, `<user>`

Quick filters for common fields:

```xml
<srcip>10.10.10.50</srcip>
<user>!admin</user>      <!-- ! prefix = NOT this user -->
```

### Correlation helpers

| Element | Effect |
|---------|--------|
| `<same_source_ip />` | Group matches by source IP |
| `<same_user />` | Group matches by user |
| `<same_field>X</same_field>` | Group matches by custom field |
| `<different_user />` | Distinct usernames in the group |
| `<different_url />` | Distinct URLs |

### `<mitre>`

Tag with ATT&CK techniques (Kibana surfaces these in dashboards):

```xml
<mitre>
  <id>T1558.003</id>
  <id>T1078</id>
</mitre>
```

## Field paths for Windows events

When Wazuh ingests Windows events, fields are namespaced:

| Field | Path |
|-------|------|
| Event ID | `win.system.eventID` |
| Computer | `win.system.computer` |
| Channel | `win.system.channel` |
| Provider name | `win.system.providerName` |
| Subject username | `win.eventdata.subjectUserName` |
| Target username | `win.eventdata.targetUserName` |
| Logon type | `win.eventdata.logonType` |
| Image (process path) | `win.eventdata.image` |
| Command line | `win.eventdata.commandLine` |
| Parent image | `win.eventdata.parentImage` |
| Source IP | `win.eventdata.ipAddress` or `win.eventdata.sourceIp` |
| Destination port | `win.eventdata.destinationPort` |

The simplest way to find a field path: trigger the event, look at the raw JSON in Discover, navigate the `win.*` tree.

## Severity level guidance

| Level | Use |
|-------|-----|
| 0 | Ignore (silenced) |
| 2–3 | Informational |
| 5–7 | Notable but routine (failed logons, etc.) |
| 9–11 | Important — should be reviewed |
| 12 | High — likely malicious |
| 13–14 | Very high — strong indicator of compromise |
| 15 | Critical — definitely compromise |

## Useful patterns

### Match Sysmon Event 1 (process create)

```xml
<rule id="100200" level="0">
  <if_group>sysmon_event1</if_group>
  <description>Sysmon process create base</description>
</rule>
```

Wazuh has built-in groups for Sysmon events — `sysmon_event1` through `sysmon_event25`.

### Negate a match

```xml
<field name="win.eventdata.image" negate="yes">^C:\\Windows\\System32\\</field>
```

### Multiple field values (OR)

```xml
<field name="win.system.eventID">^(4728|4732|4756)$</field>
```

### Time-bounded correlation

```xml
<rule id="100250" level="10" frequency="3" timeframe="300">
  <if_matched_sid>100240</if_matched_sid>
  <same_source_ip />
  <description>3 X events from same source in 5 minutes</description>
</rule>
```

## Testing rules

```bash
# Test a rule against synthetic input
sudo /var/ossec/bin/wazuh-logtest

# Paste a sample log line, see which rule matches
# Useful for debugging "why didn't my rule fire?"
```

## Common gotchas

- **Rule didn't fire**: usually wrong field path. Check actual JSON in Discover before assuming.
- **Manager won't start after rule edit**: XML syntax error. `tail /var/ossec/logs/ossec.log` for the line number.
- **Rule fires too often**: not specific enough. Add a field constraint or use frequency thresholds.
- **`if_sid` chain not working**: parent rule didn't match. Test parent rule independently first.
- **PCRE not matching**: forgot `type="pcre2"`. Default match is simpler regex syntax.
