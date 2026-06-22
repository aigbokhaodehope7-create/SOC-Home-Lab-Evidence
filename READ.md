# SOC Home Lab Evidence — Aigbokhaode Hope Imomoh

### SOC Analyst | Incident Response | Threat Detection | MITRE ATT&CK

This repository contains real hands-on lab evidence, incident reports, SPL detection queries, and technical documentation from my SOC home lab environment. All work was performed in a fully operational multi-VM lab replicating a real enterprise SOC.

- Author: Aigbokhaode Hope Imomoh
- Role: SOC Analyst (seeking Tier-1/Tier-2 roles and internships)
- Location: Abuja, Nigeria
- LinkedIn: https://www.linkedin.com/in/aigbokhaode-hope-imomoh-962717393
- Email: aigbokhaodehope7@gmail.com

---

## Lab Environment

| Component | Details |
|---|---|
| SIEM | Splunk Enterprise 9.4.2 on Ubuntu 22.04 (192.168.56.101) |
| Target | Windows 10 with Sysmon v15.20 and Universal Forwarder (192.168.56.103) |
| Attacker | Kali Linux with Hydra, Nmap, Wireshark (192.168.56.102) |
| IDS | Suricata on Ubuntu |
| Events Ingested | 5,900+ security events |

---

## Repository Contents

| File | Description | Skills Demonstrated |
|---|---|---|
| 01_Brute_Force_Incident_Report.md | Full IR report — RDP brute force attack detected in Splunk | Incident response, SIEM, MITRE ATT&CK |
| 02_SPL_Detection_Queries.md | 20+ SPL queries for brute force, lateral movement, persistence, C2 | Splunk, threat detection, query writing |
| 03_MITRE_ATTACK_Mapping.md | Full ATT&CK mapping of all lab attack simulations | MITRE ATT&CK, threat intelligence |
| 04_Lab_Setup_Documentation.md | Complete technical build guide for the SOC home lab | Infrastructure, SIEM config, Sysmon |
| 05_Malware_PCAP_Analysis.md | Wireshark analysis of 48,877-packet Cobalt Strike C2 capture | Malware analysis, PCAP, threat hunting |

---

## Key Achievements

- Detected RDP brute force attack (423 failed attempts) using Splunk SPL correlation rules
- Identified Cobalt Strike C2 beaconing via Cloudflare domain fronting in 48,877-packet PCAP
- Mapped all attacks to MITRE ATT&CK (T1110, T1021.001, T1595, T1071.001, T1090.004)
- Built full SOC lab from scratch — Splunk, Sysmon, Suricata, Universal Forwarder
- Produced professional incident reports, IOC lists, and remediation documentation

---

## Certifications

- SOC Analyst Internship Programme (8-module, 12-week) — 2026
- Incident Response, Threat Hunting and MITRE ATT&CK Intensive (6-module) — 2026
- Cybersecurity Training — Neocloud Technology, Abuja — 2025
- CompTIA Security+ SY0-701 — In Progress

---

## Connect With Me

- LinkedIn: https://www.linkedin.com/in/aigbokhaode-hope-imomoh-962717393
- Email: aigbokhaodehope7@gmail.com
- GitHub: https://github.com/aigbokhaodehope7-create
