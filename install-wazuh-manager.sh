#!/bin/bash
# install-wazuh-manager.sh
# Installs Wazuh Manager + Indexer + Dashboard (single-node, all-in-one)
# Tested target: Ubuntu 20.04/22.04
# Run as root: sudo bash install-wazuh-manager.sh

set -e

echo "[*] Updating system packages..."
apt update && apt upgrade -y

echo "[*] Downloading the official Wazuh installation assistant..."
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh

echo "[*] Running all-in-one install (manager + indexer + dashboard)..."
bash wazuh-install.sh -a

echo "[*] Install complete."
echo "[*] Admin credentials are stored in ./wazuh-install-files.tar"
echo "    Extract with: tar -xf wazuh-install-files.tar"
echo "[*] Access the dashboard at: https://<this-machine-ip>"
