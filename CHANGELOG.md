# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-23

### Added

- Unified standalone CLI entrypoint (`anonbox`) supporting `setup`, `harden`, `check`, `all`, `status`, `rollback`, and `uninstall`.
- Pluggable Transports support (`obfs4`, `Snowflake`, `WebTunnel`) and bridge template file (`bridges.txt.example`).
- Verbose CLI mode (`--verbose`, `-v`) for comprehensive command tracing, system discovery, and debugging.
- Visual phase banners in `anonbox all` (`[FASE 1/3]`, `[FASE 2/3]`, `[FASE 3/3]`) to clearly separate deployment stages.
- Real-time Tor bootstrap percentage parser (`25%`, `80%`, `100%`) replacing static point indicators.
- Live in-memory `nftables` kernel table verification in audit suite (`cmd_check`).
- Extended backup snapshots in `cmd_harden` (`/etc/fstab`, `/etc/default/grub`, `/etc/login.defs`, `/etc/pam.d/su`, `/etc/hosts`, `sysctl`) and full multi-file automated restoration in `cmd_rollback`.
- Automated signal trapping (`trap cleanup EXIT INT TERM HUP`) for safe temporary file removal on terminal drops.
- Pre-flight operating system detection and validation (`validate_os`) for Debian 12 and 13.
- Storage encryption verification for `eCryptfs` and `LUKS`/dm-crypt partitions in `check`, `status`, `setup`, and `harden`.
- Native vector Mermaid architecture, DNS flow, and stream isolation diagrams.
- GitHub Actions CI workflow (`.github/workflows/lint.yml`) for ShellCheck and Markdownlint validation.
- Issue and Pull Request templates for community contribution.

### Changed

- Rebranded project from `debian-anon-vm` to `anonbox`.
- Refined technical documentation tone to meet strict security engineering standards.
- Enforced `DEBIAN_FRONTEND=noninteractive` across all package manager operations for unattended/CI execution.
- Allowed `--dry-run` preview execution without requiring root privileges.
- Enhanced `anonbox status` to display active SOCKS isolation ports, local DNS interceptor, and hardware MAC address.
- Added smart package presence verification (`dpkg -s`) to skip redundant `apt-get` calls during re-runs under active fail-closed firewall.
- Integrated dual-destination logging (`/var/log/tor/notices.log` and `syslog`) with automatic permissions setup.

### Fixed

- Fixed Tor bootstrap stall on re-runs by detecting daemon crashes in real time, inspecting multi-source logs, and pre-validating system UTC clock skew.
- Fixed Tor daemon UID resolution by dynamically re-evaluating `TOR_UID` post-package installation in `cmd_setup`, preventing firewall drops on fresh Debian installs.
- Hardened `cmd_uninstall` to completely stop custom services (`htpdate-tor`, `macchanger@`), unmask system daemons (`systemd-timesyncd`, `cups`, `bluetooth`), and restore standard clearnet DNS.
- Fixed live kernel atomic ruleset reloading by invoking `nft -f` directly in addition to `systemctl restart nftables.service`.
- Fixed arithmetic post-increment exit code under Bash `set -e` in logging and accounting routines.
- Fixed DNS loopback capture precedence in `nftables` NAT output chain so `127.0.1.1` and `127.0.0.1:53` queries are redirected to Tor `DNSPort 5353` before loopback return.
- Replaced static `sleep 20` in `htpdate-tor.service` with deterministic SOCKS port 9050 readiness polling.
- Fixed audit counter isolation in `cmd_check()` to prevent cumulative counter pollution when running `anonbox all`.
- Fixed `/etc/resolv.conf` replacement to ensure `systemd-resolved` symlinks are removed before writing static nameserver configuration.
- Closed boot race condition by asserting `Before=network-pre.target` in `nftables.service.d/override.conf`.

### Security

- **Identity Camouflage:** Standardized `/etc/machine-id` and `/var/lib/dbus/machine-id` to a uniform anonymity pool UUID, preventing cross-session tracking by local applications.
- **Telemetry Suppression:** Purged Debian `popularity-contest` package and disabled NetworkManager periodic connectivity check (`[connectivity] enabled=false`).
- **DHCP Privacy:** Suppressed DHCP Option 12 hostname broadcast (`dhcp-send-hostname=false`) in NetworkManager configuration.
- **Service Masking:** Disabled and masked location daemon `geoclue` and crash telemetry daemons (`kerneloops`, `whoopsie`).
- **Anti-Fingerprint:** Added native NetworkManager MAC address randomization (`cloned-mac-address=random`) to prevent initial DHCP timing leaks.
- **Firewall:** Eliminated blanket RFC 1918 LAN egress bypass, restricting LAN interactions strictly to established inbound SSH replies.
- **Network Stack:** Disabled TCP timestamps (`net.ipv4.tcp_timestamps = 0`) to eliminate microsecond clock-skew de-anonymization.
- **Kernel:** Enforced full ASLR (`kernel.randomize_va_space = 2`), disabled runtime kernel execution replacement (`kernel.kexec_load_disabled = 1`), and disabled unprivileged user namespaces (`kernel.unprivileged_userns_clone = 0`).
- **Filesystem Hardening:** Hardened `/var/tmp` with `noexec,nosuid,nodev` alongside `/tmp` and `/dev/shm`.
- **Surface Reduction:** Expanded modprobe blacklist with `bluetooth`, `btusb`, `vivid`, and legacy network protocol handlers.
