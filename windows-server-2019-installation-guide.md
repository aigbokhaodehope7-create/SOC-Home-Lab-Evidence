# Windows Server 2019 Installation Guide (Beginner Friendly)

A complete, step-by-step walkthrough for installing **Windows Server 2019**
— covering both virtual machine and bare-metal installs, initial setup, and
basic post-install configuration.

---

## Table of Contents
1. [What You'll Need](#1-what-youll-need)
2. [Step 1: Get the ISO](#2-step-1-get-the-iso)
3. [Step 2: Create Bootable Media](#3-step-2-create-bootable-media)
4. [Step 3: Boot and Start Setup](#4-step-3-boot-and-start-setup)
5. [Step 4: Choose the Edition](#5-step-4-choose-the-edition)
6. [Step 5: Accept License Terms](#6-step-5-accept-license-terms)
7. [Step 6: Choose Install Type](#7-step-6-choose-install-type)
8. [Step 7: Partition the Disk](#8-step-7-partition-the-disk)
9. [Step 8: Set the Administrator Password](#9-step-8-set-the-administrator-password)
10. [Step 9: Post-Install Basic Configuration](#10-step-9-post-install-basic-configuration)
11. [Troubleshooting](#11-troubleshooting)
12. [References](#12-references)

---

## 1. What You'll Need

| Requirement | Details |
|---|---|
| ISO file | Windows Server 2019 evaluation or licensed ISO |
| RAM | 2 GB minimum (4 GB+ recommended) |
| Disk space | 32 GB minimum (more for real workloads) |
| CPU | 1.4 GHz 64-bit, 2 cores recommended |
| Install target | A VM (VirtualBox, VMware, Hyper-V, Proxmox) or physical machine |
| Bootable USB tool | [Rufus](https://rufus.ie/) (bare-metal installs only) |

---

## 2. Step 1: Get the ISO

Download the ISO from one of these sources:
- **Free 180-day trial:** [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2019)
- **Licensed copy:** your organization's Volume Licensing Service Center or
  Visual Studio/MSDN subscription

> 💡 The evaluation edition is a full, unrestricted copy of Server 2019 —
> perfect for labs and this guide. It just expires after 180 days unless
> you activate a real license.

---

## 3. Step 2: Create Bootable Media

### Option A — Installing in a Virtual Machine (Easiest)
No USB needed. Just mount the ISO directly:
- **VirtualBox:** Settings → Storage → click the empty optical drive → choose the ISO
- **VMware Workstation:** VM Settings → CD/DVD → Use ISO image file
- **Hyper-V:** Settings → DVD Drive → Image file
- **Proxmox:** upload the ISO to local storage, attach it to the VM's CD/DVD drive

### Option B — Installing on Physical Hardware
1. Download and install [Rufus](https://rufus.ie/).
2. Insert a USB drive (8 GB minimum — it will be erased).
3. Open Rufus:
   - **Device:** select your USB drive
   - **Boot selection:** click **Select**, choose the Server 2019 ISO
   - **Partition scheme:** `GPT`
   - **Target system:** `UEFI (non CSM)`
4. Click **Start** and wait for it to finish.

---

## 4. Step 3: Boot and Start Setup

1. Boot the VM/machine from the ISO or USB.
2. On the **Windows Setup** screen, choose your **Language**, **Time and
   currency format**, and **Keyboard**, then click **Next**.
3. Click **Install now**.

---

## 5. Step 4: Choose the Edition

You'll be asked to pick one:

| Option | Description |
|---|---|
| **Windows Server 2019 Standard** | For low-density or non-virtualized environments |
| **Windows Server 2019 Standard (Desktop Experience)** | Standard + full GUI |
| **Windows Server 2019 Datacenter** | For highly virtualized/software-defined datacenters |
| **Windows Server 2019 Datacenter (Desktop Experience)** | Datacenter + full GUI |

> 💡 **Beginner tip:** choose a **(Desktop Experience)** option if you want
> the familiar Windows GUI. Without it, you get **Server Core** — a
> command-line-only install that's lighter and more secure, but harder to
> navigate if you're new to Windows Server.

Select your edition and click **Next**.

---

## 6. Step 5: Accept License Terms

Check **I accept the license terms**, then click **Next**.

---

## 7. Step 6: Choose Install Type

You'll see two options:
- **Upgrade** — only used when upgrading an existing Windows Server install
- **Custom: Install Windows only (advanced)** — a clean install

Choose **Custom: Install Windows only (advanced)**.

---

## 8. Step 7: Partition the Disk

1. Select the unallocated drive/partition where you want to install Server 2019.
2. If needed, click **New** to create a partition from unallocated space.
3. Click **Next**.

Setup will now copy files and restart the machine automatically one or more
times — this can take 10–20 minutes depending on your hardware.

---

## 9. Step 8: Set the Administrator Password

On first boot after installation:
1. You'll see **"Customize settings."**
2. Enter and confirm a password for the built-in **Administrator** account.
   - Must meet complexity requirements: 8+ characters, mix of uppercase,
     lowercase, numbers, and symbols.
3. Click **Finish**.

You'll now land on the **Ctrl+Alt+Delete** login screen. Log in with the
`Administrator` account and the password you just set.

---

## 10. Step 9: Post-Install Basic Configuration

### 10.1 Set a Static IP Address
Open PowerShell **as Administrator**:
```powershell
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.10 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8,1.1.1.1
```

### 10.2 Rename the Computer
```powershell
Rename-Computer -NewName "SRV2019-01" -Restart
```

### 10.3 Run Windows Update
```powershell
Install-Module PSWindowsUpdate -Force
Get-WindowsUpdate
Install-WindowsUpdate -AcceptAll -AutoReboot
```

### 10.4 Enable Remote Desktop (Optional)
```powershell
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

### 10.5 Join a Domain (Optional)
```powershell
Add-Computer -DomainName "yourdomain.local" -Credential (Get-Credential) -Restart
```

### 10.6 Configure via Server Manager (GUI Alternative)
If you installed with **Desktop Experience**, all of the above (network
config, computer name, updates, remote desktop) can also be done through
**Server Manager → Local Server**, which opens automatically at login.

---

## 11. Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Setup won't boot from USB | Wrong partition scheme/target system in Rufus | Recreate USB with GPT + UEFI settings |
| "No drives were found" during partitioning | Missing storage/RAID driver | Load the driver via **Load driver** button on that screen |
| Can't log in after setup | Wrong password entered at setup, caps lock on | Retry carefully; reset via recovery if fully locked out |
| Windows Update fails | No internet connectivity configured | Verify static IP/DNS settings from §10.1 |
| VM boots to a black screen | ISO not mounted correctly, or wrong VM firmware (BIOS vs UEFI) | Re-check VM settings match ISO requirements |
| Evaluation edition expired | 180-day trial period ended | Reinstall or apply a full license key via `slmgr /ipk` |

---

## 12. References
- [Windows Server 2019 Evaluation Center](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2019)
- [Microsoft Docs: Install Windows Server](https://learn.microsoft.com/en-us/windows-server/get-started/installation-and-upgrade)
- [Rufus](https://rufus.ie/)
- [PSWindowsUpdate Module](https://www.powershellgallery.com/packages/PSWindowsUpdate)

---

Aigbokhaode Hope Imomoh
