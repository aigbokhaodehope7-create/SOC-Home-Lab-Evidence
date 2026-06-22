# Threat Hunting Hypotheses and Procedures
## SOC Home Lab — Active Threat Hunting

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**Tools:** Splunk Enterprise, Sysmon, Wireshark
**Framework:** MITRE ATT&CK

---

## What is Threat Hunting?

Threat hunting is the proactive search for threats that have evaded automated detection. Unlike reactive security (waiting for alerts), threat hunting assumes the attacker is already inside and actively looks for evidence.

**The Hunting Cycle:**
```
1. Create Hypothesis (based on threat intelligence or ATT&CK)
        |
        v
2. Investigate (query logs, analyse traffic)
        |
        v
3. Identify Patterns (normal vs abnormal)
        |
        v
4. Uncover Threats (or confirm no threat)
        |
        v
5. Inform and Enrich (update detection rules, share IOCs)
```

---

## Hunt 1 — Hunting for RDP Brute Force

**Hypothesis:** An attacker may be attempting to brute-force RDP credentials against Windows hosts on the network.

**ATT&CK Technique:** T1110.001 — Brute Force: Password Guessing

**Data Sources:** Windows Security Event Logs, Sysmon

### Step 1 — Baseline normal login behaviour
```spl
index=wineventlog EventCode=4624 earliest=-7d
| stats count by Account_Name, src_ip, Logon_Type
| sort - count
```

### Step 2 — Hunt for abnormal failed login spikes
```spl
index=wineventlog EventCode=4625 earliest=-24h
| timechart count span=5m by src_ip
| where count > 20
```

### Step 3 — Correlate failures with success
```spl
index=wineventlog (EventCode=4625 OR EventCode=4624) earliest=-24h
| stats count(eval(EventCode=4625)) as failures,
        count(eval(EventCode=4624)) as successes by src_ip, Account_Name
| where failures > 10 AND successes > 0
| eval attack_confirmed=if(successes>0, "YES", "NO")
| table src_ip, Account_Name, failures, successes, attack_confirmed
```

### Finding:
- Source IP 192.168.56.102 made 423 failed attempts against account "Hope"
- Followed by 1 successful login — **attack confirmed**

---

## Hunt 2 — Hunting for Living off the Land (LOLBins)

**Hypothesis:** An attacker may be using legitimate Windows binaries to execute malicious commands and evade antivirus detection.

**ATT&CK Technique:** T1218 — System Binary Proxy Execution

**Data Sources:** Sysmon EventCode 1 (Process Creation)

### Step 1 — Find all LOLBin executions
```spl
index=sysmon EventCode=1
| eval lolbin=case(
    Image LIKE "%certutil.exe%", "certutil",
    Image LIKE "%mshta.exe%", "mshta",
    Image LIKE "%regsvr32.exe%", "regsvr32",
    Image LIKE "%rundll32.exe%", "rundll32",
    Image LIKE "%wscript.exe%", "wscript",
    Image LIKE "%cscript.exe%", "cscript",
    Image LIKE "%msiexec.exe%", "msiexec",
    Image LIKE "%bitsadmin.exe%", "bitsadmin",
    Image LIKE "%forfiles.exe%", "forfiles",
    true(), null())
| where isnotnull(lolbin)
| stats count by lolbin, User, host, CommandLine
| sort - count
```

### Step 2 — Find certutil downloading files
```spl
index=sysmon EventCode=1 Image="*certutil*"
| where CommandLine LIKE "%-urlcache%"
    OR CommandLine LIKE "%-decode%"
    OR CommandLine LIKE "%-encode%"
| table _time, host, User, CommandLine
```

### Step 3 — Find regsvr32 loading remote scripts
```spl
index=sysmon EventCode=1 Image="*regsvr32*"
| where CommandLine LIKE "%http%"
    OR CommandLine LIKE "%/s%/u%"
| table _time, host, User, CommandLine
```

---

## Hunt 3 — Hunting for Lateral Movement

**Hypothesis:** After initial compromise, an attacker may be moving laterally across the network using stolen credentials or pass-the-hash techniques.

**ATT&CK Techniques:** T1021.001 (RDP), T1550.002 (Pass the Hash)

**Data Sources:** Windows Security Logs, Sysmon

