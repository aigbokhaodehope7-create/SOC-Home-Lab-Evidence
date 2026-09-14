# Windows Server 2019 Active Directory & Wazuh SOC Lab

## Project Overview

This project documents the deployment and security monitoring of a small
enterprise-style Windows environment using:

- Windows Server 2019
- Active Directory Domain Services (AD DS)
- DNS Server
- DHCP Server
- Windows 10 domain client
- Wazuh SIEM/XDR
- Ubuntu Server (Wazuh host)
- Kerberos authentication and auditing
- Windows Security Event auditing

The goal of this project was to build a practical cybersecurity monitoring
environment from scratch and understand how a security analyst can monitor
users, computers, authentication activity, and Active Directory changes
from a centralized Wazuh dashboard.

---

## Table of Contents
1. [Lab Architecture](#lab-architecture)
2. [Windows Server 2019 Deployment](#1-windows-server-2019-deployment)
3. [Active Directory Domain Services](#2-active-directory-domain-services)
4. [Windows 10 Domain Join](#3-windows-10-domain-join)
5. [DNS Configuration](#4-dns-configuration)
6. [DHCP Server](#5-dhcp-server)
7. [Active Directory Group Policy](#6-active-directory-group-policy)
8. [Department File Share Security](#7-department-file-share-security)
9. [Kerberos Authentication](#8-kerberos-authentication)
10. [Kerberos Auditing](#9-kerberos-auditing)
11. [Active Directory Auditing](#10-active-directory-auditing)
12. [Active Directory Event Monitoring](#11-active-directory-event-monitoring)
13. [Wazuh Deployment](#12-wazuh-deployment)
14. [Windows Server Wazuh Agent](#13-windows-server-wazuh-agent)
15. [Wazuh Event Verification](#14-wazuh-event-verification)
16. [Kerberoasting Detection Research](#15-kerberoasting-detection-research)
17. [Security Monitoring Architecture](#16-security-monitoring-architecture)
18. [Security Events Currently Being Monitored](#17-security-events-currently-being-monitored)
19. [Key Lessons Learned](#18-key-lessons-learned)
20. [Future Improvements](#19-future-improvements)
21. [Conclusion](#conclusion)
22. [Disclaimer](#disclaimer)

---

## Lab Architecture

```text
                         ┌──────────────────────┐
                         │     Wazuh Manager    │
                         │   Ubuntu Linux VM    │
                         │   192.168.56.121     │
                         └──────────┬───────────┘
                                    │
                              Wazuh Agent
                                    │
                    ┌───────────────┴──────────────┐
                    │                               │
        ┌───────────▼───────────┐      ┌───────────▼──────────┐
        │ Windows Server 2019   │      │ Windows 10 Client    │
        │ Domain Controller     │      │ Domain Joined        │
        │ 192.168.56.115        │      │ 192.168.56.120       │
        │                        │      │                       │
        │ AD DS                  │      │ Users                 │
        │ DNS                    │      │ Endpoint Events       │
        │ DHCP                   │      │ Security Logs         │
        │ Kerberos/KDC           │      │                       │
        └────────────────────────┘      └───────────────────────┘
```

---

## 1. Windows Server 2019 Deployment

A Windows Server 2019 virtual machine was deployed and configured as the
central Windows infrastructure server.

| Component | Configuration |
|---|---|
| Operating System | Windows Server 2019 |
| Hostname | `mrcreativity_server2019` |
| Domain | `hopelabs.local` |
| Server IP | `192.168.56.115` |
| FQDN | `mrcreativity_server2019.hopelabs.local` |

---

## 2. Active Directory Domain Services

Active Directory Domain Services was installed and configured. The domain
created was **`hopelabs.local`**.

An organizational structure was created:

```text
hopelabs.local
│
├── THE_CreativityHub
│   ├── FINANCE
│   ├── HR
│   ├── IT
│   └── Management
│
├── Computers
├── Users
└── Domain Controllers
```

Department-specific users and security groups were created, for example:
- `FINANCE-USERS`
- `HR-USERS`
- `IT-USERS`
- `Management`

This structure allows users and computers to be organized according to
their departments.

---

## 3. Windows 10 Domain Join

A Windows 10 client was joined to the `hopelabs.local` domain.

| Setting | Value |
|---|---|
| Windows 10 IP | `192.168.56.120` |
| Domain | `hopelabs.local` |

The client was successfully joined to Active Directory and moved into the
appropriate organizational unit — demonstrating centralized authentication
and management through Active Directory.

---

## 4. DNS Configuration

DNS was configured on Windows Server 2019. The Windows 10 client was
configured to use:
- **DNS Server:** `192.168.56.115`

DNS resolution was tested using:
```powershell
ping mrcreativity_server2019.hopelabs.local
nslookup mrcreativity_server2019.hopelabs.local
```

Kerberos SRV records were also verified:
```powershell
nslookup -type=SRV _ldap._tcp.dc._msdcs.hopelabs.local
```

These tests confirmed that Active Directory DNS resolution was functioning
correctly.

---

## 5. DHCP Server

DHCP was configured on Windows Server 2019.

**DHCP Scope**

| Setting | Value |
|---|---|
| Network | `192.168.56.0/24` |
| DHCP Server | `192.168.56.115` |
| Client IP | `192.168.56.120` |
| DNS Server | `192.168.56.115` |
| DNS Domain | `hopelabs.local` |

A DHCP reservation was created for the Windows 10 client:

| Setting | Value |
|---|---|
| Client MAC Address | `08-00-27-D9-67-94` |
| Reservation Name | `Windows10-PC` |
| Reserved IP | `192.168.56.120` |

This demonstrated centralized IP address allocation and endpoint network
configuration.

---

## 6. Active Directory Group Policy

Several Group Policy Objects (GPOs) were created and configured for the
environment, including:
- `Finance Department-Policy`
- `HR-Department Policy`
- `IT-Department-Policy`
- `Management-policy`
- `Kerberos Auditing Lab`
- `AD User Group Auditing`

Password security policies were configured, including:
- Minimum password length
- Password complexity
- Account lockout threshold
- Account lockout duration
- Password reset policies

---

## 7. Department File Share Security

A centralized company file structure was created:

```text
C:\CompanyFiles
│
├── HR
├── IT
└── Finance
```

Department security groups were used to control access:

| Group | Folder |
|---|---|
| `HR-USERS` | `HR` |
| `IT-USERS` | `IT` |
| `FINANCE-USERS` | `Finance` |

Both NTFS permissions and SMB share permissions were configured. The
objective was to implement the **principle of least privilege**, so users
only receive access to the resources required for their department.

---

## 8. Kerberos Authentication

Kerberos was studied and configured as part of the Active Directory
security lab. In this environment, the Windows Server 2019 Domain
Controller functions as the **Kerberos Key Distribution Center (KDC)**.

The basic authentication flow:

```text
User
  │
  ▼
Kerberos KDC
  │
  ├── Authentication Service
  │
  └── Ticket Granting Service
          │
          ▼
      Service Ticket
          │
          ▼
      Network Service
```

Important Kerberos events studied:

| Event ID | Description |
|---|---|
| 4768 | Kerberos authentication ticket (TGT) requested |
| 4769 | Kerberos service ticket requested |
| 4771 | Kerberos pre-authentication failed |

---

## 9. Kerberos Auditing

A dedicated GPO named **`Kerberos Auditing Lab`** was created and linked to
the Domain Controllers OU.

The following auditing policies were enabled (Success + Failure):
- Audit Kerberos Authentication Service
- Audit Kerberos Service Ticket Operations

The configuration was verified using:
```powershell
auditpol /get /subcategory:"Kerberos Authentication Service"
auditpol /get /subcategory:"Kerberos Service Ticket Operations"
```

Event ID **4769** was successfully observed in Windows Security logs, and
was also successfully received by Wazuh.

---

## 10. Active Directory Auditing

A dedicated GPO named **`AD User Group Auditing`** was created.

The following audit policies were enabled (Success + Failure):
- Audit User Account Management
- Audit Security Group Management
- Audit Directory Service Changes

Advanced Audit Policy precedence was configured so the policy would
properly apply to the Domain Controller. Verified using:
```powershell
auditpol /get /subcategory:"User Account Management"
auditpol /get /subcategory:"Security Group Management"
auditpol /get /subcategory:"Directory Service Changes"
```

---

## 11. Active Directory Event Monitoring

A test modification was performed against an Active Directory user, which
generated **Event ID 5136** — indicating that an Active Directory object
was modified.

The event was traced through:
```text
Event Viewer → Windows Logs → Security
```

The same event was subsequently verified in Wazuh, confirming that the
entire logging pipeline was functioning end to end.

---

## 12. Wazuh Deployment

Wazuh was deployed on an Ubuntu Linux virtual machine.

| Setting | Value |
|---|---|
| Wazuh Version | `4.14.7` |
| IP Address | `192.168.56.121` |

The Wazuh Manager and Dashboard were configured and verified. Connectivity
was tested from Windows using:
```powershell
Test-NetConnection 192.168.56.121 -Port 443
```
The result confirmed successful connectivity.

---

## 13. Windows Server Wazuh Agent

The Wazuh Agent was installed on the Windows Server 2019 Domain Controller.

| Field | Value |
|---|---|
| Agent Name | `window-server-2019` |
| Agent IP | `192.168.56.115` |

Windows Security events were successfully collected from the agent.

---

## 14. Wazuh Event Verification

Windows Event ID **4769** was successfully identified in Wazuh. Example
fields observed included:
- `data.win.system.channel`
- `data.win.system.eventID`
- `data.win.system.computer`
- `data.win.eventdata.serviceName`
- `data.win.eventdata.targetDomainName`
- `data.win.eventdata.targetUserName`
- `data.win.eventdata.ticketEncryptionType`

This demonstrated that Wazuh was successfully receiving Windows Kerberos
telemetry.

---

## 15. Kerberoasting Detection Research

Kerberoasting was studied from a defensive detection perspective. The key
Windows event investigated was **4769**, with particular attention to the
`TicketEncryptionType` field:

| Value | Encryption |
|---|---|
| `0x11` | AES128 |
| `0x12` | AES256 |
| `0x17` | RC4-HMAC |

RC4-based service ticket requests can be useful for identifying potential
Kerberoasting activity.

> **Note:** a single RC4 ticket does **not** automatically mean a
> Kerberoasting attack is happening.

Detection should consider additional context such as:
- Request volume
- Source computer
- Target service account
- Encryption type
- Normal organizational behavior
- Account type
- Time of activity

---

## 16. Security Monitoring Architecture

The completed monitoring architecture:

```text
                    ┌───────────────────────┐
                    │     Wazuh Manager     │
                    │        Ubuntu         │
                    └───────────┬───────────┘
                                │
                       Centralized Monitoring
                                │
                 ┌──────────────┴──────────────┐
                 │                              │
       ┌─────────▼──────────┐        ┌──────────▼─────────┐
       │ Windows Server 2019│        │ Windows 10 Client  │
       │                     │        │                     │
       │ AD DS               │        │ User activity       │
       │ DNS                 │        │ Logons              │
       │ DHCP                │        │ Processes           │
       │ Kerberos            │        │ Security events     │
       │ Security Events     │        │                     │
       └─────────────────────┘        └─────────────────────┘
```

The Windows Server and Windows client can be monitored as separate
endpoints while being viewed centrally from Wazuh.

---

## 17. Security Events Currently Being Monitored

| Event ID | Purpose |
|---|---|
| 4624 | Successful logon |
| 4625 | Failed logon |
| 4634 | Logoff |
| 4647 | User initiated logoff |
| 4720 | User account created |
| 4722 | User account enabled |
| 4725 | User account disabled |
| 4726 | User account deleted |
| 4728 | Member added to security-enabled global group |
| 4729 | Member removed from security-enabled global group |
| 4732 | Member added to security-enabled local group |
| 4733 | Member removed from security-enabled local group |
| 4768 | Kerberos TGT request |
| 4769 | Kerberos service ticket request |
| 4771 | Kerberos pre-authentication failure |
| 5136 | Active Directory object modified |

---

## 18. Key Lessons Learned

Through this project I learned how to:
- Deploy Windows Server 2019
- Configure Active Directory
- Create OUs, users, and security groups
- Join Windows clients to a domain
- Configure DNS
- Configure DHCP
- Create department-based file permissions
- Configure Group Policy
- Configure Windows Advanced Audit Policy
- Understand Kerberos authentication
- Analyze Windows Security Events
- Deploy Wazuh
- Connect Windows endpoints to Wazuh
- Investigate Windows events from Wazuh
- Understand SIEM-based centralized monitoring
- Begin developing detection logic for Active Directory attacks

---

## 19. Future Improvements

The next stages of this lab will include:
- Install Wazuh Agent on Windows 10
- Monitor workstation login activity
- Monitor multiple Windows endpoints
- Create custom Wazuh detection rules
- Detect suspicious Active Directory activity
- Investigate Kerberoasting telemetry
- Investigate AS-REP Roasting telemetry
- Study Pass-the-Ticket detection
- Study Golden Ticket detection
- Monitor privileged account activity
- Monitor PowerShell activity
- Monitor process creation
- Configure File Integrity Monitoring
- Build dashboards for different departments
- Implement security hardening
- Develop incident-response procedures

---

## Conclusion

This project demonstrates the construction of a small enterprise-style
Active Directory environment with centralized security monitoring.

The lab combines **Active Directory + DNS + DHCP + Group Policy + Kerberos
+ Windows Security Auditing + Wazuh** to create a practical cybersecurity
monitoring environment.

The ultimate objective is to develop the skills required to monitor,
investigate, detect, and respond to security events as a cybersecurity/SOC
analyst.

---

## Disclaimer

This project was created as a controlled cybersecurity laboratory for
learning, monitoring, detection, and defensive security purposes. All
testing was performed within an isolated lab environment.

---

## Suggested Repository Structure

```text
windows-server-ad-wazuh-soc-lab/
│
├── README.md
├── architecture/
│   └── network-diagram.png
├── active-directory/
│   ├── ou-structure.md
│   └── group-policy.md
├── dns-dhcp/
│   └── configuration.md
├── wazuh/
│   ├── agent-installation.md
│   └── detection-rules.md
├── kerberos/
│   └── kerberos-monitoring.md
├── screenshots/
│   ├── active-directory/
│   ├── wazuh/
│   └── event-viewer/
└── incident-detection/
    └── detection-notes.md
```

---

Aigbokhaode Hope Imomoh
