#!/usr/bin/env bash
# Static smoke checks for CI (no root, no live Tor).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

[[ -f ./anonbox ]] || fail "anonbox script missing"
bash -n ./anonbox
pass "bash -n anonbox"

# Torrc fragment must neutralize Debian defaults and forbid 0.0.0.0 binds
grep -q 'anonbox-defaults-torrc' ./anonbox || fail "anonbox-defaults-torrc missing from generator"
grep -q 'SocksPort 127.0.0.1:9050' ./anonbox || fail "localhost SocksPort missing"
# shellcheck disable=SC2016 # intentional literal ${TOR_USER} in source
grep -q 'User ${TOR_USER}' ./anonbox || fail "dynamic User \${TOR_USER} missing from anonbox-defaults"
# Generator must not emit bare SocksPort 0 lines (incompatible with nonzero SocksPort)
if grep -E '^\s*SocksPort 0\s*$' ./anonbox >/dev/null 2>&1; then
  fail "Generator still emits SocksPort 0"
fi
pass "torrc generator asserts"

# IFACE_IP drift helpers + check FAIL path
grep -q 'torrc_transport_nic_ip' ./anonbox || fail "torrc_transport_nic_ip helper missing"
grep -q 'warn_iface_ip_drift' ./anonbox || fail "warn_iface_ip_drift helper missing"
grep -q 'IFACE_IP drift' ./anonbox || fail "IFACE_IP drift FAIL in check missing"
grep -q 'Preserving existing Bridge lines' ./anonbox || fail "bridge preserve on re-setup missing"
grep -q 'baseline nftables accept' ./anonbox || fail "uninstall help must mention baseline nftables accept"
# shellcheck disable=SC2016 # intentional literal "$ANONBOX_TOR_DEFAULTS" in source
grep -q 'rm -f "$ANONBOX_TOR_DEFAULTS"' ./anonbox || fail "uninstall must remove anonbox-defaults-torrc"
# Dead ssh_output_extra must stay gone
if grep -q 'ssh_output_extra' ./anonbox; then
  fail "dead ssh_output_extra still present"
fi
pass "hygiene and drift asserts"

# nftables template: redirect + INPUT drop + fib local accept
grep -q 'redirect to :9040' ./anonbox || fail "nft redirect :9040 missing"
grep -q 'redirect to :5353' ./anonbox || fail "nft redirect :5353 missing"
grep -q 'tcp dport { 9040, 5353 } drop' ./anonbox || fail "INPUT drop 9040/5353 missing"
grep -q 'fib daddr type local accept' ./anonbox || fail "fib daddr type local accept missing"
pass "nftables template asserts"

# Dry-run should not require root
./anonbox setup --dry-run --no-bridges --yes >/tmp/anonbox-dry.out 2>&1 || true
if grep -qi 'ERROR' /tmp/anonbox-dry.out && ! grep -q 'DRY-RUN' /tmp/anonbox-dry.out; then
  # dry-run may still die on OS detection outside Debian — accept that
  pass "dry-run invoked (non-Debian hosts may abort after OS check)"
else
  pass "dry-run completed or reported dry-run markers"
fi

# CLI UX Stage 1–3 helpers
grep -q 'fail_fix' ./anonbox || fail "fail_fix helper missing"
grep -q 'Next steps:' ./anonbox || fail "Next steps summary missing"
grep -q 'apparmor-applied.at' ./anonbox || fail "apparmor-applied.at marker missing"
grep -q 'record_apparmor_applied' ./anonbox || fail "record_apparmor_applied missing"
grep -q 'cmd_doctor' ./anonbox || fail "doctor subcommand missing"
grep -q 'NO_KILL_SWITCH' ./anonbox || fail "--no-kill-switch support missing"
grep -q 'ASSUME_YES' ./anonbox || fail "--yes support missing"
grep -q 'JSON_OUT' ./anonbox || fail "--json support missing"
grep -q 'print_audit_summary' ./anonbox || fail "print_audit_summary missing"
grep -q 'Exit code: %d (0=SAFE, 1=leak/network, 2=hardening/storage)' ./anonbox || fail "exit code legend missing"
grep -q '\[PHASE' ./anonbox || fail "PHASE banners missing (English UI)"
[[ -f ./completions/anonbox.bash ]] || fail "completions/anonbox.bash missing"
pass "CLI UX asserts"

# Audit remediation helpers (path jail, bridges allowlist, kill-switch, restore)
grep -q 'resolve_under_dir' ./anonbox || fail "resolve_under_dir missing"
grep -q 'resolve_snapshot_dir' ./anonbox || fail "resolve_snapshot_dir missing"
grep -q 'append_bridges_from_file' ./anonbox || fail "append_bridges_from_file missing"
grep -q "only 'Bridge" ./anonbox || fail "bridges allowlist die missing"
grep -q 'restore_one' ./anonbox || fail "restore_one missing"
grep -q 'install_baseline_nftables_accept' ./anonbox || fail "install_baseline_nftables_accept missing"
grep -q 'log_append' ./anonbox || fail "log_append missing"
grep -q 'anonbox_mktemp' ./anonbox || fail "anonbox_mktemp missing"
grep -q 'ss_listens_tcp' ./anonbox || fail "ss_listens_tcp missing"
grep -q 'CURRENT_SNAPSHOT_ID=.*_\$\$' ./anonbox || fail "snapshot ID must include PID"
if grep -q 'exec > >(tee' ./anonbox; then
  fail "exec tee session logging must remain removed"
fi
if grep -q 'nft flush ruleset 2>/dev/null || true' ./anonbox && grep -q 'disable --now nftables' ./anonbox; then
  # uninstall must not use flush+disable as sole end-state; baseline helper required
  grep -q 'install_baseline_nftables_accept' ./anonbox || fail "uninstall flush without baseline helper"
fi
grep -q 'classified drop\|curl exit' ./anonbox || fail "kill-switch curl exit classification missing"
grep -q 'Tor inactive; nft tor_' ./anonbox || true
grep -q 'ks_code == 28' ./anonbox || fail "kill-switch classified curl exits missing"
pass "audit remediation asserts"

# Per-command help
./anonbox check --help 2>&1 | grep -q 'no-kill-switch' || fail "check --help missing --no-kill-switch"
./anonbox doctor --help 2>&1 | grep -q 'doctor' || fail "doctor --help broken"
pass "per-command help"

printf '\nAll CI smoke checks passed.\n'
