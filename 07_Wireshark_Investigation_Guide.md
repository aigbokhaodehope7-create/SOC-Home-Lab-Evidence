# Wireshark SOC Investigation Guide
## Network Traffic Analysis for SOC Analysts

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**Tool:** Wireshark 4.x
**Environment:** SOC Home Lab — Kali Linux

---

## 1. Essential Wireshark Filters for SOC Analysts

### 1.1 Basic Traffic Filters

**Show only HTTP traffic:**
```
http
```

**Show only HTTPS/TLS traffic:**
```
tls
```

**Show only DNS traffic:**
```
dns
```

**Show traffic from specific IP:**
```
ip.src == 192.168.56.102
```

**Show traffic to specific IP:**
```
ip.dst == 192.168.56.103
```

**Show traffic between two hosts:**
```
ip.addr == 192.168.56.102 && ip.addr == 192.168.56.103
```

**Show specific port traffic:**
```
tcp.port == 3389
```

**Show all traffic except local:**
```
!ip.addr == 192.168.0.0/16 && !ip.addr == 10.0.0.0/8
```

---

### 1.2 Attack Detection Filters

**Detect port scanning (many SYN packets):**
```
tcp.flags.syn == 1 && tcp.flags.ack == 0
```

**Detect SYN flood:**
```
tcp.flags == 0x002 && !tcp.flags.ack == 1
```

**Detect RDP brute force:**
```
tcp.port == 3389 && tcp.flags.syn == 1
```

**Detect HTTP POST requests (possible C2/exfiltration):**
```
http.request.method == "POST"
```

**Detect large HTTP POST (data exfiltration):**
```
http.request.method == "POST" && http.content_length > 10000
```

**Detect DNS queries to suspicious TLDs:**
```
dns.qry.name contains ".su" || dns.qry.name contains ".tk" || dns.qry.name contains ".ml"
```

**Detect ICMP tunneling:**
```
icmp && data.len > 64
```

**Detect FTP credentials in cleartext:**
```
ftp.request.command == "USER" || ftp.request.command == "PASS"
```

---

### 1.3 Malware and C2 Detection Filters

**Detect Cobalt Strike beaconing pattern:**
```
http.request.method == "POST" && http.request.uri contains "agent"
```

**Detect suspicious User-Agent strings:**
```
http.user_agent contains "curl" || http.user_agent contains "python" || http.user_agent contains "wget"
```

**Detect domain fronting (Host header mismatch):**
```
tls.handshake.extensions_server_name != http.host
```

**Detect DNS tunneling (long subdomain queries):**
```
dns && dns.qry.name matches "^.{50,}"
```

**Detect IRC C2 communication:**
```
tcp.port == 6667 || tcp.port == 6668 || tcp.port == 6669
```

**Detect Tor traffic patterns:**
```
tcp.port == 9001 || tcp.port == 9030
```

---

## 2. Step-by-Step Investigation Procedures

### 2.1 Investigating a Suspected C2 Connection

**Step 1 — Get a high-level overview:**
```
Statistics > Protocol Hierarchy
```
Look for unusual protocols or high percentage of HTTP/HTTPS to unknown IPs.

**Step 2 — Check all conversations:**
```
Statistics > Conversations > TCP tab
```
Sort by bytes to find largest data transfers.

**Step 3 — Filter HTTP POST traffic:**
```
http.request.method == "POST"
```

**Step 4 — Follow TCP stream on suspicious connection:**
Right-click suspicious packet → Follow → TCP Stream
Look for:
- Encoded/encrypted payload
- Unusual URI patterns
- Suspicious User-Agent strings
- Regular intervals between connections

**Step 5 — Check DNS queries:**
```
dns
```
Look for:
- Queries to unusual TLDs (.su, .tk, .ml)
- High-frequency queries to same domain
- Long subdomain names (DNS tunneling)
- DGA (Domain Generation Algorithm) patterns

**Step 6 — Export suspicious objects:**
```
File > Export Objects > HTTP
```
Save and analyse any downloaded files.

---

### 2.2 Investigating RDP Brute Force

**Step 1 — Filter RDP traffic:**
```
tcp.port == 3389
```

**Step 2 — Look for SYN packets from single source:**
```
tcp.flags.syn == 1 && tcp.flags.ack == 0 && ip.dst == [target_ip]
```

**Step 3 — Count connections from source:**
```
Statistics > Conversations
```
Filter by source IP and count TCP connections.

**Step 4 — Check for successful connection:**
Look for full TCP handshake (SYN, SYN-ACK, ACK) followed by RDP protocol data.

**Step 5 — Identify source IP and timestamp:**
Note the source IP, start time, end time, and number of attempts for incident report.

---

### 2.3 Investigating Malware Traffic

**Step 1 — Check for beaconing (regular intervals):**
```
Statistics > IO Graph
```
Set interval to 1 minute. Regular spikes indicate beaconing.

