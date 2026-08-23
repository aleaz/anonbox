<div align="center">

# 🧅 Anonbox

## *Turn any Debian VM into an isolated, fail-closed, hardened Tor workstation.*

[![Release](https://img.shields.io/badge/release-v1.0.0-7D4698.svg?style=flat-square&logo=github)](https://github.com/aleaz/anonbox/releases)
[![Debian: 12 | 13](https://img.shields.io/badge/Debian-12%20(Bookworm)%20%7C%2013%20(Trixie)-D70A53.svg?style=flat-square&logo=debian&logoColor=white)](https://www.debian.org/)
[![Tor: Transparent Proxy](https://img.shields.io/badge/Tor-Transparent%20Proxy-7D4698.svg?style=flat-square&logo=torproject&logoColor=white)](https://www.torproject.org/)
[![Hardening: KSPP & Tails](https://img.shields.io/badge/Hardening-KSPP%20%7C%20Tails%20Standard-success.svg?style=flat-square&logo=linux&logoColor=white)](docs/ARCHITECTURE.md)
[![CI](https://github.com/aleaz/anonbox/actions/workflows/lint.yml/badge.svg?style=flat-square)](https://github.com/aleaz/anonbox/actions/workflows/lint.yml)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg?style=flat-square)](LICENSE)

<p align="center">
  🛡️ <b>Fail-Closed nftables</b> &nbsp;•&nbsp; 🔒 <b>KSPP & Yama LSM</b> &nbsp;•&nbsp; 🚫 <b>Zero DNS/IPv6 Leaks</b> &nbsp;•&nbsp; 🔀 <b>Stream Isolation</b>
</p>

</div>

---

## At a Glance

| Specification | Details |
| :--- | :--- |
| **Target OS** | Debian GNU/Linux 12 (Bookworm) and 13 (Trixie) |
| **Architecture** | `ARM64` (Apple Silicon UTM) and `x86_64` (VirtualBox, KVM, Proxmox) |
| **Traffic Policy** | 100% Fail-Closed routing through Tor (`nftables` priority drop) |
| **Security Standards** | KSPP (Kernel Self Protection), Tails OS & Whonix Hardening Patterns |
| **Storage Security** | Verified LUKS2 Full-Disk Encryption & eCryptfs Persistent Volumes |

## Quickstart

Get a hardened anonymous workstation running in under 2 minutes:

```bash
# 1. Clone the repository inside your clean Debian VM
git clone https://github.com/aleaz/anonbox.git
cd anonbox

# 2. Run the automated pipeline (Setup -> Hardening -> 12-Point Security Audit)
sudo ./anonbox all

# Optional: Connect via obfs4 anti-censorship bridges
# sudo ./anonbox all --bridges-file /path/to/bridges.txt

# 3. Reboot to apply kernel sysctl, GRUB memory sanitization, and mount restrictions
sudo reboot
```

> [!IMPORTANT]
> **Prerequisites:** Clean minimal installation of **Debian 12 or 13** with **LUKS Full-Disk Encryption** enabled during guided partitioning.

## Why Anonbox?

| Security Vector | Tails OS (Live USB) | Whonix (2 VMs: Gateway + WS) | Anonbox (This Project) |
| :--- | :--- | :--- | :--- |
| **Deployment Model** | Ephemeral Live USB | 2 Dedicated VMs (Heavy RAM) | **Single Hardened VM (Lightweight)** |
| **Persistence** | Limited to USB Volume | VM Disk Images | **LUKS2 / eCryptfs Encrypted Persistence** |
| **Tor Routing** | iptables/nftables | Hypervisor-isolated Gateway | **Local Fail-Closed nftables Kill-Switch** |
| **Leak Prevention** | Blocked | Blocked | **Kernel-Level Drop (UDP, ICMP, IPv6)** |
| **Stream Isolation** | Per application | Per SocksPort | **Multi-Port Isolation (9050, 9051, 9052)** |
| **Anti-Fingerprint** | UTC, MAC, Hostname | Standardized Identity | **UTC, Auto-MAC, Standardized Machine-ID** |

## System Architecture

```mermaid
flowchart TD
    subgraph Host["Host Machine (macOS / Linux / Windows)"]
        subgraph Guest["anonbox Guest (Debian 12/13 — LUKS2 Encrypted)"]
            Apps["Applications / CLI / Tor Browser"]
            
            Apps -->|TCP Egress| NFT_NAT["nftables NAT: Redirection"]
            Apps -->|UDP Port 53| NFT_NAT
            Apps -->|Non-Tor UDP / ICMP / IPv6| NFT_FILTER["nftables Filter: Drop"]
            
            NFT_NAT -->|TCP to 127.0.0.1:9040| Tor_TransPort["Tor TransPort (:9040)"]
            NFT_NAT -->|DNS to 127.0.0.1:5353| Tor_DNSPort["Tor DNSPort (:5353)"]
            
            Tor_TransPort --> Tor_Core["Tor Core Daemon (uid: debian-tor)"]
            Tor_DNSPort --> Tor_Core
            
            Tor_Core -->|obfs4 / Snowflake / WebTunnel / Direct| Tor_Outbound["Encrypted Tor Traffic"]
        end
        
        Tor_Outbound --> NAT_Adapter["Virtual NAT Adapter"]
    end
    
    NAT_Adapter --> Internet["Internet (Tor Guard Node)"]
    NFT_FILTER -.->|Blocked at Kernel| DropNode["[Destroyed / No Leak]"]
```

## Core Security Pillars

* 🌐 **100% Fail-Closed Transparent Routing:** All outbound TCP and DNS traffic is redirected to Tor (`TransPort 9040` / `DNSPort 5353`). If the Tor daemon terminates, the firewall blocks 100% of clearnet traffic. Non-Tor UDP, ICMP, and IPv6 packets are dropped at kernel level.
* 🛡️ **Kernel & Memory Protection:** Memory zeroing on allocation/free (`init_on_alloc=1`, `init_on_free=1` in GRUB), Yama LSM ptrace restriction (`ptrace_scope=2`), TTY command injection mitigation (`legacy_tiocsti=0`), core dumps disabled, and secure `noexec,nosuid,nodev` mounts for `/tmp`, `/var/tmp`, and `/dev/shm`.
* 🎭 **Anti-Fingerprinting & Telemetry Suppression:** Forced UTC timezone, MAC address randomization at boot (`macchanger` & NetworkManager), neutral hostname (`localhost`), standardized `/etc/machine-id` pool UUID, and Debian `popularity-contest` purging.
* 🔀 **Stream Isolation & Anti-Censorship:** Multi-SOCKS5 circuit isolation (9050, 9051, 9052) preventing traffic correlation across applications, paired with native support for `obfs4`, `Snowflake`, and `WebTunnel` pluggable transports.

## CLI Command Reference (`anonbox`)

The `anonbox` toolkit provides a unified, idempotent CLI interface:

```bash
# Setup Tor transparent proxy, nftables firewall, and DNS routing
sudo ./anonbox setup [--bridges-file FILE | --no-bridges] [--iface IFACE]

# Apply comprehensive OS, Kernel (Yama, GRUB, sysctl), user & filesystem hardening
sudo ./anonbox harden [--iface IFACE] [--dry-run]

# Run the 12-section security, leak detection, and hardening audit suite
sudo ./anonbox check

# Show current Tor connection health, circuits, and public exit IP
./anonbox status

# Rollback configuration to a previous snapshot
sudo ./anonbox rollback

# Uninstall anonbox and restore standard clearnet networking
sudo ./anonbox uninstall
```

## Stream Isolation & Application Routing

Tor stream isolation ensures independent circuits for distinct application classes:

```mermaid
flowchart TD
    subgraph VM["anonbox Workstation"]
        Browser["Tor Browser / Web"] -->|SOCKS5 :9050| CircuitA["Circuit A (Entry -> Middle -> Exit 1)"]
        Wallet["Crypto Wallet / Financial"] -->|SOCKS5 :9051| CircuitB["Circuit B (Entry -> Middle -> Exit 2)"]
        Automation["CLI / Automated Scripts"] -->|SOCKS5 :9052| CircuitC["Circuit C (Entry -> Middle -> Exit 3)"]
    end
    
    CircuitA --> SiteA["Target Website A"]
    CircuitB --> SiteB["Target Service B"]
    CircuitC --> SiteC["Target API C"]
```

| SOCKS5 Port | Isolation Policy | Recommended Use Case |
| :--- | :--- | :--- |
| **`127.0.0.1:9050`** | `IsolateDestAddr`, `IsolateDestPort` | Standard browsing, general tools, package updates |
| **`127.0.0.1:9051`** | `IsolateDestAddr` | Financial apps, cryptocurrency wallets (Monero / Feather) |
| **`127.0.0.1:9052`** | `IsolateDestAddr`, `IsolateDestPort`, `IsolateClientAddr` | Sensitive CLI automation, scraping, isolated sessions |

```bash
# Query endpoint A via isolated circuit
curl --socks5-hostname 127.0.0.1:9051 https://api-a.com

# Query endpoint B via completely different circuit and exit IP
curl --socks5-hostname 127.0.0.1:9052 https://api-b.com
```

## Documentation

* [Software Design Document & Architecture](docs/ARCHITECTURE.md)
* [Threat Model & Acceptance Test Matrix](docs/THREAT_MODEL.md)
* [Hypervisor Configuration Guide (UTM, VirtualBox, KVM)](docs/HYPERVISORS.md)
* [Security Policy & Vulnerability Disclosure](SECURITY.md)
* [Contributing Guidelines](CONTRIBUTING.md)
* [Changelog](CHANGELOG.md)

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See the [LICENSE](LICENSE) file for details.
