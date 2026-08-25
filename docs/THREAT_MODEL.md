# Threat Model & Security Boundaries

## 1. System Comparison: Tails OS vs Whonix vs anonbox

| Security Vector | Tails OS (Live USB) | Whonix (2 VMs: Gateway + WS) | anonbox (This Project) | Design Status |
| :--- | :--- | :--- | :--- | :--- |
| **Storage Encryption** | LUKS (Persistent Volume) | Optional inside VM | **LUKS2 / eCryptfs (required for SAFE)** | **IN-SCOPE (check FAIL blocks SAFE)** |
| **Tor Routing** | iptables/nftables | Hypervisor-isolated Gateway | **Local Fail-Closed nftables** | **IN-SCOPE (Mandatory)** |
| **Kill-Switch on Crash** | Yes | Yes | **Yes (nftables drop policy)** | **IN-SCOPE (Mandatory)** |
| **DNS / UDP Leak Drop** | Yes | Yes | **Yes (Kernel drop + local DNSPort)** | **IN-SCOPE (Mandatory)** |
| **Boot Race Mitigation** | Yes | Yes | **Yes (Before=network-pre.target)** | **IN-SCOPE (Mandatory)** |
| **Network Anti-Fingerprint** | Yes (UTC, MAC, Hostname) | Yes | **Partial** (UTC, hostname, NM cloned-mac; **not** L2 anti-FP under NAT) | **IN-SCOPE (Honest limits)** |
| **Machine-ID Camouflage** | Randomized per boot | Standardized dummy ID | **Standardized Anonymity Pool ID** | **IN-SCOPE (Mandatory)** |
| **Clock-Skew Mitigation** | Yes | Yes (sclockdiv) | **Disabled TCP Timestamps (tcp_timestamps=0)** | **IN-SCOPE (Mandatory)** |
| **Stream Isolation** | Yes (Per Application) | Yes (Per SocksPort) | **Yes (Multi-Socks + IsolateDestAddr)** | **IN-SCOPE (Mandatory)** |
| **Root Compromise Isolation** | Partial | **Total** (WS cannot see host IP) | **Limited** (Root can inspect NIC) | **KNOWN LIMITATION (1 VM)** |
| **Native Amnesia (RAM-Only)** | **Total** (OverlayFS in RAM) | Optional (Live mode) | **Via Hypervisor Snapshots** | **KNOWN LIMITATION (LUKS)** |
| **Cold-Boot RAM Wipe** | **Yes** (Wipes RAM on shutdown) | No (Handled by Host) | **No** (Handled by Host) | **OUT-OF-SCOPE (Host Trust)** |
| **Compromised Host OS** | Protected (Independent OS) | Vulnerable | **Vulnerable** (If host falls, VM falls) | **OUT-OF-SCOPE (Host Trust)** |

---

## 2. In-Scope vs Out-of-Scope Threat Boundaries

### In-Scope (Mitigated by `anonbox`)

1. **Accidental Clearnet Leaks:** All outbound TCP and DNS traffic from any application (curl, git, apt, custom scripts) is captured and sent over Tor. Non-Tor protocols (UDP, ICMP) and IPv6 are dropped.
2. **Network Observer Correlation:** The local ISP or network monitor only observes encrypted traffic to a single Tor guard node or obfs4 bridge.
3. **Local Process Snooping:** Unprivileged non-sudo users cannot snoop on `/proc` PIDs (`hidepid=2,gid=sudo`), inject via `ptrace` (`ptrace_scope=2`), or read other users' files (`umask 027`, `/home/` 700). Operators in `sudo` still see all PIDs.
4. **Time & Location Fingerprinting:** System clock is set to UTC and synchronized anonymously over Tor using `htpdate`, eliminating standard unencrypted NTP UDP leaks.
5. **Machine-ID & Telemetry Correlation:** Standardized `/etc/machine-id`, purged `popularity-contest`, and disabled NetworkManager connectivity checks eliminate OS-level tracking tokens.
6. **Disk Forensics when Powered Off:** LUKS2 or eCryptfs keeps disk image files (`.qcow2`, `.vdi`) unreadable without the passphrase. Without encryption, `check` reports FAIL and SAFE is blocked (setup does not abort).

### Out-of-Scope (Known Limitations)

1. **Malicious Host OS:** If the physical host OS has keyloggers, hypervisor exploits, or malware, it can inspect VM memory.
2. **Browser Fingerprinting without Tor Browser:** Standard browsers (Chrome, standard Firefox) will leak canvas, WebGL, and font fingerprints. Interactive browsing **must** be conducted in **Tor Browser** or **LibreWolf with RFP enabled**.
3. **Physical Cold-Boot Attacks:** Extracting RAM chips from physical hardware immediately after shutdown is not mitigated by a virtual machine; this requires host-level memory wiping or Live USB OS like Tails.

### Accepted Residuals (In-Scope, Documented)

