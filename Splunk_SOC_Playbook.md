# Splunk SOC Analyst Playbook
## Detection, Investigation and Response Procedures

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**Tool:** Splunk Enterprise 9.4.2
**Environment:** SOC Home Lab — Ubuntu 22.04 / Windows 10 / Kali Linux

---

## 1. SOC Alert Triage Workflow

```
Alert Triggered in Splunk
        |
        v
Step 1: Validate Alert (True Positive or False Positive?)
        |
        +-- False Positive --> Document and tune rule
        |
        +-- True Positive --> Continue investigation
        |
        v
Step 2: Scope the Incident (How many hosts? Users? IPs?)
        |
        v
Step 3: Collect Evidence (Logs, IOCs, Timeline)
        |
        v
Step 4: Contain (Block IP, Isolate host, Disable account)
        |
        v
Step 5: Eradicate (Remove malware, patch vulnerability)
        |
        v
Step 6: Recover (Restore systems, monitor for reinfection)
        |
        v
Step 7: Document (Incident report, lessons learned)
```

---

## 2. Essential Splunk Searches for SOC Analysts

### 2.1 Initial Triage — Top Queries

**Find all events in the last 24 hours:**
```spl
index=* earliest=-24h
| stats count by index, sourcetype
| sort - count
```

**Find all failed logins in last hour:**
```spl
index=wineventlog EventCode=4625 earliest=-1h
| stats count by Account_Name, src_ip, host
| sort - count
```

**Find all new processes created:**
```spl
index=sysmon EventCode=1 earliest=-1h
| table _time, host, User, Image, CommandLine, ParentImage
| sort - _time
```

**Find all network connections:**
```spl
index=sysmon EventCode=3 earliest=-1h
| table _time, host, Image, DestinationIp, DestinationPort
| sort - _time
```

---

### 2.2 Account and Authentication Monitoring

**Locked out accounts:**
```spl
index=wineventlog EventCode=4740
| table _time, host, Account_Name, Caller_Computer_Name
| sort - _time
```

**Password changes:**
```spl
index=wineventlog EventCode=4723 OR EventCode=4724
| table _time, host, Account_Name, SubjectUserName
| sort - _time
```

**New user accounts created:**
```spl
index=wineventlog EventCode=4720
| table _time, host, Account_Name, SubjectUserName
| sort - _time
```

**Users added to privileged groups:**
```spl
index=wineventlog EventCode=4728 OR EventCode=4732 OR EventCode=4756
| table _time, host, Account_Name, SubjectUserName, Group_Name
| sort - _time
```

**Admin logons outside business hours:**
```spl
index=wineventlog EventCode=4624 Logon_Type=2
| eval hour=strftime(_time, "%H")
| where hour < 8 OR hour > 18
| table _time, host, Account_Name, src_ip
| sort - _time
```

---

### 2.3 Malware and Process Investigation

**Suspicious parent-child process relationships:**
```spl
index=sysmon EventCode=1
| eval suspicious=case(
    ParentImage LIKE "%winword.exe%" AND Image LIKE "%cmd.exe%", "Word spawning CMD",
    ParentImage LIKE "%excel.exe%" AND Image LIKE "%powershell.exe%", "Excel spawning PowerShell",
    ParentImage LIKE "%outlook.exe%" AND Image LIKE "%wscript.exe%", "Outlook spawning WScript",
    ParentImage LIKE "%chrome.exe%" AND Image LIKE "%cmd.exe%", "Browser spawning CMD",
    true(), "Normal")
| where suspicious != "Normal"
| table _time, host, suspicious, ParentImage, Image, CommandLine
```

**Encoded PowerShell commands:**
```spl
index=sysmon EventCode=1 Image="*powershell*"
| where match(CommandLine, "(?i)-enc|-encodedcommand|-ec\s")
| table _time, host, User, CommandLine
| sort - _time
```

**Suspicious file creation in temp directories:**
```spl
index=sysmon EventCode=11
| where TargetFilename LIKE "%\\Temp\\%.exe"
    OR TargetFilename LIKE "%\\AppData\\%.exe"
    OR TargetFilename LIKE "%\\Downloads\\%.exe"
| table _time, host, Image, TargetFilename
| sort - _time
```

**LSASS memory access (credential dumping):**
```spl
index=sysmon EventCode=10 TargetImage="*lsass.exe*"
| where NOT (SourceImage LIKE "%\\Windows\\System32\\%"
    OR SourceImage LIKE "%\\Windows\\SysWOW64\\%"
    OR SourceImage LIKE "%antivirus%")
| table _time, host, SourceImage, TargetImage, GrantedAccess
| sort - _time
```

---

### 2.4 Network and C2 Detection

