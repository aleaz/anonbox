# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- CLI remediations: `fail_fix` prints actionable `Fix:` lines; audit summary lists **Next steps** and honest UNSAFE reasons.
- Exit codes for `check`/`doctor`/`all`: `0` SAFE, `1` leak/network/Tor, `2` hardening/storage only.
- AppArmor apply marker `/var/lib/anonbox/apparmor-applied.at`; `check` FAILs only on DENIED after marker (stale boot denials → WARN).
- `doctor` read-only diagnostics (no kill-switch); `check --no-kill-switch` for frequent audits (release gate still requires full check).
- Preflight on `setup`/`all`: bridges validation, SSH lockout prompt, swap/LUKS warnings; `--yes`/`-y` skips prompts.
- Destructive confirmations for `uninstall`/`rollback` (type `uninstall`/`yes`, or `--yes`).
- Output flags: `--quiet`/`-q`, `--json` (check/doctor/status), `--no-color` / `NO_COLOR`, session log under `/var/log/anonbox/` (`--log-file` / `--no-log`).
- Per-command help (`anonbox check --help`); bash completion in `completions/anonbox.bash`.
- Stream isolation test retries; clearer transient WARN when SOCKS already passed.

### Fixed

- `check` FAILs on IFACE_IP drift (live primary IPv4 ≠ TransPort NIC bind in torrc/`ss`) and when primary IPv4 is missing during transparent-path checks; `setup`/`harden`/`status` warn to re-run setup after IP change.
- `check` asserts `/etc/tor/anonbox-defaults-torrc` exists and `tor@default` ExecStart uses `--defaults-torrc` pointing at it.
- `uninstall` removes anonbox Tor defaults + `tor@default` drop-in (and empty drop-in dir) with `daemon-reload`; help text matches first/oldest snapshot restore (`backups[0]`).
- Re-setup without `--bridges-file`/`--no-bridges` preserves existing `Bridge` lines from current torrc.
- Strong WARN when SSH env is present but `--allow-ssh` is not set during setup (lockout on reboot).
- Dynamic `User ${TOR_USER}` in anonbox-defaults; removed unused `ssh_output_extra`; clarified SocksPort comments for anonbox-defaults approach.
- Transparent proxy uses nftables `redirect to :9040` / `:5353` with Tor `TransPort`/`DNSPort` on both `127.0.0.1` and the NIC primary IPv4 (never `0.0.0.0`). OUTPUT DNAT to `127.0.0.1` delivered zero packets to Tor on tested kernels.
- OUTPUT uses `fib daddr type local accept` for post-redirect delivery (required on Debian 13; accept-by-`$IFACE_IP`:9040/5353 alone dropped redirected packets). INPUT explicitly drops new connections to those ports (NIC-bind residual mitigation).
- Removed dual `TransPort`/`DNSPort` binds of `127.0.0.1` plus `0.0.0.0`. The overlap made Tor fail to bind; `tor --verify-config` never caught it because it does not open sockets.
- Neutralized Debian `tor-service-defaults-torrc` via `/etc/tor/anonbox-defaults-torrc` + `tor@default` drop-in (no all-interfaces SocksPort / WorldWritable unix). Note: Tor rejects `SocksPort 0` combined with nonzero SocksPort.
- Applied `/etc/apparmor.d/local/system_tor` (`owner /var/lib/tor/** rwk` including directory chmod) in **setup before Tor starts**, with `apparmor_parser -r` fail-hard.
- Setup now aborts unless Tor is active, listeners are safe, nft `tor_*` tables are loaded, and bootstrap reaches 100% (`start_tor_or_die`).
- `anonbox check` treats UDP/53 to external resolvers as intercepted-by-Tor (expected success), probes non-53 UDP for leaks, and no longer treats `nc -uz` as proof of UDP egress. Stream isolation no longer false-passes on failed curls.
- Setup EXIT trap no longer returns 1 after success when temp paths were already removed.

### Changed

- Version **1.2.0** candidate. Status: hardening toolkit (not Tails/Whonix).
- Docs: LUKS/eCryptfs required for SAFE (`check` FAIL), not a setup hard die; acceptance matrix tied to SAFE = FAIL_COUNT==0 + Tor + encrypted.
- `torrc` is `chmod 640` `root:debian-tor`. Snowflake only if `snowflake-client` exists. Optional `torbrowser-launcher` when packaged.
- nftables unit override: `After=systemd-modules-load.service sysinit.target` plus `Before=network-pre.target`.
- MAC: NetworkManager `cloned-mac-address=random` only (macchanger oneshot removed). Documented as non-anti-FP under NAT.
- Shell history: `unset HISTFILE` (not Tails amnesia). `hidepid` documented as ineffective vs sudo operators.
- `LAN_SUBNET` display uses Python `ipaddress` when available.
- Touched-files manifest at `/var/lib/anonbox/touched-files.manifest`.
- Inbound RFC1918 SSH/ICMP closed by default; `--allow-ssh` for lab. `userns_clone` left enabled for Tor Browser sandbox.
- CI: pinned Actions SHAs; smoke job (`scripts/ci-smoke.sh`); `scripts/acceptance-matrix.sh` for release gate.

### Security

- Transparent proxy does not replace Tor Browser; setup prints that warning.
- Documented residuals: bootstrap clearnet apt/git, NIC TransPort binds, NAT MAC, IFACE_IP drift until re-setup.

## [1.0.0] - 2026-08-23

> **Note:** Some 1.0.0 changelog claims are superseded by later work (keep for history). In particular: TransPort/`DNSPort` on `0.0.0.0` was reverted (bind conflict); `kernel.unprivileged_userns_clone=0` was undone for Tor Browser sandbox; AppArmor PT binary whitelist in `local/system_tor` was replaced (conflicts with Debian `x` modifiers); blanket RFC1918 SSH/ICMP accept is no longer default.

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

- Removed `pam_wheel.so` restriction on `/etc/pam.d/su` to ensure standard Debian users without `sudo` privileges can elevate using `su -`.
- Fixed AppArmor Tor containment crash by deploying `/etc/apparmor.d/local/system_tor` whitelist for pluggable transport binaries (`obfs4proxy`, `lyrebird`, `snowflake-client`) and operational logfiles.
- Fixed Debian 13 (Trixie) package detection by adding `bind9-dnsutils` resolution, preventing false-positive APT updates under active fail-closed firewall.
- Fixed Transparent TCP Proxying by configuring `TransPort` and `DNSPort` on `0.0.0.0` in addition to `127.0.0.1`, allowing redirected packets with outgoing interface IPs to be accepted and proxied through Tor.
- Consolidated all package installations upfront in `cmd_setup` step 1 and added `dpkg -s` checks in `cmd_harden` steps 7 and 8 to prevent APT connection timeouts during hardening.
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