1. **Bootstrap clearnet:** The first `git clone` / `apt-get install` (before fail-closed nftables) uses the real ISP path. Prefer installing from a preseeded image or offline packages when that matters.
2. **NIC TransPort/DNSPort binds:** Required for nft `redirect` on tested kernels. Mitigated by INPUT drop of 9040/5353; residual if nftables fails to load at boot.
3. **MAC under NAT:** NetworkManager `cloned-mac-address=random` only affects the guest NIC. Upstream NAT still shows the host MAC — not L2 anti-fingerprint.
4. **Shell history:** `HISTFILE` is unset (no persistent history). This is not Tails-style amnesia (RAM-only rootfs).

---

## 3. Acceptance Verification Matrix

Release gate: prefer `sudo ./anonbox check` (without `--no-kill-switch`). **SAFE** means `FAIL_COUNT == 0`, Tor active, and encrypted storage (LUKS/eCryptfs). Exit codes: `0` SAFE, `1` leak/network, `2` hardening/storage only. Individual matrix rows below are the in-scope verification targets; lab hosts may WARN or FAIL storage by design without blocking setup. Use `sudo ./anonbox doctor` for read-only triage (no kill-switch).

| # | Verification Check | Command | Expected Result |
| :--- | :--- | :--- | :--- |
| **01** | TransPort TCP Routing | `curl -s https://check.torproject.org` | Returns Tor confirmation |
| **02** | DNS Leak Prevention | `dig +short @127.0.0.1 -p 5353 whoami.akamai.net` | Resolves to Tor exit IP |
| **03** | DNS UDP/53 Intercept | `dig @1.1.1.1 google.com` | **Answered via Tor DNSPort** (not clearnet; eth0 silent) |
| **04** | UDP Leak Prevention | `dig @8.8.8.8 -p 5353 google.com` | **Timeout / Drop** (non-53 UDP blocked; do not use `nc -uz`) |
| **05** | ICMP Leak Prevention | `ping -c 2 -W 2 1.1.1.1` | **100% packet loss** |
| **06** | IPv6 Leak Prevention | `curl -6 https://icanhazip.com` | **Immediate network failure** |
| **07** | Kill-Switch on Crash | Stop `tor` (`systemctl stop tor`) & run `curl` | **Connection refused / 0 bytes leaked** |
| **08** | Stream Isolation | `curl` to 2 distinct endpoints simultaneously | **Different exit IPs returned** |
| **09** | Timezone Check | `date +%Z` | Returns `UTC` |
| **10** | Storage Encryption Check | `findmnt -t ecryptfs` / `lsblk -f` | Active `ecryptfs` mount or `crypto_LUKS` (**FAIL** if missing; blocks SAFE) |
| **11** | Swap Security Check | `swapon --show` | Swap on LUKS, `zram`, or disabled (**FAIL** if cleartext swap; remediations suggest `swapoff` / LUKS / zram — anonbox does not auto-disable) |
| **12** | ControlPort Auth Check | `nc -z 127.0.0.1 9053` | Listening on localhost; cookie authentication |
| **13** | User & Home Isolation | `stat -c %a /home/*` & `umask` | `700` permissions on home and umask `027` |
| **14** | Core Dump Disabled | `sysctl fs.suid_dumpable` | Returns `0` |
| **15** | Kernel Yama & TTY | `sysctl kernel.yama.ptrace_scope` | `ptrace_scope >= 2` |
| **16** | Mounts Security Check | `findmnt /tmp /var/tmp /dev/shm` | Mounted with `noexec,nosuid,nodev` |
| **17** | AppArmor Status Check | `aa-status` + `journalctl -b -k` | Active; **FAIL** only on Tor DENIED after `/var/lib/anonbox/apparmor-applied.at` (stale earlier-boot DENIED → WARN; reboot then re-check) |
| **18** | TCP Timestamp Check | `sysctl net.ipv4.tcp_timestamps` | Returns `0` |
| **19** | User Namespaces Check | `sysctl kernel.unprivileged_userns_clone` | **Not** `0` (Tor Browser sandbox) |
| **20** | Machine-ID Pool Check | `cat /etc/machine-id` | Standardized anonymity UUID |
| **21** | NM Connectivity Check | `cat /etc/NetworkManager/conf.d/20-connectivity.conf` | `enabled=false` |
| **22** | Boot Ordering Check | `systemctl show -p Before nftables` | Contains `network-pre.target` |
| **23** | Safe TransPort/DNSPort binds | `ss -lnt sport = :9040` / `ss -lnu :5353` | `127.0.0.1` + NIC IP; never `0.0.0.0`/`*`; SOCKS localhost only |
| **24** | nft redirect + INPUT deny | `nft list table ip tor_nat` / `tor_filter` | `redirect to :9040/:5353`; INPUT drops 9040/5353; OUTPUT `fib daddr type local` |
| **25** | nft boot ordering | `systemctl show -p After nftables` | Includes `systemd-modules-load` or `sysinit` |
