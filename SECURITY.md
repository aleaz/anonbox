# Security Policy

## Reporting Security Vulnerabilities

The security and anonymity of `anonbox` users is our highest priority. If you discover a security vulnerability, traffic leak, firewall bypass, or privacy issue, please report it responsibly.

### How to Report

**Please DO NOT open a public GitHub issue for security vulnerabilities.**

Instead, report security issues through one of the following channels:

1. **GitHub Private Vulnerability Reporting:**
   Use the "Report a vulnerability" button under the **Security** tab of this repository.
2. **Email Disclosure:**
   Send a direct message to the maintainer (plain email is acceptable; no public PGP key is published for this project):
   - Maintainer: Alejandro Azario (`aleaz`)
   - Repository: [https://github.com/aleaz/anonbox](https://github.com/aleaz/anonbox)

### What to Include in Your Report

To help us triage and resolve the issue quickly, please provide:

- A clear description of the vulnerability (such as DNS leak, UDP escape, privilege escalation, or bypass of fail-closed rules).
- Step-by-step instructions or proof-of-concept (PoC) scripts to reproduce the issue.
- The environment used for testing (Debian version, architecture `x86_64` vs `ARM64`, Hypervisor `UTM` / `VirtualBox` / `KVM`).
- Any proposed mitigations or fixes if available.

### Response Timeline

- **Acknowledgment:** Within 48 hours of report submission.
- **Assessment & Confirmation:** Within 5 business days.
- **Fix & Coordinated Disclosure:** We aim to release fixes promptly before public disclosure.

---

## Product scope

`anonbox` is a **small Debian toolkit** (one main script + docs): it quickly turns a **standard Debian 12/13 guest VM** into a fail-closed Tor workstation for browsing and general use. It is **not** Tails, Whonix, an amnesic Live OS, or a new anonymous operating system. Value is packaged defaults, hardening, and an audit CLI—not a replacement OS.

### Supported vs unsupported deployment

| | |
| :--- | :--- |
| **Supported** | Dedicated guest VM (UTM, VirtualBox, KVM/QEMU). Prefer hypervisor [NAT / host-only](docs/HYPERVISORS.md) and console admin. |
| **Unsupported / dangerous** | Daily host OS, trusted bare metal, or any machine you need for normal clearnet work. Hardening closes inbound access by default and can lock you out; if the host is compromised, the guest is too ([threat model](docs/THREAT_MODEL.md)). |

### Persistence, encryption, and SSH

- **Persistence is intentional.** Reuse the guest. Amnesia (RAM-only rootfs) is out of scope. For disposable sessions, revert a [hypervisor snapshot](docs/HYPERVISORS.md).
- **Disk encryption is user-provided** at Debian install time. anonbox does **not** set up LUKS/eCryptfs. The script **runs without** encryption. If you **keep data** on the VM, enable encryption (**recommended**). Throwaway / discard-disk / revert-snapshot → optional. `anonbox check` reports **SAFE** only when LUKS or eCryptfs is present (otherwise storage **FAIL**).
- **SSH** is closed by default (hypervisor console preferred). Optional lab: `--allow-ssh` accepts inbound TCP/22 from RFC1918 only; the rule is written to `/etc/nftables.conf` and **persists across reboot**. Re-running `setup`/`all` without `--allow-ssh` regenerates the firewall **without** that rule. Prefer NAT + port-forward or host-only—not an open bridged LAN. Lab SSH is not a max-anonymity posture.

### Security boundaries

Please review [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md) for established security boundaries:

- **In-Scope:** Transparent TCP/DNS Tor routing, fail-closed kill-switch, DNS/UDP/ICMP/IPv6 leak prevention, OS hardening, stream isolation.
- **Residuals:** First `apt`/`git` install over clearnet; TransPort/DNSPort bind on NIC IP (mitigated by nft INPUT drop); MAC cloning under hypervisor NAT is not L2 anti-fingerprint.
- **Out-of-Scope (Known Limits):** Host machine compromise, physical cold-boot RAM attacks, browser fingerprint standardization (use Tor Browser for web browsing), Whonix-style gateway isolation.
