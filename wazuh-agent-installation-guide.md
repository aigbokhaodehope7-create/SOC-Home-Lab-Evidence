# Wazuh Agent Installation Guide — Windows 10, Ubuntu, Kali Linux & Windows Server 2019

A focused, beginner-friendly guide for installing the **Wazuh agent** across
four common endpoint types: **Windows 10**, **Ubuntu**, **Kali Linux**, and
**Windows Server 2019**. This assumes you already have a working Wazuh
manager (server) up and running — if not, see the companion
[Wazuh Installation Guide](./wazuh-installation-guide.md) first.

> 💡 The Wazuh **agent** is a small piece of software installed on each
> endpoint you want to monitor. It collects logs, watches for file changes,
> checks for vulnerabilities, and reports everything back to your Wazuh
> manager for analysis and alerting.

---

## Table of Contents
1. [Before You Start](#1-before-you-start)
2. [Installing on Windows 10](#2-installing-on-windows-10)
3. [Installing on Ubuntu](#3-installing-on-ubuntu)
4. [Installing on Kali Linux](#4-installing-on-kali-linux)
5. [Installing on Windows Server 2019](#5-installing-on-windows-server-2019)
6. [Verifying All Agents Are Connected](#6-verifying-all-agents-are-connected)
7. [Common Issues](#7-common-issues)
8. [References](#8-references)

---

## 1. Before You Start

You'll need:

| Item | Details |
|---|---|
| Wazuh manager IP | e.g. `192.168.1.10` — used on every agent below |
| Wazuh version | Match your manager's version (this guide uses `4.9.x`) |
| Admin/root access | Required on every endpoint |
| Open firewall ports | `1514/tcp` (agent data) and `1515/tcp` (enrollment) on the manager |

> ⚠️ **Version matching matters.** Always install an agent version that
> matches (or is compatible with) your Wazuh manager version. Mismatched
> versions are one of the most common causes of connection problems.

---

## 2. Installing on Windows 10

### 2.1 Download the Agent
Get the `.msi` installer from
[wazuh.com/downloads](https://wazuh.com/downloads/) — pick the Windows
package matching your manager's version.

### 2.2 Install via PowerShell (Run as Administrator)
```powershell
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.9.0-1.msi -OutFile $env:tmp\wazuh-agent.msi
msiexec.exe /i $env:tmp\wazuh-agent.msi /q WAZUH_MANAGER='192.168.1.10' WAZUH_AGENT_GROUP='windows10'
```
- `WAZUH_MANAGER` — your Wazuh manager's IP address.
- `WAZUH_AGENT_GROUP` — optional; assigns the agent to a group in the
  dashboard for easier organization (create the group first, or omit this).

### 2.3 Start the Agent
```powershell
NET START WazuhSvc
```

### 2.4 Confirm It's Running
```powershell
Get-Service -Name WazuhSvc
```
You should see `Status: Running`.

---

## 3. Installing on Ubuntu

Run the following on the Ubuntu machine you want to monitor.

### 3.1 Add the Wazuh GPG Key and Repository
```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && sudo chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update
```

### 3.2 Install the Agent
```bash
sudo WAZUH_MANAGER='192.168.1.10' apt install wazuh-agent -y
```

### 3.3 Enable and Start the Agent
```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

### 3.4 Confirm It's Running
```bash
sudo systemctl status wazuh-agent
```
Look for `active (running)` in green.

---

## 4. Installing on Kali Linux

Kali is Debian-based, so the process is nearly identical to Ubuntu, with one
extra consideration: Kali's rolling-release repos can sometimes conflict
with the Wazuh repo's dependencies, so we install the `.deb` package
directly instead of adding a repository — this avoids most conflicts.

### 4.1 Update Kali First
```bash
sudo apt update && sudo apt upgrade -y
```

### 4.2 Download the Agent Package Directly
```bash
curl -so wazuh-agent.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.0-1_amd64.deb
```
> Check [packages.wazuh.com](https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/)
> for the exact current filename/version before downloading.

### 4.3 Install with the Manager IP Set
```bash
sudo WAZUH_MANAGER='192.168.1.10' dpkg -i ./wazuh-agent.deb
```

### 4.4 Fix Missing Dependencies (If Any)
If `dpkg` reports missing dependencies:
```bash
sudo apt -f install -y
```

### 4.5 Enable and Start the Agent
```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
sudo systemctl status wazuh-agent
```

---

## 5. Installing on Windows Server 2019

The process mirrors Windows 10, with a couple of server-specific notes
around firewall and PowerShell execution policy.

### 5.1 Download the Agent
Same `.msi` package as Windows 10, from
[wazuh.com/downloads](https://wazuh.com/downloads/).

### 5.2 Allow Script Execution (If Blocked)
Server 2019 sometimes restricts script execution by default. If PowerShell
blocks the commands below, run:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
```

### 5.3 Install via PowerShell (Run as Administrator)
```powershell
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.9.0-1.msi -OutFile $env:tmp\wazuh-agent.msi
msiexec.exe /i $env:tmp\wazuh-agent.msi /q WAZUH_MANAGER='192.168.1.10' WAZUH_AGENT_GROUP='winserver2019'
```

### 5.4 Open the Windows Firewall for Outbound Traffic
Server editions often have stricter firewall defaults:
```powershell
New-NetFirewallRule -DisplayName "Wazuh Agent Outbound" -Direction Outbound -Protocol TCP -RemotePort 1514,1515 -Action Allow
```

### 5.5 Start the Agent
```powershell
NET START WazuhSvc
Get-Service -Name WazuhSvc
```

---

## 6. Verifying All Agents Are Connected

### 6.1 From the Manager (CLI)
```bash
sudo /var/ossec/bin/agent_control -l
```
This lists every enrolled agent, its ID, name, IP, and connection status
(`Active`, `Disconnected`, or `Never connected`).

### 6.2 From the Dashboard
1. Log into the Wazuh Dashboard (`https://<manager-ip>`).
2. Go to **Agents** in the left sidebar.
3. Confirm all four endpoints appear with a green **Active** status and a
   recent "Last keep alive" timestamp.

| Agent | Expected OS Field in Dashboard |
|---|---|
| Windows 10 | `Microsoft Windows 10` |
| Ubuntu | `Ubuntu` |
| Kali Linux | `Debian GNU/Linux` (Kali reports as Debian-based) |
| Windows Server 2019 | `Microsoft Windows Server 2019` |

---

## 7. Common Issues

| Symptom | Likely Cause | Fix |
|---|---|---|
| Agent stuck on "Never connected" | Wrong `WAZUH_MANAGER` IP at install time | Uninstall, reinstall with correct IP |
| Agent connects then drops | Firewall closing port 1514/1515 mid-session | Add persistent firewall rules on both ends |
| Kali `dpkg` install fails on dependencies | Missing libs from a minimal Kali image | Run `sudo apt -f install -y` after |
| Windows Server agent won't start | Execution policy blocking install script | Run `Set-ExecutionPolicy RemoteSigned -Scope Process` first |
| Agent shows wrong/old IP after network change | Agent caches manager IP at enrollment | Edit `ossec.conf`'s `<address>` field and restart the agent |
| Version mismatch warning in dashboard | Agent version newer/older than manager | Reinstall the matching agent version |

---

## 8. References
- [Wazuh Agent Installation Documentation](https://documentation.wazuh.com/current/installation-guide/wazuh-agent/index.html)
- [Wazuh Agent Enrollment Guide](https://documentation.wazuh.com/current/user-manual/agent/agent-enrollment/index.html)
- [Wazuh Downloads](https://wazuh.com/downloads/)
- [Wazuh Package Repository (Linux)](https://packages.wazuh.com/)

---

Aigbokhaode Hope Imomoh
