# Suricata → Wazuh Integration

This sets up Suricata as a network IDS on the sensor/gateway machine and feeds its
`eve.json` alerts into Wazuh so they show up alongside host-based detections.

## 1. Install Suricata

```bash
sudo apt update
sudo apt install -y suricata
sudo suricata-update
sudo systemctl enable suricata
sudo systemctl start suricata
```

Confirm it's monitoring the right interface in `/etc/suricata/suricata.yaml`
(set `af-packet: - interface: eth0` to match your NIC).

## 2. Confirm eve.json Logging Is Enabled

In `/etc/suricata/suricata.yaml`, under `outputs:`, make sure `eve-log` is enabled
with `types: - alert`. Default path is:

```
/var/log/suricata/eve.json
```

## 3. Point the Wazuh Agent at eve.json

On the same machine running Suricata (or wherever the agent runs), edit
`/var/ossec/etc/ossec.conf` and add a log collection block:

```xml
<ossec_config>
  <localfile>
    <log_format>json</log_format>
    <location>/var/log/suricata/eve.json</location>
  </localfile>
</ossec_config>
```

Restart the agent:

```bash
sudo systemctl restart wazuh-agent
```

## 4. Verify Suricata Alerts Reach Wazuh

Trigger a test alert (e.g. `curl testmynids.org/uid/index.html`), then check the
Wazuh dashboard under **Security Events**, filtering for `rule.groups: suricata`.

Wazuh ships with a built-in Suricata decoder/ruleset (`0465-suricata_rules.xml`),
so alerts should be parsed and categorized automatically — no custom decoder needed
for basic alerts.

## 5. Custom Correlation Rule

To correlate a Suricata brute-force network signature with repeated Wazuh
authentication failures on the same host, see
[`custom-rules/brute_force_correlation.xml`](./custom-rules/brute_force_correlation.xml).

Drop it into `/var/ossec/etc/rules/local_rules.xml` on the manager (or include it
as a separate file referenced in `ossec.conf`), then restart the manager:

```bash
sudo systemctl restart wazuh-manager
```
