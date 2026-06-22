# SOC Home Lab — Setup Documentation
## Full Technical Build Guide

**Author:** Aigbokhaode Hope Imomoh
**Date:** 2026
**Lab Type:** Multi-VM SOC Environment (VirtualBox)

---

## Lab Overview

This document details the complete setup of my SOC home lab environment, designed to replicate a real enterprise Security Operations Centre. The lab consists of three virtual machines communicating over a host-only network.

---

## Network Architecture

```
+------------------------------------------------------+
|                  VirtualBox Host-Only Network        |
|                  192.168.56.0/24                     |
|                                                      |
|   +-------------+          +----------------------+  |
|   |  Kali Linux |--------->|  Windows 10 Target   |  |
|   |  Attacker   |  Attack  |  192.168.56.103      |  |
|   |  .102       |          |  Sysmon v15 + UF     |  |
|   +-------------+          +----------+-----------+  |
|                                       |               |
|                                       | Log Forward   |
|                                       v               |
|                        +-------------------------+   |
|                        |   Ubuntu 22.04          |   |
|                        |   192.168.56.101        |   |
|                        |   Splunk Enterprise     |   |
|                        |   Suricata IDS          |   |
|                        +-------------------------+   |
+------------------------------------------------------+
```

---

## Virtual Machine Specifications

### VM 1 — Ubuntu (Splunk SIEM)

| Setting | Value |
|---|---|
| OS | Ubuntu 22.04 LTS |
| IP Address | 192.168.56.101 |
| RAM | 4GB |
| Storage | 50GB |
| Role | SIEM, Log Aggregation, IDS |
| Software | Splunk Enterprise 9.4.2, Suricata |

### VM 2 — Windows 10 (Target)

| Setting | Value |
|---|---|
| OS | Windows 10 Pro |
| IP Address | 192.168.56.103 |
| RAM | 2GB |
| Storage | 50GB |
| Role | Target/Victim Machine |
| Software | Sysmon v15.20, Splunk Universal Forwarder |

### VM 3 — Kali Linux (Attacker)

| Setting | Value |
|---|---|
| OS | Kali Linux 2024 |
| IP Address | 192.168.56.102 |
| RAM | 2GB |
| Storage | 30GB |
| Role | Attacker Machine |
| Software | Hydra, Nmap, Wireshark, Metasploit |

---

## Splunk Configuration

### Splunk Enterprise (Ubuntu)

**Installation:**
```bash
wget -O splunk.deb https://download.splunk.com/products/splunk/releases/9.4.2/linux/splunk-9.4.2-linux-amd64.deb
dpkg -i splunk.deb
/opt/splunk/bin/splunk start --accept-license
/opt/splunk/bin/splunk enable boot-start
```

**Receiving Port Configuration:**
- Port: 9997
- Protocol: TCP
- Source: Windows 10 Universal Forwarder

**Indexes Created:**
- wineventlog — Windows Event Logs
- sysmon — Sysmon Events

### Splunk Universal Forwarder (Windows 10)

**inputs.conf configuration:**
```
[WinEventLog://Security]
disabled = false
index = wineventlog

[WinEventLog://System]
disabled = false
index = wineventlog

[WinEventLog://Application]
disabled = false
index = wineventlog

[monitor://C:\Windows\System32\winevt\Logs\Microsoft-Windows-Sysmon%4Operational.evtx]
disabled = false
index = sysmon
sourcetype = XmlWinEventLog:Microsoft-Windows-Sysmon/Operational
```

**outputs.conf configuration:**
```
[tcpout]
defaultGroup = splunk-siem

[tcpout:splunk-siem]
server = 192.168.56.101:9997
```

---

## Sysmon Configuration

**Sysmon Version:** v15.20
**Config:** Custom XML ruleset

**Key Events Monitored:**

| EventCode | Description |
|---|---|
| 1 | Process creation |
| 3 | Network connection |
| 7 | Image loaded |
| 8 | CreateRemoteThread |
| 10 | ProcessAccess (LSASS monitoring) |
| 11 | FileCreate |
| 12/13 | Registry events |
| 22 | DNS query |

**Installation Command:**
```cmd
sysmon64.exe -accepteula -i sysmonconfig.xml
```

---

## Suricata IDS Configuration

**Installation (Ubuntu):**
```bash
apt-get install suricata
suricata-update
systemctl enable suricata
systemctl start suricata
```

**Network Interface:** eth1 (host-only network)
**Rules:** ET Open ruleset + custom rules
**Log Location:** /var/log/suricata/fast.log

---

## Events Ingested

| Source | Event Count |
|---|---|
| Windows Security Log | 3,200+ events |
| Sysmon | 2,700+ events |
| Total | 5,900+ events |

---

## Tools Used

| Tool | Version | Purpose |
|---|---|---|
| VirtualBox | 7.x | Hypervisor |
| Splunk Enterprise | 9.4.2 | SIEM |
| Splunk Universal Forwarder | 9.x | Log forwarding |
| Sysmon | v15.20 | Host telemetry |
| Suricata | 7.x | Network IDS |
| Wireshark | 4.x | Packet analysis |
| Hydra | 9.4 | Attack simulation |
| Nmap | 7.94 | Reconnaissance |

---

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**LinkedIn:** https://www.linkedin.com/in/aigbokhaode-hope-imomoh-962717393
**GitHub:** https://github.com/aigbokhaodehope7-create
