#!/bin/bash
# install-agent-linux.sh
# Installs and enrolls a Wazuh agent on a Debian/Ubuntu-based Linux host
# (e.g. Metasploitable3's Ubuntu variant)
#
# Usage: sudo bash install-agent-linux.sh <WAZUH_MANAGER_IP> [AGENT_NAME]

set -e

MANAGER_IP="$1"
AGENT_NAME="${2:-$(hostname)}"

if [ -z "$MANAGER_IP" ]; then
  echo "Usage: sudo bash install-agent-linux.sh <WAZUH_MANAGER_IP> [AGENT_NAME]"
  exit 1
fi

echo "[*] Importing Wazuh GPG key and repo..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && \
  chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  | tee /etc/apt/sources.list.d/wazuh.list

apt update

echo "[*] Installing Wazuh agent, pointing it at manager $MANAGER_IP ..."
WAZUH_MANAGER="$MANAGER_IP" WAZUH_AGENT_NAME="$AGENT_NAME" apt install -y wazuh-agent

echo "[*] Enabling and starting the agent..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

echo "[*] Done. Check status with: systemctl status wazuh-agent"
echo "[*] On the manager, confirm enrollment with: /var/ossec/bin/agent_control -l"
