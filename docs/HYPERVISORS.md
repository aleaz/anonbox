# Hypervisor Configuration Guide

`anonbox` is supported on a **dedicated Debian guest VM** only. Configure the hypervisor with these guidelines. **Do not** run the toolkit against your daily host OS or trusted bare metal — use the guest console (or lab SSH; see below).

To maximize security, privacy, and performance when running `anonbox`:

---

## 1. UTM / QEMU (macOS Apple Silicon & Intel)

* **Architecture:** ARM64 (Apple Silicon) or x86_64 (Intel).
* **Network Mode:** Set network mode to **Shared Network (NAT)**.
  * *Rationale:* Isolates the VM from local broadcast domains and prevents LAN devices from directly reaching the VM.
  * *Lab SSH:* If you use `anonbox … --allow-ssh`, keep NAT (or host-only) and prefer port-forward from the host — avoid open bridged Wi‑Fi where any LAN peer can reach TCP/22.
* **Entropy Device (`virtio-rng`):**
  * Under VM Settings -> Devices -> Ensure **VirtIO RNG** is enabled.
  * *Rationale:* Prevents entropy starvation inside the VM when Tor generates cryptographic circuit keys.
* **Clipboard & File Sharing:**
  * Clipboard Sharing: **Disabled** or **Host to Guest Only**.
  * Directory Sharing (VirtFS/WebDAV): **Disabled**.
  * *Rationale:* Prevents compromised processes inside the VM from exfiltrating clipboard contents or host directory metadata.

---

## 2. Oracle VirtualBox (Linux / Windows / macOS Intel)

* **Network Adapter:** Set Adapter 1 to **NAT** (same SSH guidance as UTM: NAT + port-forward if using `--allow-ssh`).
* **Shared Clipboard & Drag'n'Drop:** Set to **Disabled**.
* **Shared Folders:** None configured.
* **Paravirtualization Interface:** Default / KVM.

---

## 3. KVM / QEMU / virt-manager (Linux Host)

* **Virtual Network Interface:** Default NAT (`virbr0` or isolated bridge). Prefer this over bridged LAN when using `--allow-ssh`.
* **RNG Device:** Add RNG device `/dev/urandom` -> `virtio`.
* **Video Driver:** `virtio` or `QXL`.
* **Security Model:** Use `virt-manager` default AppArmor / SELinux svirt isolation for QEMU processes on the host.

---

## 4. Snapshots & Disposable Mode

For pseudo-amnesic operation (similar to Tails-style “forget the session”):

1. Complete setup and hardening: `sudo ./anonbox all`.
2. Power off the VM cleanly.
3. Take a baseline snapshot in your hypervisor named **`CLEAN_ANON_BASELINE`**.
4. After completing sensitive operations, discard changes and revert to **`CLEAN_ANON_BASELINE`** with one click.

**Encryption vs throwaway:** Disk encryption is **user-provided** at Debian install (anonbox does not set up LUKS). If you **keep data** on the guest, enable LUKS/eCryptfs. If the VM is **throwaway** (you discard the disk or always revert this snapshot), encryption is optional — but cleartext images on the host remain readable until deleted. `anonbox check` still requires encryption to report **SAFE**.
