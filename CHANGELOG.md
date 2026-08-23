# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Unified standalone CLI entrypoint (`anonbox`) supporting `setup`, `harden`, `check`, `all`, `status`, `rollback`, and `uninstall`.
- Pluggable Transports support (`obfs4`, `Snowflake`, `WebTunnel`).
- Automated signal trapping (`trap cleanup`) for safe temporary file removal.
- Native vector Mermaid architecture, DNS flow, and stream isolation diagrams.
- GitHub Actions CI workflow (`.github/workflows/lint.yml`) for ShellCheck and Markdownlint validation.
- Issue and Pull Request templates for community contribution.

### Changed

- Rebranded project from `debian-anon-vm` to `anonbox`.
- Refined technical documentation tone to meet strict security engineering standards.

### Fixed

- Fixed DNS loopback capture precedence in `nftables` NAT output chain so `127.0.0.1:53` queries are redirected to Tor `DNSPort 5353` before loopback return.
- Replaced static `sleep 20` in `htpdate-tor.service` with deterministic SOCKS port 9050 readiness polling.
- Fixed audit counter isolation in `cmd_check()` to prevent cumulative counter pollution when running `anonbox all`.
- Fixed `/etc/resolv.conf` replacement to ensure `systemd-resolved` symlinks are removed before writing static nameserver configuration.
- Closed boot race condition by asserting `Before=network-pre.target` in `nftables.service.d/override.conf`.

### Security

- **Anti-Fingerprint:** Added native NetworkManager MAC address randomization (`cloned-mac-address=random`) to prevent initial DHCP timing leaks.
- **Firewall:** Eliminated blanket RFC 1918 LAN egress bypass, restricting LAN interactions strictly to established inbound SSH replies.
- **Network Stack:** Disabled TCP timestamps (`net.ipv4.tcp_timestamps = 0`) to eliminate microsecond clock-skew de-anonymization.
- **Kernel:** Enforced full ASLR (`kernel.randomize_va_space = 2`), disabled runtime kernel execution replacement (`kernel.kexec_load_disabled = 1`), and disabled unprivileged user namespaces (`kernel.unprivileged_userns_clone = 0`).
- **Filesystem Hardening:** Hardened `/var/tmp` with `noexec,nosuid,nodev` alongside `/tmp` and `/dev/shm`.
- **Surface Reduction:** Expanded modprobe blacklist with `bluetooth`, `btusb`, `vivid`, and legacy network protocol handlers.