**Step 2 — Identify C2 server:**
```
http.request.method == "POST"
```
Note destination IPs and domains.

**Step 3 — Analyse HTTP headers:**
Follow TCP stream and examine:
- Host header
- User-Agent
- Content-Type
- Cookie values

**Step 4 — Check TLS certificates:**
```
tls.handshake.type == 11
```
Examine certificate issuer, subject, and validity dates.

**Step 5 — Extract IOCs:**
Document all:
- C2 IP addresses
- C2 domains
- URI patterns
- User-Agent strings
- Beaconing intervals
- File hashes (if files downloaded)

---

## 3. PCAP Analysis — Cobalt Strike Investigation

### What I Found in the 48,877 Packet Capture

**Step 1 — Initial statistics:**
```
Statistics > Summary
```
- Duration: ~4 hours
- Total packets: 48,877
- Average packet rate: ~3.4 packets/second

**Step 2 — Protocol hierarchy showed:**
- 64.3% TCP
- 18.2% HTTP
- 12.7% TLS
- 4.3% DNS

**Step 3 — Suspicious HTTP POST traffic:**
Filter used:
```
http.request.method == "POST"
```
Finding: Regular POST requests to `/api/set_agent` every ~60 seconds

**Step 4 — DNS anomalies:**
Filter used:
```
dns.qry.name contains ".su"
```
Finding: 47 queries to `update.windowscdn[.]su` — .su TLD is suspicious

**Step 5 — Domain fronting identified:**
The HTTP Host header showed `cdn.cloudflare.com` but actual backend was different C2 server.

**Step 6 — Beaconing pattern confirmed:**
```
Statistics > IO Graph
```
Regular spikes every 60 seconds confirmed automated C2 beaconing.

---

## 4. Wireshark Display Statistics Used

### Useful Statistics Menus

| Menu | Purpose |
|---|---|
| Statistics > Summary | Overall capture statistics |
| Statistics > Protocol Hierarchy | Protocol distribution |
| Statistics > Conversations | All host-to-host communications |
| Statistics > IO Graph | Traffic volume over time |
| Statistics > DNS | DNS query statistics |
| Statistics > HTTP > Requests | All HTTP requests |
| Statistics > HTTP > Load Distribution | HTTP server load |
| Analyze > Expert Information | Automatic anomaly detection |

---

## 5. Common IOC Extraction Workflow

```
1. Open PCAP in Wireshark
        |
        v
2. Check Protocol Hierarchy (Statistics > Protocol Hierarchy)
        |
        v
3. Review Conversations (Statistics > Conversations)
        |
        v
4. Filter HTTP POST traffic
        |
        v
5. Follow suspicious TCP streams
        |
        v
6. Note all C2 IPs, domains, URIs
        |
        v
7. Check DNS for suspicious queries
        |
        v
8. Export objects (File > Export Objects)
        |
        v
9. Document all IOCs in report
        |
        v
10. Cross-reference with threat intelligence
```

---

## 6. Wireshark Command Line (TShark) for SOC Analysts

**Extract all HTTP hosts from PCAP:**
```bash
tshark -r capture.pcap -Y "http.host" -T fields -e http.host | sort | uniq -c | sort -rn
```

**Extract all DNS queries:**
```bash
tshark -r capture.pcap -Y "dns.flags.response == 0" -T fields -e dns.qry.name | sort | uniq -c | sort -rn
```

**Extract all destination IPs:**
```bash
tshark -r capture.pcap -T fields -e ip.dst | sort | uniq -c | sort -rn | head -20
```

**Find all HTTP POST requests:**
```bash
tshark -r capture.pcap -Y "http.request.method == POST" -T fields -e ip.dst -e http.host -e http.request.uri
```

**Count packets per protocol:**
```bash
tshark -r capture.pcap -q -z io,phs
```

**Extract files from PCAP:**
```bash
tshark -r capture.pcap --export-objects http,/tmp/extracted_files/
```

---

## 7. Key Indicators to Look For

| Indicator | What it Means | Severity |
|---|---|---|
| Regular POST requests at fixed intervals | C2 beaconing | Critical |
| .su/.tk/.ml TLD DNS queries | Malicious infrastructure | High |
| Encoded/encrypted POST body | Hidden C2 communication | High |
| Spoofed User-Agent strings | Malware masquerading as browser | High |
| Large outbound data transfers | Data exfiltration | Critical |
| DNS queries with long subdomains | DNS tunneling | High |
| SYN packets to many ports | Port scanning/reconnaissance | Medium |
| FTP/Telnet cleartext credentials | Credential exposure | High |
| Self-signed TLS certificates | Suspicious encrypted traffic | Medium |
| ICMP packets with large payloads | ICMP tunneling | Medium |

---

**Author:** Aigbokhaode Hope Imomoh — SOC Analyst
**LinkedIn:** https://www.linkedin.com/in/aigbokhaode-hope-imomoh-962717393
**GitHub:** https://github.com/aigbokhaodehope7-create
