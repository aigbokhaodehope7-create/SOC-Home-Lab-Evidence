# Wazuh Agent Installation Guide — Windows Server 2019

A dedicated, step-by-step guide for installing the **Wazuh agent** on
**Windows Server 2019**. This assumes you already have a working Wazuh
manager (server) reachable on your network — if not, see the
[Wazuh Installation Guide](./wazuh-installation-guide.md) first.

> 💡 The Wazuh agent is a lightweight service that runs on the server,
> collects security-relevant logs and events, and sends them to your Wazuh
> manager for analysis, alerting, and dashboarding.

---

## Table of Contents
1. [Before You Start](#1-before-you-start)
2. [Step 1: Prepare the Server](#2-step-1-prepare-the-server)
3. [Step 2: Download the Agent](#3-step-2-download-the-agent)
4. [Step 3: Install the Agent](#4-step-3-install-the-agent)
5. [Step 4: Configure the Windows Firewall](#5-step-4-configure-the-windows-firewall)
6. [Step 5: Start and Enable the Agent](#6-step-5-start-and-enable-the-agent)
7. [Step 6: Verify the Connection](#7-step-6-verify-the-connection)
8. [Optional: Enable Extra Monitoring](#8-optional-enable-extra-monitoring)
9. [Uninstalling the Agent](#9-uninstalling-the-agent)
10. [Troubleshooting](#10-troubleshooting)
11. [References](#11-references)

---

## 1. Before You Start

| Item | Details |
|---|---|
| OS | Windows Server 2019 (any edition — Standard/Datacenter) |
| Access | Local Administrator rights |
| Wazuh manager IP | e.g. `192.168.1.10` |
| Wazuh agent version | Should match your manager version (this guide uses `4.9.x`) |
| Network | Server must be able to reach the manager on ports `1514` and `1515` |

> ⚠️ Always match the agent version to your manager's version. Installing a
> mismatched agent is the #1 cause of "connects then drops" issues.

---

## 2. Step 1: Prepare the Server

### 2.1 Confirm Network Connectivity to the Manager
Open PowerShell and test that the server can reach the Wazuh manager:
```powershell
Test-NetConnection -ComputerName 192.168.1.10 -Port 1514
```
Look for `TcpTestSucceeded : True`. If it returns `False`, resolve
networking/firewall issues on the **manager side** before continuing.

### 2.2 Check Windows Update Status (Recommended)
Keeping the server patched avoids unrelated install issues:
```powershell
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5
```

### 2.3 Allow Script Execution
Windows Server locks down PowerShell script execution by default. Allow it
for this session only:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
```

---

## 3. Step 2: Download the Agent

### 3.1 Find the Correct Package
Go to [wazuh.com/downloads](https://wazuh.com/downloads/) and copy the
download link for the **Windows agent `.msi`** matching your manager's
version.

### 3.2 Download via PowerShell
Run PowerShell **as Administrator**:
```powershell
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.9.0-1.msi -OutFile $env:tmp\wazuh-agent.msi
```
> Replace `4.9.0-1` with the exact version shown on the downloads page.

---

## 4. Step 3: Install the Agent

### 4.1 Silent Install with Manager IP Set
```powershell
msiexec.exe /i $env:tmp\wazuh-agent.msi /q WAZUH_MANAGER='192.168.1.10' WAZUH_AGENT_GROUP='winserver2019'
```
- **`WAZUH_MANAGER`** — IP or hostname of your Wazuh manager. Required.
- **`WAZUH_AGENT_GROUP`** — optional; assigns this agent to a group (create
  the group in the dashboard first, or drop this parameter).
- **`/q`** — runs the installer silently, with no popup windows.

### 4.2 Confirm the Install Succeeded
```powershell
Get-Package -Name "Wazuh Agent"
```
This should return the package name and version if the install worked.

---

## 5. Step 4: Configure the Windows Firewall

Server editions typically have stricter default firewall rules than
Windows 10, so add explicit outbound rules for the agent:

```powershell
New-NetFirewallRule -DisplayName "Wazuh Agent Outbound TCP 1514" -Direction Outbound -Protocol TCP -RemotePort 1514 -Action Allow
New-NetFirewallRule -DisplayName "Wazuh Agent Outbound TCP 1515" -Direction Outbound -Protocol TCP -RemotePort 1515 -Action Allow
```
- **1514** — used for ongoing agent-to-manager data (logs, events).
- **1515** — used briefly during enrollment/registration.

---

## 6. Step 5: Start and Enable the Agent

### 6.1 Start the Service
```powershell
NET START WazuhSvc
```

### 6.2 Set It to Start Automatically on Boot
```powershell
Set-Service -Name WazuhSvc -StartupType Automatic
```

### 6.3 Confirm the Service Status
```powershell
Get-Service -Name WazuhSvc
```
Expected output:
```
Status   Name               DisplayName
------   ----               -----------
Running  WazuhSvc           Wazuh Agent
```

---

## 7. Step 6: Verify the Connection

### 7.1 Check from the Server Itself
```powershell
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 20
```
Look for a line similar to:
```
INFO: Connected to the server (192.168.1.10:1514)
```

### 7.2 Check from the Wazuh Manager
On the manager:
```bash
sudo /var/ossec/bin/agent_control -l
```
Your server should appear in the list with status **Active**.

### 7.3 Check from the Dashboard
1. Log into `https://<manager-ip>`.
2. Go to **Agents**.
3. Find your server — the **OS** column should read
   `Microsoft Windows Server 2019`, with a green **Active** status.

---

## 8. Optional: Enable Extra Monitoring

### 8.1 File Integrity Monitoring (FIM)
Edit `C:\Program Files (x86)\ossec-agent\ossec.conf` and add folders you
want watched for changes inside the `<syscheck>` block:
```xml
<syscheck>
  <directories check_all="yes" report_changes="yes">C:\Windows\System32\drivers\etc</directories>
</syscheck>
```

### 8.2 Windows Event Log Collection
By default, the agent already forwards Application, Security, and System
event logs. To add more (e.g. PowerShell logs), add inside `<localfile>`:
```xml
<localfile>
  <location>Microsoft-Windows-PowerShell/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
```

Restart the service after any config change:
```powershell
Restart-Service WazuhSvc
```

---

## 9. Uninstalling the Agent

If you ever need to remove it cleanly:
```powershell
Get-Package -Name "Wazuh Agent" | Uninstall-Package
```

---

## 10. Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `Test-NetConnection` fails on port 1514 | Firewall blocking traffic (either side) | Check both server and manager firewall rules |
| Service installed but won't start | Corrupted `.msi` download | Re-download and reinstall |
| Agent shows "Never connected" in dashboard | Wrong manager IP entered at install | Uninstall, reinstall with correct `WAZUH_MANAGER` |
| `ossec.log` shows repeated connection retries | Manager's port 1514 not open, or manager service down | Verify `wazuh-manager` service is running on the server |
| PowerShell blocks the install commands | Execution policy restriction | Run `Set-ExecutionPolicy RemoteSigned -Scope Process` first |
| Agent version mismatch warning | Installed agent doesn't match manager version | Uninstall and reinstall the matching version |

---

## 11. References
- [Wazuh Agent Installation — Windows](https://documentation.wazuh.com/current/installation-guide/wazuh-agent/wazuh-agent-package-windows.html)
- [Wazuh Agent Enrollment Guide](https://documentation.wazuh.com/current/user-manual/agent/agent-enrollment/index.html)
- [Wazuh Downloads](https://wazuh.com/downloads/)

---

Aigbokhaode Hope Imomoh