**DNS queries to suspicious TLDs:**
```spl
index=sysmon EventCode=22
| rex field=QueryName "\.(?<tld>[^.]+)$"
| where tld IN ("su", "ru", "cn", "tk", "ml", "ga", "cf")
| stats count by QueryName, tld, Image, host
| sort - count
```

**Connections to non-standard ports:**
```spl
index=sysmon EventCode=3
| where NOT DestinationPort IN (80, 443, 53, 8080, 8443, 22, 25, 110, 143)
| where NOT (DestinationIp LIKE "192.168.%" OR DestinationIp="127.0.0.1")
| stats count by DestinationIp, DestinationPort, Image
| sort - count
```

**High frequency outbound connections (beaconing):**
```spl
index=sysmon EventCode=3
| bucket _time span=5m
| stats count by _time, DestinationIp, Image, host
| eventstats avg(count) as avg_count stdev(count) as stdev by DestinationIp
| where count > avg_count + (2 * stdev)
| table _time, host, Image, DestinationIp, count, avg_count
```

**Large data transfers (potential exfiltration):**
```spl
index=sysmon EventCode=3
| stats sum(bytes_out) as total_bytes_out by DestinationIp, Image, host
| eval mb_out = round(total_bytes_out/1024/1024, 2)
| where mb_out > 100
| sort - mb_out
| table host, Image, DestinationIp, mb_out
```

---

### 2.5 Persistence Detection

**Scheduled tasks:**
```spl
index=wineventlog EventCode=4698 OR EventCode=4702
| table _time, host, Account_Name, Task_Name, Task_Content
| sort - _time
```

**Services installed:**
```spl
index=wineventlog EventCode=7045
| table _time, host, Service_Name, Service_File_Name, Service_Type, Service_Account
| sort - _time
```

**Startup folder modifications:**
```spl
index=sysmon EventCode=11
| where TargetFilename LIKE "%\\Start Menu\\Programs\\Startup\\%"
    OR TargetFilename LIKE "%\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\%"
| table _time, host, Image, TargetFilename
```

**Registry persistence keys:**
```spl
index=sysmon EventCode=13
| where TargetObject LIKE "%\\CurrentVersion\\Run%"
    OR TargetObject LIKE "%\\CurrentVersion\\RunOnce%"
    OR TargetObject LIKE "%Winlogon%"
| table _time, host, Image, TargetObject, Details
```

---

## 3. Splunk Dashboard — SOC Overview

### Key Panels to Build

**Panel 1 — Failed Login Attempts (Last 24h)**
```spl
index=wineventlog EventCode=4625 earliest=-24h
| timechart count span=1h
```

**Panel 2 — Top Attacked Accounts**
```spl
index=wineventlog EventCode=4625 earliest=-24h
| top limit=10 Account_Name
```

**Panel 3 — Top Source IPs**
```spl
index=wineventlog EventCode=4625 earliest=-24h
| top limit=10 src_ip
```

**Panel 4 — Suspicious Processes**
```spl
index=sysmon EventCode=1 earliest=-24h
| where Image LIKE "%powershell%" OR Image LIKE "%cmd%" OR Image LIKE "%wscript%"
| timechart count span=1h
```

**Panel 5 — Network Connections by Destination**
```spl
index=sysmon EventCode=3 earliest=-24h
| where NOT (DestinationIp LIKE "192.168.%" OR DestinationIp="127.0.0.1")
| top limit=10 DestinationIp
```

---

## 4. Alert Rules Configured in Lab

| Alert Name | SPL Trigger | Threshold | Severity |
|---|---|---|---|
| RDP Brute Force | EventCode=4625 count > 10 in 5min | 10 failures | High |
| Admin Account Lockout | EventCode=4740 admin accounts | Any | Critical |
| New Admin User Created | EventCode=4720 + 4732 | Any | High |
| LSASS Access | EventCode=10 TargetImage=lsass | Any | Critical |
| Encoded PowerShell | EventCode=1 CommandLine=-enc | Any | High |
| C2 Beaconing | EventCode=3 regular intervals | 10+ per hour | High |
| Suspicious TLD DNS | EventCode=22 .su .tk .ml | Any | Medium |

---

## 5. Splunk Add-ons Installed

| Add-on | Purpose |
|---|---|
| Splunk Add-on for Sysmon v5.0.0 | Parse Sysmon XML events |
| Splunk Add-on for Windows | Windows Event Log parsing |
| Splunk Security Essentials | Pre-built detections |

---

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**LinkedIn:** https://www.linkedin.com/in/aigbokhaode-hope-imomoh-962717393
**GitHub:** https://github.com/aigbokhaodehope7-create
