# Wazuh SIEM Home Lab — Brute-Force Detection with Suricata + Metasploitable3

This project documents a home-lab SOC environment built to practice detection engineering and log correlation.

## Lab Overview

| Component | Role |
|---|---|
| **Wazuh Manager** | Central SIEM — collects, indexes, and correlates logs/alerts |
| **Windows 10 (Agent)** | Monitored endpoint — Wazuh agent installed |
| **Metasploitable3 (Agent)** | Vulnerable target — Wazuh agent installed, monitored for attacks |
| **Suricata** | Network IDS — generates alerts on suspicious traffic, forwarded into Wazuh |
| **Attacker Machine** | Used to simulate a brute-force attack (Hydra/Metasploit) against the target |

## Architecture

```
[Attacker VM] --brute force--> [Metasploitable3 + Wazuh Agent]
                                          |
                                          v
                              [Suricata IDS] --alerts--> [Wazuh Manager]
                                          |
                        [Windows 10 + Wazuh Agent] --logs--> [Wazuh Manager]
                                          |
                                          v
                              [Wazuh Dashboard / Alerts]
```

## What This Demonstrates

- Deploying a Wazuh manager and enrolling multiple OS agents (Windows + Linux)
- Integrating Suricata NIDS alerts into Wazuh via the `eve.json` decoder
- Simulating a brute-force SSH/RDP attack against Metasploitable3
- Correlating authentication failure logs + Suricata network alerts into a single Wazuh alert/rule
- Verifying detection in the Wazuh dashboard

## 1. Install Wazuh Manager

See [`install-wazuh-manager.sh`](./install-wazuh-manager.sh) — uses the official Wazuh all-in-one installation script (manager + indexer + dashboard) for a single-node deployment.

```bash
sudo bash install-wazuh-manager.sh
```

After install, note the generated admin password from the output (also saved to `wazuh-install-files.tar`), then browse to:

```
https://<manager-ip>
```

## 2. Install the Wazuh Agent — Linux (Metasploitable3 / Ubuntu-based)

See [`install-agent-linux.sh`](./install-agent-linux.sh).

```bash
sudo bash install-agent-linux.sh <WAZUH_MANAGER_IP>
```

## 3. Install the Wazuh Agent — Windows 10

See [`install-agent-windows.ps1`](./install-agent-windows.ps1). Run in an **elevated PowerShell** prompt on the Windows 10 machine.

```powershell
.\install-agent-windows.ps1 -ManagerIP "<WAZUH_MANAGER_IP>"
```

## 4. Verify Agents Are Connected

On the Wazuh manager:

```bash
sudo /var/ossec/bin/agent_control -l
```

All agents should show `Active`.

## 5. Suricata Integration

See [`suricata-wazuh-integration.md`](./suricata-wazuh-integration.md) for:
- Installing Suricata on the network sensor / gateway
- Enabling `eve.json` alert logging
- Configuring the Wazuh agent's `ossec.conf` to read Suricata's `eve.json`
- Sample custom rule that fires on repeated auth failures + a Suricata brute-force signature hit

## 6. Simulated Attack

Brute-force test (from attacker VM, against Metasploitable3 SSH):

```bash
hydra -l msfadmin -P /usr/share/wordlists/rockyou.txt ssh://<metasploitable3-ip>
```

This should trigger:
- Multiple Wazuh `authentication_failed` events (rule group `authentication_failures`)
- A Suricata `ET SCAN SSH BruteForce` (or similar) alert
- A correlated custom Wazuh rule (see `custom-rules/brute_force_correlation.xml`) once both conditions are met within the same time window

## 7. Result

Screenshot the Wazuh dashboard alert showing the correlated detection and drop it in `/screenshots`.

---

## Repo Structure

```
.
├── README.md
├── install-wazuh-manager.sh
├── install-agent-linux.sh
├── install-agent-windows.ps1
├── suricata-wazuh-integration.md
├── custom-rules/
│   └── brute_force_correlation.xml
└── screenshots/
```

## Disclaimer

This lab is run entirely on isolated/local virtual machines for educational purposes. Metasploitable3 is an intentionally vulnerable VM designed for this kind of practice — do not run these tools against systems you don't own or have explicit permission to test.
