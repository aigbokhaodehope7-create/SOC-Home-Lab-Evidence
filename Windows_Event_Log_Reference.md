# Windows Event Log Reference Guide
## Critical Event IDs for SOC Analysts

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**Source:** Hands-on SOC home lab analysis

---

## Critical Event IDs Every SOC Analyst Must Know

### Authentication Events

| Event ID | Description | Why It Matters |
|---|---|---|
| 4624 | Successful logon | Track who logged in, from where, and when |
| 4625 | Failed logon | Detect brute force and credential attacks |
| 4634 | Logoff | Track session duration |
| 4647 | User initiated logoff | Normal user activity |
| 4648 | Logon with explicit credentials | Possible lateral movement |
| 4672 | Special privileges assigned | Admin-level access granted |
| 4720 | User account created | New accounts — possible persistence |
| 4722 | User account enabled | Dormant account reactivated |
| 4723 | Password change attempt | Self-service password change |
| 4724 | Password reset by admin | Admin action on account |
| 4725 | User account disabled | Account management |
| 4728 | User added to global security group | Privilege escalation |
| 4732 | User added to local security group | Privilege escalation |
| 4740 | Account locked out | Brute force indicator |
| 4756 | User added to universal security group | Privilege escalation |
| 4776 | Credential validation | NTLM authentication attempt |

### Logon Types

| Logon Type | Description | Risk Level |
|---|---|---|
| 2 | Interactive (local keyboard) | Normal |
| 3 | Network logon | Monitor for lateral movement |
| 4 | Batch logon (scheduled tasks) | Monitor for persistence |
| 5 | Service logon | Monitor for malicious services |
| 7 | Unlock workstation | Normal |
| 8 | Network cleartext | High — credentials sent in clear |
| 9 | New credentials | Monitor for pass-the-hash |
| 10 | Remote interactive (RDP) | Monitor for RDP attacks |
| 11 | Cached interactive | Offline logon |

---

### Process and Execution Events

| Event ID | Description | Why It Matters |
|---|---|---|
| 4688 | New process created | Track all process execution |
| 4689 | Process terminated | Track process lifecycle |
| 4698 | Scheduled task created | Persistence mechanism |
| 4699 | Scheduled task deleted | Attacker cleaning up |
| 4700 | Scheduled task enabled | Persistence activated |
| 4702 | Scheduled task updated | Persistence modified |

---

### System and Service Events

| Event ID | Description | Why It Matters |
|---|---|---|
| 7034 | Service crashed unexpectedly | Possible exploitation |
| 7035 | Service sent start/stop control | Service manipulation |
| 7036 | Service entered running/stopped state | Service state changes |
| 7040 | Service start type changed | Persistence modification |
| 7045 | New service installed | Possible persistence/malware |

---

### Object Access Events

| Event ID | Description | Why It Matters |
|---|---|---|
| 4656 | Object handle requested | File/registry access attempt |
| 4657 | Registry value modified | Registry persistence |
| 4663 | Object access attempted | File access monitoring |
| 4670 | Permissions on object changed | ACL modification |
| 4698 | Scheduled task created | Task-based persistence |

---

### Network Events

| Event ID | Description | Why It Matters |
|---|---|---|
| 5140 | Network share accessed | Lateral movement via SMB |
| 5142 | Network share added | New share created |
| 5144 | Network share deleted | Share removed |
| 5145 | Network share object access | File accessed via network share |
| 5156 | Windows Firewall allowed connection | Outbound connections |
| 5157 | Windows Firewall blocked connection | Blocked connection attempts |

---

### Policy and Audit Events

| Event ID | Description | Why It Matters |
|---|---|---|
| 4616 | System time changed | Log tampering indicator |
| 4657 | Registry value modified | Configuration changes |
| 4719 | System audit policy changed | Attacker disabling logging |
| 4739 | Domain policy changed | Major policy modification |
| 1102 | Audit log cleared | Critical — attacker covering tracks |
| 4946 | Firewall rule added | Firewall bypass |
| 4947 | Firewall rule modified | Firewall bypass |
| 4950 | Firewall setting changed | Security weakening |

---

## Sysmon Event IDs

| Event ID | Description | Key Fields |
|---|---|---|
| 1 | Process creation | Image, CommandLine, ParentImage, User |
| 2 | File creation time changed | TargetFilename, CreationUtcTime |
| 3 | Network connection | Image, DestinationIp, DestinationPort |
| 4 | Sysmon service state changed | State |
| 5 | Process terminated | Image, ProcessId |
| 6 | Driver loaded | ImageLoaded, Signed |
| 7 | Image loaded (DLL) | Image, ImageLoaded, Signed |
| 8 | CreateRemoteThread | SourceImage, TargetImage |
| 9 | RawAccessRead | Image, Device |
| 10 | ProcessAccess (LSASS) | SourceImage, TargetImage, GrantedAccess |
| 11 | FileCreate | Image, TargetFilename |
| 12 | Registry object added/deleted | Image, TargetObject |
| 13 | Registry value set | Image, TargetObject, Details |
| 14 | Registry object renamed | Image, TargetObject |
| 15 | FileCreateStreamHash | Image, TargetFilename |
| 17 | Pipe created | Image, PipeName |
| 18 | Pipe connected | Image, PipeName |
| 22 | DNS query | Image, QueryName, QueryResults |
| 23 | File deleted | Image, TargetFilename |
| 25 | Process tampering | Image, Type |

---

## SPL Queries by Event ID

### Most Used in SOC Operations

```spl
| tstats count where index=wineventlog
    by EventCode
| sort - count
| head 20
```

### Quick Investigation Template
```spl
index=wineventlog EventCode=[EVENT_ID] earliest=-[TIME]
| table _time, host, Account_Name, src_ip, [relevant_fields]
| sort - _time
```

---

## Alert Priority Matrix

| Priority | Event IDs | Action |
|---|---|---|
| P1 — Critical | 1102, 4720+4728, 4625>50 in 5min, EventCode=10 (lsass) | Immediate response |
| P2 — High | 4625>10, 7045, 4698, 4648 | Investigate within 15 min |
| P3 — Medium | 4624 Logon_Type=10, 4732, 4740 | Investigate within 1 hour |
| P4 — Low | 4624 normal, 4634, 4647 | Log and monitor |

---

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**LinkedIn:** https://www.linkedin.com/in/aigbokhaode-hope-imomoh-962717393
**GitHub:** https://github.com/aigbokhaodehope7-create
