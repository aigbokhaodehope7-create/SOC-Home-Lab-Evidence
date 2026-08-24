# Vulnerability Finding: CVE-2019-16775 (npm Symlink Arbitrary File Write)

| Field | Value |
|---|---|
| CVE ID | [CVE-2019-16775](https://nvd.nist.gov/vuln/detail/CVE-2019-16775) |
| Detected by | Wazuh Vulnerability Detector |
| Host / Agent | `metasploitable3-ub1404` (Agent ID: `002`) |
| IP address | `<METASPLOITABLE3_IP — run 'ip a' on the VM to get this>` |
| Operating system | Ubuntu 14.04.6 LTS "Trusty Tahr" |
| Affected package | npm (Node.js package manager), version `2.15.11` |
| CVSS score | 7.5 (High) — CVSS:3.0/AV:L/AC:L/PR:N/UI:R/S:U/C:N/I:H/A:N |
| Detection date | `2026-08-24` |
| Status | Detected, not remediated (intentional — this VM is meant to stay vulnerable) |

---

## 1. Summary

Wazuh's vulnerability detector picked up CVE-2019-16775 on `metasploitable3-ub1404`. The host is running npm `2.15.11`, which is a long way behind the patched version, `6.13.3`. I used this finding mainly to check that the detection pipeline actually works end to end — outdated package on the host, Wazuh flags it, alert shows up on the dashboard.

Worth noting: `metasploitable3-ub1404` is Rapid7's intentionally-vulnerable training VM, not a production box, so this isn't a "real" risk to anything. It's here to prove the detector caught it. The fact that the installed npm (2015) is four years older than the fix (2019) also says something about how far behind this host is generally, not just on this one package.

---

## 2. Technical details

### What's actually wrong
Before version 6.13.3, the npm CLI didn't check that a package's `bin` field entries actually pointed somewhere inside that package's own `node_modules` folder.

Wazuh's dashboard describes it like this:

> "Versions of the npm CLI prior to 6.13.3 are vulnerable to an Arbitrary File Write. It is possible for packages to create symlinks to files outside the node_modules folder through the bin field upon installation. A properly constructed entry in the package.json bin field would allow a package publisher to create a symlink to arbitrary files on a user's system..."

*(the excerpt above is truncated — paste the rest from the dashboard panel if you want the full text in here)*

### How it plays out in practice
1. A malicious or compromised npm package sets a `bin` field in its `package.json`.
2. When someone runs `npm install`, npm creates a symlink for that entry without verifying it stays inside the package's own directory.
3. That symlink can point anywhere the installing user has write access to — not just inside `node_modules`.
4. No extra interaction needed beyond the install itself. It happens quietly, during a normal `npm install`.

### Related CVEs from the same disclosure
- CVE-2019-16776 — same idea but without the symlink (a direct arbitrary file write via `bin`)
- CVE-2019-16777 — overwriting binaries in the global `node_modules`

### What it can't do
- Can't overwrite a file that already exists at the target path
- Limited to whatever permissions the user running `npm install` has
- No privilege escalation on its own — it rides on the installing user's access, nothing more

---

## 3. Detection / evidence

Screenshot below is from the Wazuh Vulnerability Detection dashboard (`192.168.56.101`), showing CVE-2019-16775 flagged against agent `002` (`metasploitable3-ub1404`).

What the dashboard showed at the time:
- Top 5 vulnerabilities panel — CVE-2019-16775 listed with a count of 1, alongside the related npm CVEs (16776, 16777) plus CVE-2018-7408 and CVE-2020-15095, all on the same agent
- Top 5 OS panel — Ubuntu 14.04.6 LTS "Trusty Tahr" with 5 findings total (this CVE being one of them)
- Top 5 agents panel — `metasploitable3-ub1404` with 5 findings
- Top 5 packages panel — npm with 5 findings (this one npm install is responsible for several of the CVEs on this host, not just this one)
- Dashboard totals at capture time: 34 Critical, 46 High, 20 Medium, 0 Low, 0 Pending

Wazuh rule / alert ID: `<click into the CVE-2019-16775 row on the dashboard to get the specific alert ID>`

Screenshot: `./screenshot-wazuh-cve-2019-16775.png`

npm version confirmed directly on the host:
```bash
npm --version
# Output: 2.15.11
```

---

## 4. Impact

| Factor | Assessment |
|---|---|
| Confidentiality | Not affected — this is a write primitive, not a read |
| Integrity | High. Attacker can create arbitrary new files/symlinks anywhere the installing user can write |
| Availability | Not affected |
| Attack vector | Local — only triggers when someone runs `npm install` against a malicious package |
| User interaction | Required — a developer has to actually install the bad package |
| Likely exploitation path | Supply-chain style — a malicious or typosquatted package on the registry drops a file somewhere useful to an attacker (startup locations, scheduled tasks, etc.) during install |

---

## 5. Remediation

Fix, for reference — not applied on this host: update npm to 6.13.3 or later.

```bash
npm install -g npm@latest
npm --version   # confirm >= 6.13.3
```

A few things worth keeping in mind if this comes up on a real host:
- If npm is bundled with Node.js, update Node too — the fix was backported to Node 10.19.0+, 12.16.0+, and 13.6.0+.
- If npm was installed through the OS package manager (apt, yum, dnf), patch through that channel rather than just the global npm binary, so the system's tracked version actually matches.
- This is a bug in the npm tool itself, not in a project's dependencies, so `npm audit` on individual repos won't catch it — you have to check the npm version directly.

Not applied here because `metasploitable3-ub1404` is meant to stay vulnerable for lab work. This section is really just documenting what the correct fix looks like, in case this same CVE shows up on something that actually matters.

---

## 6. Verification

- [x] CVE-2019-16775 shows up correctly in Wazuh for agent `002` (`metasploitable3-ub1404`)
- [x] Installed npm version (2.15.11) confirmed vulnerable, matches what Wazuh reported
- [ ] N/A — no remediation performed, this is intentional
- [x] Full pipeline checked end to end: outdated package → Wazuh detector → dashboard alert → manual confirmation on the host

---

## 7. References

- [NVD — CVE-2019-16775](https://nvd.nist.gov/vuln/detail/CVE-2019-16775)
- [GitHub Advisory Database](https://github.com/advisories)
- [npm blog — security release notes](https://blog.npmjs.org/)

---

*Documented by Aigbokhaode Hope Imomoh, SOC Analyst Trainee, as part of ongoing home-lab vulnerability management practice with Wazuh.*
