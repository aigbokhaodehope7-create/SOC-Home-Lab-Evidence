# Incident Response Report
## RDP Brute Force Attack — Detection and Analysis

**Report ID:** IR-2026-001
**Date:** June 2026
**Analyst:** Aigbokhaode Hope Imomoh
**Severity:** HIGH
**Status:** Resolved

---

## 1. Executive Summary

A brute-force attack targeting the Remote Desktop Protocol (RDP) service was detected on the Windows 10 target host (192.168.56.103). The attacker, originating from Kali Linux (192.168.56.102), used the Hydra password-cracking tool to systematically attempt authentication against the local user account "Hope". The attack was detected via Splunk SIEM through correlation of Windows Event Logs forwarded by the Splunk Universal Forwarder and Sysmon telemetry.

The attack successfully resulted in an authenticated RDP session after repeated failed login attempts, confirming credential compromise. The full attack chain was mapped to the MITRE ATT&CK framework and remediation steps were implemented.

---

## 2. Incident Timeline

| Time | Event |
|---|---|
| 08:15:00 | Attacker begins Hydra RDP brute-force from 192.168.56.102 |
| 08:15:01 - 08:17:43 | 423 failed login attempts detected (EventCode 4625) |
| 08:17:44 | Successful authentication achieved (EventCode 4624) |
| 08:17:45 | RDP session established by attacker |
| 08:18:10 | Splunk alert triggered on brute-force correlation rule |
| 08:20:00 | Analyst triages alert and begins investigation |
| 08:35:00 | Incident confirmed — attacker session terminated |
| 08:40:00 | Remediation steps implemented |

---

## 3. Attack Details

### 3.1 Attacker Information

| Field | Value |
|---|---|
| Source IP | 192.168.56.102 (Kali Linux) |
| Tool Used | Hydra v9.4 |
| Target IP | 192.168.56.103 (Windows 10) |
| Target Port | 3389 (RDP) |
| Target Account | Hope |
| Attack Duration | 2 minutes 44 seconds |
| Failed Attempts | 423 |

### 3.2 Attack Command (Reconstructed)

```bash
hydra -l Hope -P /usr/share/wordlists/rockyou.txt rdp://192.168.56.103
```

### 3.3 Detection Evidence

**Splunk SPL Query Used:**

```spl
index=wineventlog EventCode=4625
| stats count by src_ip, user, _time
| where count > 5
| join src_ip [search index=wineventlog EventCode=4624]
| table src_ip, user, count, _time
```

**Key Windows Event IDs Observed:**

| Event ID | Description | Count |
|---|---|---|
| 4625 | Failed logon attempt | 423 |
| 4624 | Successful logon | 1 |
| 4648 | Logon with explicit credentials | 1 |
| 4776 | Credential validation attempt | 424 |

---

## 4. MITRE ATT&CK Mapping

| Tactic | Technique | ID | Description |
|---|---|---|---|
| Reconnaissance | Active Scanning | T1595 | Attacker scanned target for open RDP port |
| Credential Access | Brute Force | T1110 | Hydra used to brute-force RDP credentials |
| Credential Access | Password Guessing | T1110.001 | Dictionary attack using rockyou.txt wordlist |
| Lateral Movement | Remote Desktop Protocol | T1021.001 | RDP used for remote access after credential compromise |
| Credential Access | Modify Authentication Process | T1556 | Attacker modified auth process post-compromise |

---

## 5. Indicators of Compromise (IOCs)

| Type | Value | Description |
|---|---|---|
| IP Address | 192.168.56.102 | Attacker source IP |
| Username | Hope | Targeted account |
| Port | 3389 | RDP service port |
| Process | hydra.exe | Attack tool process name |
| Event Pattern | 423x EventCode 4625 followed by EventCode 4624 | Brute-force pattern |

---

## 6. Root Cause Analysis

1. RDP was exposed on the network without IP allowlisting
2. Network Level Authentication (NLA) was disabled on the target host
3. No account lockout policy was configured — unlimited login attempts permitted
4. Weak password policy allowed dictionary attack to succeed
5. No MFA was configured on the RDP service

---

## 7. Remediation Actions Taken

| Action | Status |
|---|---|
| Terminated active attacker RDP session | Completed |
| Enabled Network Level Authentication (NLA) | Completed |
| Configured account lockout policy (5 attempts / 30 min lockout) | Completed |
| Restricted RDP access to authorised IPs only via Windows Firewall | Completed |
| Forced password reset on compromised account | Completed |
| Enabled Windows Defender and reviewed AV logs | Completed |

---

## 8. Recommendations

1. Implement Multi-Factor Authentication (MFA) on all remote access services
2. Disable RDP on hosts that do not require it
3. Deploy a VPN gateway — require VPN before RDP access is permitted
4. Enable advanced audit logging on all authentication events
5. Configure Splunk alerts for brute-force patterns on all critical accounts
6. Conduct regular password audits and enforce strong password policies

---

## 9. Lessons Learned

- Account lockout policies are a critical first line of defence against brute-force attacks
- Splunk SIEM correlation rules successfully detected the attack pattern in real time
- NLA disabled on RDP significantly lowers the barrier for unauthenticated attack attempts
- Log forwarding via Sysmon and Universal Forwarder provided sufficient telemetry for full investigation

---

**Report Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**LinkedIn:** https://www.linkedin.com/in/aigbokhaode-hope-imomoh-962717393
**GitHub:** https://github.com/aigbokhaodehope7-create
