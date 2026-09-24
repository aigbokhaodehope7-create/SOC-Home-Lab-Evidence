# Mimikatz Credential Dumping - YARA Rule

A YARA rule that detects strings and command patterns commonly associated with
Mimikatz, a tool used for credential dumping, pass-the-hash attacks, and
Kerberos golden ticket generation.

## What it detects

The rule flags a file if it contains 2 or more of the following:

| String | Meaning |
|---|---|
| `mimikatz` | Core tool name |
| `gentilkiwi` | Author signature used internally by the tool |
| `sekurlsa::logonpasswords` | Dumps logon passwords from LSASS memory |
| `sekurlsa::pth` | Pass-the-hash command |
| `lsadump::sam` | Dumps the SAM database |
| `lsadump::secrets` | Dumps LSA secrets |
| `privilege::debug` | Elevates privileges, required before dumping |
| `kerberos::golden` | Generates a golden ticket |
| `wdigest` | Related to WDigest credential caching abuse |

## MITRE ATT&CK mapping

- T1003 - OS Credential Dumping
- T1003.001 - LSASS Memory
- T1550.002 - Pass the Hash
- T1558.001 - Golden Ticket

## Requirements

- YARA installed on your system

Install YARA:

```bash
# Debian / Ubuntu / Kali
sudo apt update
sudo apt install yara

# macOS (Homebrew)
brew install yara

# From source / other platforms
# https://yara.readthedocs.io/en/stable/gettingstarted.html
```

Check it installed correctly:

```bash
yara --version
```

## The rule

Save the block below as `mimikatz_detection.yar`.

```yara
rule Mimikatz_Credential_Dumping
{
    meta:
        author = "Aigbokhaode Hope Imomoh"
        description = "Detects strings commonly associated with Mimikatz credential dumping"
        date = "2026-09-23"
        category = "Credential Access"

    strings:
        $m1 = "mimikatz" nocase ascii wide
        $m2 = "sekurlsa::logonpasswords" nocase ascii wide
        $m3 = "sekurlsa::pth" nocase ascii wide
        $m4 = "lsadump::sam" nocase ascii wide
        $m5 = "lsadump::secrets" nocase ascii wide
        $m6 = "privilege::debug" nocase ascii wide
        $m7 = "kerberos::golden" nocase ascii wide
        $m8 = "gentilkiwi" nocase ascii wide
        $m9 = "wdigest" nocase ascii wide

    condition:
        2 of them
}
```

## Usage

Scan a single file:

```bash
yara mimikatz_detection.yar /path/to/file
```

Scan a directory recursively:

```bash
yara -r mimikatz_detection.yar /path/to/directory
```

Show which strings matched and where:

```bash
yara -s mimikatz_detection.yar /path/to/file
```

Show compile warnings (useful when editing the rule):

```bash
yara -w mimikatz_detection.yar /path/to/file
```

## Testing the rule

### Positive test

Save this as `positive_test.txt`. It should trigger a match.

```
privilege::debug
sekurlsa::logonpasswords
lsadump::sam
```

Run:

```bash
yara -s mimikatz_detection.yar positive_test.txt
```

Expected output:

```
Mimikatz_Credential_Dumping positive_test.txt
0x0:$m6: privilege::debug
0x11:$m2: sekurlsa::logonpasswords
0x2f:$m4: lsadump::sam
```

### Negative test

Save this as `negative_test.txt`. It should produce no output.

```
username: jsmith
password: not_a_real_password
notes: this is a benign file used to confirm the rule does not produce false positives
```

Run:

```bash
yara -w mimikatz_detection.yar negative_test.txt
```

If nothing prints, the rule is not producing false positives on benign
content.

## Notes

This rule is string-based and intended as a detection aid, not a standalone
solution. Attackers can rename binaries, obfuscate command syntax, or use
in-memory/reflective loading to avoid these exact strings. Pair this with
process, network, and behavioral monitoring (e.g. LSASS access alerts,
command-line logging) for better coverage.

## License

MIT License. Free to use, modify, and distribute.

## Author

Aigbokhaode Hope Imomoh
