# Security Policy

## Reporting Security Vulnerabilities

The security and anonymity of `debian-anon-vm` users is our highest priority. If you discover a security vulnerability, traffic leak, firewall bypass, or privacy issue, please report it responsibly.

### How to Report

**Please DO NOT open a public GitHub issue for security vulnerabilities.**

Instead, report security issues through one of the following channels:

1. **GitHub Private Vulnerability Reporting:**
   Use the "Report a vulnerability" button under the **Security** tab of this repository.
2. **Email Disclosure:**
   Send an encrypted email (if preferred) or direct message to the maintainer:
   - Maintainer: Alejandro Azario (`aleaz`)
   - Repository: [https://github.com/aleaz/debian-anon-vm](https://github.com/aleaz/debian-anon-vm)

### What to Include in Your Report

To help us triage and resolve the issue quickly, please provide:

- A clear description of the vulnerability (e.g., DNS leak, UDP escape, privilege escalation, bypass of fail-closed rules).
- Step-by-step instructions or proof-of-concept (PoC) scripts to reproduce the issue.
- The environment used for testing (Debian version, architecture `x86_64` vs `ARM64`, Hypervisor `UTM` / `VirtualBox` / `KVM`).
- Any proposed mitigations or fixes if available.

### Response Timeline

- **Acknowledgment:** Within 48 hours of report submission.
- **Assessment & Confirmation:** Within 5 business days.
- **Fix & Coordinated Disclosure:** We aim to release fixes promptly before public disclosure.

---

## Security Boundaries & Model

`debian-anon-vm` is designed as a single-VM transparent proxy with OS-level hardening. Please review [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md) for established security boundaries:

- **In-Scope:** Transparent TCP/DNS Tor routing, fail-closed kill-switch, DNS/UDP/ICMP/IPv6 leak prevention, OS hardening, stream isolation, anti-fingerprinting.
- **Out-of-Scope (Known Limits):** Host machine compromise, physical cold-boot RAM attacks (unless running an amnesic system like Tails), browser fingerprint standardization (use Tor Browser with letterboxing for web browsing).