### Step 1 — Find all remote logons
```spl
index=wineventlog EventCode=4624
| where Logon_Type=3 OR Logon_Type=10
| stats count by Account_Name, src_ip, host, Logon_Type
| sort - count
```

### Step 2 — Hunt for pass-the-hash indicators
```spl
index=wineventlog EventCode=4624 Logon_Type=3
| where Authentication_Package="NTLM"
    AND NOT Account_Name LIKE "%$"
    AND NOT src_ip="127.0.0.1"
| stats count by Account_Name, src_ip, host
| sort - count
```

### Step 3 — Find accounts logging into multiple hosts
```spl
index=wineventlog EventCode=4624 Logon_Type=3 earliest=-1h
| stats dc(host) as unique_hosts count by Account_Name, src_ip
| where unique_hosts > 3
| table Account_Name, src_ip, unique_hosts, count
```

---

## Hunt 4 — Hunting for C2 Beaconing

**Hypothesis:** A compromised host may be communicating with a C2 server at regular intervals that indicate automated beaconing behaviour.

**ATT&CK Technique:** T1071.001 — Application Layer Protocol: Web Protocols

**Data Sources:** Sysmon EventCode 3, Wireshark PCAP

### Step 1 — Find hosts with regular outbound connections
```spl
index=sysmon EventCode=3 earliest=-4h
| where NOT (DestinationIp LIKE "192.168.%" OR DestinationIp="127.0.0.1")
| bucket _time span=1m
| stats count by _time, DestinationIp, host, Image
| streamstats window=60 stdev(count) as stdev avg(count) as avg by DestinationIp
| where stdev < 2 AND avg > 0.5
| table host, DestinationIp, Image, avg, stdev
```

### Step 2 — Calculate beaconing intervals
```spl
index=sysmon EventCode=3 DestinationIp="[suspicious_ip]"
| sort _time
| streamstats current=f last(_time) as prev_time
| eval interval=_time - prev_time
| stats avg(interval) as avg_interval stdev(interval) as stdev_interval count
| eval regularity=if(stdev_interval < 10, "REGULAR BEACONING", "IRREGULAR")
| table avg_interval, stdev_interval, count, regularity
```

### Step 3 — Validate with Wireshark
```
Filter: ip.dst == [suspicious_ip] && http
Statistics > IO Graph (1 minute intervals)
```
Look for regular spikes confirming beaconing pattern.

---

## Hunt 5 — Hunting for Data Exfiltration

**Hypothesis:** A compromised host may be exfiltrating sensitive data to an external server.

**ATT&CK Technique:** T1041 — Exfiltration Over C2 Channel

**Data Sources:** Sysmon, Wireshark

### Step 1 — Find large outbound transfers
```spl
index=sysmon EventCode=3 earliest=-24h
| where NOT (DestinationIp LIKE "192.168.%" OR DestinationIp="127.0.0.1")
| stats sum(bytes_out) as total_out by host, DestinationIp, Image
| eval mb_out=round(total_out/1024/1024, 2)
| where mb_out > 50
| sort - mb_out
| table host, DestinationIp, Image, mb_out
```

### Step 2 — Check for DNS exfiltration
```spl
index=sysmon EventCode=22
| eval query_length=len(QueryName)
| where query_length > 50
| stats count avg(query_length) as avg_length by QueryName, host
| sort - avg_length
```

### Step 3 — Wireshark validation
```
Filter: ip.src == [compromised_host] && (http || dns)
Statistics > Conversations (sort by bytes A->B)
```

---

## Hunt Summary

| Hunt | Hypothesis | Technique | Result |
|---|---|---|---|
| Hunt 1 | RDP Brute Force | T1110.001 | CONFIRMED — 423 attempts, 1 success |
| Hunt 2 | LOLBin Execution | T1218 | Investigated — No evidence found |
| Hunt 3 | Lateral Movement | T1021.001 | CONFIRMED — RDP session post-compromise |
| Hunt 4 | C2 Beaconing | T1071.001 | CONFIRMED — 60-second interval beaconing |
| Hunt 5 | Data Exfiltration | T1041 | CONFIRMED — Data in C2 POST body |

---

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**LinkedIn:** https://www.linkedin.com/in/aigbokhaode-hope-imomoh-962717393
**GitHub:** https://github.com/aigbokhaodehope7-create
