# Threat Model & Security Boundaries

## 1. System Comparison: Tails OS vs Whonix vs anonbox

| Security Vector | Tails OS (Live USB) | Whonix (2 VMs: Gateway + WS) | anonbox (This Project) | Design Status |
| :--- | :--- | :--- | :--- | :--- |
| **Storage Encryption** | LUKS (Persistent Volume) | Optional inside VM | **LUKS2 (Mandatory Pre-requisite)** | **IN-SCOPE (Mandatory)** |
| **Tor Routing** | iptables/nftables | Hypervisor-isolated Gateway | **Local Fail-Closed nftables** | **IN-SCOPE (Mandatory)** |
| **Kill-Switch on Crash** | Yes | Yes | **Yes (nftables drop policy)** | **IN-SCOPE (Mandatory)** |
| **DNS / UDP Leak Drop** | Yes | Yes | **Yes (Kernel drop + local DNSPort)** | **IN-SCOPE (Mandatory)** |
| **Boot Race Mitigation** | Yes | Yes | **Yes (Before=network-pre.target)** | **IN-SCOPE (Mandatory)** |
| **Network Anti-Fingerprint** | Yes (UTC, MAC, Hostname) | Yes | **Yes (macchanger, htpdate, UTC, NM MAC)** | **IN-SCOPE (Mandatory)** |
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
3. **Local Process Snooping:** Unprivileged users cannot snoop on `/proc` PIDs (`hidepid=2`), inject memory via `ptrace` (`ptrace_scope=2`), or read other users' files (`umask 027`, `/home/` 700).
4. **Time & Location Fingerprinting:** System clock is set to UTC and synchronized anonymously over Tor using `htpdate`, eliminating standard unencrypted NTP UDP leaks.
5. **Machine-ID & Telemetry Correlation:** Standardized `/etc/machine-id`, purged `popularity-contest`, and disabled NetworkManager connectivity checks eliminate OS-level tracking tokens.
6. **Disk Forensics when Powered Off:** LUKS2 AES-XTS 512-bit disk encryption ensures disk image files (`.qcow2`, `.vdi`) are unreadable without the passphrase.

### Out-of-Scope (Known Limitations)

1. **Malicious Host OS:** If the physical host OS has keyloggers, hypervisor exploits, or malware, it can inspect VM memory.
2. **Browser Fingerprinting without Tor Browser:** Standard browsers (Chrome, standard Firefox) will leak canvas, WebGL, and font fingerprints. Interactive browsing **must** be conducted in **Tor Browser** or **LibreWolf with RFP enabled**.
3. **Physical Cold-Boot Attacks:** Extracting RAM chips from physical hardware immediately after shutdown is not mitigated by a virtual machine; this requires host-level memory wiping or Live USB OS like Tails.

---

## 3. Acceptance Verification Matrix

Every release of `anonbox` must satisfy 100% of the following verification checks:

| # | Verification Check | Command | Expected Result |
| :--- | :--- | :--- | :--- |
| **01** | TransPort TCP Routing | `curl -s https://check.torproject.org` | Returns Tor confirmation |
| **02** | DNS Leak Prevention | `dig +short @127.0.0.1 -p 5353 whoami.akamai.net` | Resolves to Tor exit IP |
| **03** | DNS UDP Fallback Drop | `dig @1.1.1.1 google.com` | **Timeout / Drop** (No clearnet leak) |
| **04** | UDP Leak Prevention | `nc -u -z -w 2 8.8.8.8 53` | **Dropped by nftables** |
| **05** | ICMP Leak Prevention | `ping -c 2 -W 2 1.1.1.1` | **100% packet loss** |
| **06** | IPv6 Leak Prevention | `curl -6 https://icanhazip.com` | **Immediate network failure** |
| **07** | Kill-Switch on Crash | Stop `tor` (`systemctl stop tor`) & run `curl` | **Connection refused / 0 bytes leaked** |
| **08** | Stream Isolation | `curl` to 2 distinct endpoints simultaneously | **Different exit IPs returned** |
| **09** | Timezone Check | `date +%Z` | Returns `UTC` |
| **10** | LUKS Encryption Check | `lsblk -f` | Root mounted on `crypto_LUKS` |
| **11** | Swap Security Check | `swapon --show` | Swap on LUKS, `zram`, or disabled |
| **12** | ControlPort Auth Check | `nc -z 127.0.0.1 9053` | Requires authentication cookie |
| **13** | User & Home Isolation | `stat -c %a /home/*` & `umask` | `700` permissions on home and umask `027` |
| **14** | Core Dump Disabled | `sysctl fs.suid_dumpable` | Returns `0` |
| **15** | Kernel Yama & TTY | `sysctl kernel.yama.ptrace_scope` | `ptrace_scope >= 2` |
| **16** | Mounts Security Check | `findmnt /tmp /var/tmp /dev/shm` | Mounted with `noexec,nosuid,nodev` |
| **17** | AppArmor Status Check | `aa-status` | Active and enforcing profiles |
| **18** | TCP Timestamp Check | `sysctl net.ipv4.tcp_timestamps` | Returns `0` |
| **19** | User Namespaces Check | `sysctl kernel.unprivileged_userns_clone` | Returns `0` |
| **20** | Machine-ID Pool Check | `cat /etc/machine-id` | Standardized anonymity UUID |
| **21** | NM Connectivity Check | `cat /etc/NetworkManager/conf.d/20-connectivity.conf` | `enabled=false` |
| **22** | Boot Ordering Check | `systemctl show -p Before nftables` | Contains `network-pre.target` |
