# Splunk SPL Detection Queries
## SOC Analyst Query Library — Aigbokhaode Hope Imomoh

A collection of SPL queries written and tested in my SOC home lab environment (Splunk Enterprise 9.4.2).

---

## 1. Brute Force Detection

### RDP Brute Force — Failed then Successful Login
```spl
index=wineventlog EventCode=4625
| stats count by src_ip, user, _time
| where count > 5
| join src_ip [search index=wineventlog EventCode=4624]
| table src_ip, user, count, _time
```

### Multiple Failed Logins from Single Source
```spl
index=wineventlog EventCode=4625
| stats count as failed_attempts by src_ip, Account_Name
| where failed_attempts > 10
| sort - failed_attempts
| table src_ip, Account_Name, failed_attempts
```

### Account Lockout Detection
```spl
index=wineventlog EventCode=4740
| table _time, src_ip, Account_Name, Caller_Computer_Name
| sort - _time
```

---

## 2. Lateral Movement Detection

### RDP Lateral Movement
```spl
index=wineventlog EventCode=4624 Logon_Type=10
| stats count by src_ip, Account_Name, host
| where count > 3
| table src_ip, Account_Name, host, count
```

### Pass the Hash Detection
```spl
index=wineventlog EventCode=4624 Logon_Type=3
| where NOT src_ip="127.0.0.1"
| stats count by src_ip, Account_Name, host
| table src_ip, Account_Name, host, count
```

---

## 3. Persistence Detection

### New Scheduled Task Created
```spl
index=wineventlog EventCode=4698
| table _time, host, Account_Name, Task_Name, Task_Content
| sort - _time
```

### New Service Installed
```spl
index=wineventlog EventCode=7045
| table _time, host, Service_Name, Service_File_Name, Service_Account
| sort - _time
```

### Registry Run Key Modification (Sysmon)
```spl
index=sysmon EventCode=13
| where TargetObject LIKE "%CurrentVersion\\Run%"
| table _time, host, Image, TargetObject, Details
```

---

## 4. Process and Execution Detection

### Suspicious PowerShell Execution (Sysmon)
```spl
index=sysmon EventCode=1 Image="*powershell.exe*"
| where CommandLine LIKE "%-enc%"
    OR CommandLine LIKE "%-encodedcommand%"
    OR CommandLine LIKE "%bypass%"
    OR CommandLine LIKE "%-nop%"
| table _time, host, User, CommandLine
```

### Suspicious Process Creation
```spl
index=sysmon EventCode=1
| where ParentImage LIKE "%cmd.exe%"
    AND (Image LIKE "%net.exe%"
    OR Image LIKE "%whoami.exe%"
    OR Image LIKE "%ipconfig.exe%")
| table _time, host, User, Image, CommandLine, ParentImage
```

### Mimikatz Detection
```spl
index=sysmon EventCode=10
| where TargetImage LIKE "%lsass.exe%"
| table _time, host, SourceImage, TargetImage, GrantedAccess
```

---

## 5. Network Detection

### Unusual Outbound Connections (Sysmon)
```spl
index=sysmon EventCode=3
| where NOT (DestinationIp LIKE "192.168.%"
    OR DestinationIp="127.0.0.1"
    OR DestinationPort=80
    OR DestinationPort=443)
| stats count by Image, DestinationIp, DestinationPort
| sort - count
```

### C2 Beaconing Detection
```spl
index=sysmon EventCode=3
| bucket _time span=1m
| stats count by _time, DestinationIp, Image
| streamstats window=10 avg(count) as avg_connections by DestinationIp
| where count > avg_connections * 2
| table _time, DestinationIp, Image, count, avg_connections
```

### DNS Anomaly Detection
```spl
index=sysmon EventCode=22
| stats count by QueryName, Image, host
| where count > 50
| sort - count
| table QueryName, Image, host, count
```

---

## 6. Threat Hunting Queries

### Hunt for Living off the Land Binaries (LOLBins)
```spl
index=sysmon EventCode=1
| where Image LIKE "%certutil.exe%"
    OR Image LIKE "%mshta.exe%"
    OR Image LIKE "%regsvr32.exe%"
    OR Image LIKE "%rundll32.exe%"
    OR Image LIKE "%wscript.exe%"
    OR Image LIKE "%cscript.exe%"
| table _time, host, User, Image, CommandLine, ParentImage
```

### Hunt for Reconnaissance Activity
```spl
index=wineventlog EventCode=4625
| stats count as attempts, dc(src_ip) as unique_sources by user
| where attempts > 20
| table user, attempts, unique_sources
```

### Hunt for Data Exfiltration
```spl
index=sysmon EventCode=3
| where DestinationPort=443 OR DestinationPort=80
| stats sum(bytes_out) as total_bytes by DestinationIp, Image
| where total_bytes > 10000000
| sort - total_bytes
| table DestinationIp, Image, total_bytes
```

---

## Lab Environment

| Component | Details |
|---|---|
| Splunk Version | Enterprise 9.4.2 |
| OS | Ubuntu 22.04 (SIEM), Windows 10 (target) |
| Sysmon Version | v15.20 |
| Universal Forwarder | Splunk UF 9.x |
| Index Names | wineventlog, sysmon |

---

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**LinkedIn:** https://www.linkedin.com/in/aigbokhaode-hope-imomoh-962717393
**GitHub:** https://github.com/aigbokhaodehope7-create
