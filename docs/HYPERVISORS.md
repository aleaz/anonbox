# Hypervisor Configuration Guide

To maximize security, privacy, and performance when running `anonbox`, configure your hypervisor according to these engineering guidelines:

---

## 1. UTM / QEMU (macOS Apple Silicon & Intel)

* **Architecture:** ARM64 (Apple Silicon) or x86_64 (Intel).
* **Network Mode:** Set network mode to **Shared Network (NAT)**.
  * *Rationale:* Isolates the VM from local broadcast domains and prevents LAN devices from directly reaching the VM.
* **Entropy Device (`virtio-rng`):**
  * Under VM Settings -> Devices -> Ensure **VirtIO RNG** is enabled.
  * *Rationale:* Prevents entropy starvation inside the VM when Tor generates cryptographic circuit keys.
* **Clipboard & File Sharing:**
  * Clipboard Sharing: **Disabled** or **Host to Guest Only**.
  * Directory Sharing (VirtFS/WebDAV): **Disabled**.
  * *Rationale:* Prevents compromised processes inside the VM from exfiltrating clipboard contents or host directory metadata.

---

## 2. Oracle VirtualBox (Linux / Windows / macOS Intel)

* **Network Adapter:** Set Adapter 1 to **NAT**.
* **Shared Clipboard & Drag'n'Drop:** Set to **Disabled**.
* **Shared Folders:** None configured.
* **Paravirtualization Interface:** Default / KVM.

---

## 3. KVM / QEMU / virt-manager (Linux Host)

* **Virtual Network Interface:** Default NAT (`virbr0` or isolated bridge).
* **RNG Device:** Add RNG device `/dev/urandom` -> `virtio`.
* **Video Driver:** `virtio` or `QXL`.
* **Security Model:** Use `virt-manager` default AppArmor / SELinux svirt isolation for QEMU processes on the host.

---

## 4. Snapshots & Disposable Mode

For pseudo-amnesic operation (similar to Tails):

1. Complete setup and hardening: `sudo ./anonbox all`.
2. Power off the VM cleanly.
3. Take a baseline snapshot in your hypervisor named **`CLEAN_ANON_BASELINE`**.
4. After completing sensitive operations, discard changes and revert to **`CLEAN_ANON_BASELINE`** with one click.
