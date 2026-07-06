# Homelab Session: OpenVAS Troubleshooting, Sigma-to-Splunk, MITRE ATT&CK Navigator & Resource Planning

## Overview
This entry documents a single working session across the SOC homelab, covering four practical tasks: fixing a GVM/OpenVAS database migration error on Kali, converting community Sigma detection rules into Splunk-compatible queries, standing up MITRE ATT&CK Navigator locally to build a personal technique coverage map, and planning VM resource allocation across a 4-machine lab on a 16GB host.

**Environment**
- Host: 16GB RAM total
- VMs: Kali Linux, Windows 10, Windows Server 2019 (Domain Controller), Ubuntu (Splunk)

---

## 1. OpenVAS / GVM Setup — Database Migration Fix

Running `sudo gvm-check-setup` on Kali returned a clean pass on every check (Scanner, Notus, GVMD Manager, certificates, SCAP/CERT data) except one:

```
Database is wrong version.
ERROR: Database is wrong version. You have installed a new gvmd version
FIX: Run 'sudo runuser -u _gvm -- gvmd --migrate'
```

**Cause:** The gvmd package had been upgraded, but the underlying PostgreSQL database schema hadn't been migrated to match the new version.

**Fix applied:**
```bash
sudo runuser -u _gvm -- gvmd --migrate
sudo gvm-check-setup   # re-run to confirm
sudo gvm-start
```

**Access:** `https://localhost:9392`

**Lesson learned:** `gvm-check-setup` is genuinely useful as a self-diagnosing tool — it doesn't just report errors, it tells you the exact fix command. Worth running after any GVM/OpenVAS package update, not just on first install.

---

## 2. Converting Sigma Rules to Splunk SPL

**Initial mistake:** installed the wrong package entirely.
```bash
sudo apt install sigma-align
```
`sigma-align` is a bioinformatics sequence-alignment tool — completely unrelated. Running `sigma plugin install splunk` against it produced:
```
Error reading from file plugin
Error reading from file install
Error reading from file splunk
Error: no sequences read (check filename and file format): exiting
```

**Correct fix:**
```bash
sudo apt remove sigma-align -y
sudo apt install python3-pip -y
pip install sigma-cli --break-system-packages
sigma plugin install splunk
```

**Usage:**
```bash
sigma convert -t splunk -p splunk <rule_file.yml>
```
This takes a community-maintained Sigma detection rule (vendor/platform-agnostic YAML) and converts it directly into Splunk SPL syntax — turning someone else's published detection logic into a ready-to-use search/alert.

**Lesson learned:** always double-check that a CLI tool name matches the actual project you intend — `sigma` is an extremely generic name, and multiple unrelated tools share it across different domains (bioinformatics vs. security).

---

## 3. Running MITRE ATT&CK Navigator Locally

**Goal:** stand up the official ATT&CK Navigator as a local, self-hosted tool for building a personal technique coverage map, rather than relying on the public MITRE-hosted instance.

**Steps:**
```bash
sudo apt update
sudo apt install git -y
git clone https://github.com/mitre-attack/attack-navigator.git
sudo apt install nodejs npm -y
cd attack-navigator/nav-app
npm install
npm start
```

**First error:** `sh: 1: ng: not found` — the Angular CLI wasn't resolvable from `npm start`.

**Fix:** re-ran `npm install` cleanly, then confirmed `npm start` correctly invoked `ng serve --host 0.0.0.0` once dependencies were fully installed.

**Result:** Application bundle built successfully (3.80MB initial bundle, ~24s build time), serving on:
```
Local:   http://localhost:4200/
Network: http://192.168.56.101:4200/
```

**How it's being used:** Navigator is not a reference tool (that's attack.mitre.org) — it's a workspace for annotating techniques. The plan is to build a single ongoing layer that tracks every technique encountered across this homelab's labs so far:

| Lab | Techniques Mapped |
|---|---|
| Phishing analysis (IR-2023-001) | T1566.001, T1204.002, T1547.001, T1071.001, T1041 |
| XLMRat network forensics | T1105, T1071 |
| CVE-2024-3400 investigation | (technique mapping pending) |
| Brute-force Splunk detection lab | T1110.001 |

Each technique gets color-coded (red = investigated, yellow = understood but undetected, green = working detection built) and annotated with the specific evidence/detection method used — turning scattered lab work into one visual coverage map.

---

## 4. Homelab Resource Planning (16GB Host)

With four VMs in active use, RAM was allocated as follows:

| VM | RAM | Role |
|---|---|---|
| Kali Linux | 3GB | Attacker/analyst machine |
| Windows 10 | 2GB | Client/victim endpoint |
| Windows Server 2019 | 2GB | Domain Controller / DNS |
| Ubuntu | 6GB | Splunk (+ Wazuh planned) |

**Total allocated:** 13GB, leaving ~3GB for host OS overhead.

**Key takeaway:** this allocation only holds up comfortably if VMs are run selectively (1–2 at a time) rather than all four simultaneously. Running everything at once leaves the host OS uncomfortably tight on a 16GB machine. Practical workflow adopted: power on only the VMs needed for the current task (e.g., Ubuntu + Windows Server for AD/DNS work, or Kali + Windows 10 for attack simulation), and fully shut down unused VMs rather than leaving them suspended.

---

## Next Steps
- Finish building the full ATT&CK Navigator coverage layer across all completed labs
- Export the finished layer as an image for the GitHub README and LinkedIn
- Install Wazuh on the Ubuntu VM once Splunk's resource footprint is confirmed stable at 6GB
- Map remaining CVE-2024-3400 findings to their corresponding ATT&CK techniques
