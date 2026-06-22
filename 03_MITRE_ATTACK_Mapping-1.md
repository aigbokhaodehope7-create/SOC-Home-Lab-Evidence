# MITRE ATT&CK Mapping Report
## SOC Home Lab — Attack Simulation and Detection

**Analyst:** Aigbokhaode Hope Imomoh
**Date:** June 2026
**Lab Environment:** VirtualBox — Windows 10 + Ubuntu/Splunk + Kali Linux

---

## Overview

This document maps all attack techniques simulated in the SOC home lab to the MITRE ATT&CK framework, along with the detection methods used and evidence collected.

---

## Attack Simulation 1 — RDP Brute Force

### Attack Flow

```
Kali Linux (192.168.56.102)
        |
        | Hydra RDP Brute Force
        v
Windows 10 Target (192.168.56.103:3389)
        |
        | EventCode 4625 x423 + EventCode 4624 x1
        v
Splunk SIEM (192.168.56.101)
        |
        | SPL Correlation Alert Triggered
        v
SOC Analyst Investigation
```

### MITRE ATT&CK Techniques

| Tactic | Technique | Sub-technique | ID | Detection Method |
|---|---|---|---|---|
| Reconnaissance | Active Scanning | Scanning IP Blocks | T1595.001 | Suricata IDS alert on port scan |
| Credential Access | Brute Force | Password Guessing | T1110.001 | EventCode 4625 threshold alert |
| Credential Access | Brute Force | Password Spraying | T1110.003 | Multiple accounts EventCode 4625 |
| Lateral Movement | Remote Services | Remote Desktop Protocol | T1021.001 | EventCode 4624 Logon Type 10 |
| Credential Access | Modify Authentication Process | — | T1556 | EventCode 4648 monitoring |

### Evidence Collected

| Evidence Type | Source | EventCode |
|---|---|---|
| Failed login attempts (423) | Windows Security Log | 4625 |
| Successful login | Windows Security Log | 4624 |
| RDP session established | Windows Security Log | 4778 |
| Source IP identified | Sysmon Network Event | 3 |
| Process execution (Hydra) | Sysmon Process Create | 1 |

---

## Attack Simulation 2 — Network Reconnaissance

### Attack Flow

```
Kali Linux (192.168.56.102)
        |
        | Nmap -sV -p- 192.168.56.103
        v
Windows 10 Target (192.168.56.103)
        |
        | Network connections detected
        v
Suricata IDS on Ubuntu (192.168.56.101)
        |
        | Port scan alert triggered
        v
SOC Analyst Investigation
```

### MITRE ATT&CK Techniques

| Tactic | Technique | Sub-technique | ID | Detection Method |
|---|---|---|---|---|
| Reconnaissance | Active Scanning | Scanning IP Blocks | T1595.001 | Suricata port scan rule |
| Reconnaissance | Active Scanning | Vulnerability Scanning | T1595.002 | Suricata service detection |
| Discovery | Network Service Discovery | — | T1046 | Sysmon network connections |
| Discovery | System Network Configuration | — | T1016 | Process monitoring |

---

## Attack Simulation 3 — Malware C2 Traffic (PCAP Analysis)

### Traffic Analysis Flow

```
Infected Host
        |
        | HTTP POST /api/set_agent
        v
Cloudflare CDN (Fronted C2)
        |
        | Forwarded to actual C2 server
        v
Cobalt Strike C2 Infrastructure
```

### MITRE ATT&CK Techniques

| Tactic | Technique | Sub-technique | ID | Detection Method |
|---|---|---|---|---|
| Command and Control | Application Layer Protocol | Web Protocols | T1071.001 | Wireshark HTTP analysis |
| Command and Control | Domain Fronting | — | T1090.004 | CDN traffic analysis |
| Command and Control | Ingress Tool Transfer | — | T1105 | Large HTTP POST detection |
| Exfiltration | Exfiltration Over C2 Channel | — | T1041 | Beaconing pattern detection |
| Defense Evasion | Obfuscated Files or Information | — | T1027 | Encrypted payload analysis |

### IOCs Identified

| Type | Value | Confidence |
|---|---|---|
| C2 Endpoint | /api/set_agent | High |
| Beaconing Interval | ~60 seconds | High |
| C2 Domain TLD | .su (Soviet Union) | High |
| HTTP Method | POST | Medium |
| CDN Infrastructure | Cloudflare | High |

---

## Detection Coverage Summary

| MITRE Tactic | Techniques Detected | Detection Tool |
|---|---|---|
| Reconnaissance | T1595.001, T1595.002 | Suricata IDS, Nmap logs |
| Credential Access | T1110, T1110.001, T1110.003 | Splunk (EventCode 4625/4624) |
| Lateral Movement | T1021.001 | Splunk (EventCode 4624 Type 10) |
| Command and Control | T1071.001, T1090.004 | Wireshark PCAP analysis |
| Exfiltration | T1041 | Wireshark beaconing detection |
| Defense Evasion | T1027 | Wireshark payload analysis |

---

## Recommendations

1. Implement endpoint detection rules for all T1110 sub-techniques
2. Deploy DNS monitoring to detect .su and other suspicious TLD queries
3. Configure Splunk alerts for Logon Type 10 (RDP) from non-authorised IPs
4. Enable SSL inspection to detect domain-fronted C2 traffic
5. Implement network segmentation to limit lateral movement opportunities

---

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**LinkedIn:** https://www.linkedin.com/in/aigbokhaode-hope-imomoh-962717393
**GitHub:** https://github.com/aigbokhaodehope7-create
