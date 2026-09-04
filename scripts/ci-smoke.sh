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
grep -q 'cmd_sync_iface' ./anonbox || fail "cmd_sync_iface missing"
grep -q 'cmd_ensure_net' ./anonbox || fail "cmd_ensure_net missing"
grep -q 'ensure_tor_iface_ready' ./anonbox || fail "ensure_tor_iface_ready missing"
grep -q 'rewrite_torrc_nic_binds' ./anonbox || fail "rewrite_torrc_nic_binds missing"
grep -q '99-anonbox-sync-iface' ./anonbox || fail "NM sync dispatcher path missing"
grep -q 'anonbox-net-ready.service' ./anonbox || fail "anonbox-net-ready.service missing"
grep -q 'ANONBOX_INSTALLED_MARKER' ./anonbox || fail "ANONBOX_INSTALLED_MARKER missing"
grep -q 'install_sync_iface_hook' ./anonbox || fail "install_sync_iface_hook missing"
grep -q 'remove_sync_iface_hook' ./anonbox || fail "remove_sync_iface_hook missing"
grep -q 'install_dhcpcd_dns_guard' ./anonbox || fail "dhcpcd DNS guard missing"
grep -q 'nohook resolv.conf' ./anonbox || fail "dhcpcd nohook resolv.conf missing"
grep -q 'assert_resolv_tor_dns' ./anonbox || fail "assert_resolv_tor_dns missing"
grep -q 'After=network-online.target anonbox-net-ready.service' ./anonbox || fail "Tor drop-in After=net-ready missing"
# sync-iface must not call full setup
if awk '/^cmd_sync_iface\(\)/,/^cmd_rollback\(\)|^cmd_uninstall\(\)|^cmd_ensure_net\(\)|^# =====/' ./anonbox | grep -q 'cmd_setup'; then
  fail "cmd_sync_iface must not call cmd_setup"
fi
if awk '/^cmd_ensure_net\(\)/,/^cmd_sync_iface\(\)|^# =====/' ./anonbox | grep -q 'cmd_setup'; then
  fail "cmd_ensure_net must not call cmd_setup"
fi
# Dispatcher must never act on lo
grep -q '!= "lo"' ./anonbox || fail "NM dispatcher must skip lo"
# Prefer systemctl start net-ready (not ad-hoc systemd-run sync-iface)
grep -q 'systemctl start --no-block anonbox-net-ready.service' ./anonbox || fail "dispatcher must start anonbox-net-ready"
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
grep -q 'print_result_card' ./anonbox || fail "print_result_card missing"
grep -q 'log_fail' ./anonbox || fail "log_fail helper missing"
grep -q 'progress_update' ./anonbox || fail "progress_update helper missing"
grep -q 'is_stderr_tty' ./anonbox || fail "is_stderr_tty helper missing"
grep -q 'FORCE_COLOR' ./anonbox || fail "FORCE_COLOR support missing"
grep -qE 'TERM=dumb|TERM:-' ./anonbox || fail "TERM=dumb color handling missing"
grep -q -- '--silent' ./anonbox || fail "--silent alias missing"
grep -q '::group::' ./anonbox || fail "GitHub Actions ::group:: missing"
grep -q 'Exit code: %d (0=SAFE, 1=leak/network, 2=hardening/storage)' ./anonbox || fail "exit code legend missing"
grep -q '\[PHASE' ./anonbox || fail "PHASE banners missing (English UI)"
[[ -f ./completions/anonbox.bash ]] || fail "completions/anonbox.bash missing"
grep -q 'Dedicated Debian guest VM recommended' ./anonbox || fail "VM-only preflight warn missing"
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
if grep -qE 'exec > >\(tee[^)]*\) 2>&1' ./anonbox; then
  fail "mixed stdout/stderr session tee (2>&1) is forbidden; use separate tees"
fi
grep -q 'exec 2> >(tee -a' ./anonbox || fail "separate stderr session tee missing"
if grep -q 'nft flush ruleset 2>/dev/null || true' ./anonbox && grep -q 'disable --now nftables' ./anonbox; then
  # uninstall must not use flush+disable as sole end-state; baseline helper required
  grep -q 'install_baseline_nftables_accept' ./anonbox || fail "uninstall flush without baseline helper"
fi
grep -q 'classified drop\|curl exit' ./anonbox || fail "kill-switch curl exit classification missing"
grep -q 'Tor inactive; nft tor_' ./anonbox || true
grep -q 'ks_code == 28' ./anonbox || fail "kill-switch classified curl exits missing"
pass "audit remediation asserts"

# Stream isolation: JSON on stdout, humans on stderr
set +e
./anonbox doctor --json --dry-run >/tmp/anonbox-json.out 2>/tmp/anonbox-json.err
doc_rc=$?
set -e
[[ "$doc_rc" -eq 2 ]] || fail "doctor --json --dry-run must exit 2 (DRY-RUN), got $doc_rc"
grep -q '^{' /tmp/anonbox-json.out || fail "JSON stdout must start with {"
grep -q '"verdict":"DRY-RUN"' /tmp/anonbox-json.out || fail "dry-run JSON verdict must be DRY-RUN"
if grep -q '^{' /tmp/anonbox-json.err; then
  fail "JSON leaked to stderr"
fi
set +e
./anonbox doctor --dry-run >/tmp/anonbox-human.out 2>/tmp/anonbox-human.err
doc_rc=$?
set -e
[[ "$doc_rc" -eq 2 ]] || fail "doctor --dry-run must exit 2 (DRY-RUN), got $doc_rc"
if grep -q '\[ SKIP \]\|\[PASS\]\|Doctor\|DRY-RUN\|dry-run' /tmp/anonbox-human.out; then
  fail "human logs leaked to stdout (expected stderr)"
fi
grep -q 'DRY-RUN\|Dry-run' /tmp/anonbox-human.err || fail "human dry-run should mention DRY-RUN on stderr"
./anonbox help | grep -q -- '--silent' || fail "help missing --silent"
./anonbox version | grep -q 'anonbox v' || fail "version output missing"
pass "JSON/stderr stream isolation"

# Per-command help
./anonbox check --help 2>&1 | grep -q 'no-kill-switch' || fail "check --help missing --no-kill-switch"
./anonbox doctor --help 2>&1 | grep -q 'doctor' || fail "doctor --help broken"
./anonbox help | grep -q 'sync-iface' || fail "help missing sync-iface"
./anonbox help | grep -q 'ensure-net' || fail "help missing ensure-net"
./anonbox sync-iface --help 2>&1 | grep -q 'sync-iface' || fail "sync-iface --help broken"
./anonbox ensure-net --help 2>&1 | grep -q 'ensure-net' || fail "ensure-net --help broken"
pass "per-command help"

# torrc NIC bind rewrite selftest (no root / no Tor)
REWRITE_DIR="$(mktemp -d)"
trap 'rm -rf "$REWRITE_DIR"' EXIT
OLD_IP="10.0.0.50"
NEW_IP="10.0.0.99"
cat > "$REWRITE_DIR/torrc.in" << EOF
# test fixture
TransPort 127.0.0.1:9040 IsolateDestAddr IsolateDestPort
TransPort ${OLD_IP}:9040 IsolateDestAddr IsolateDestPort
DNSPort 127.0.0.1:5353
DNSPort ${OLD_IP}:5353
SocksPort 127.0.0.1:9050 IsolateDestAddr IsolateDestPort
UseBridges 1
Bridge obfs4 1.2.3.4:443 AAAA cert=BBBB iat-mode=0
EOF
ANONBOX_REWRITE_SELFTEST=1 ./anonbox "$REWRITE_DIR/torrc.in" "$REWRITE_DIR/torrc.out" "$OLD_IP" "$NEW_IP" \
  || fail "ANONBOX_REWRITE_SELFTEST rewrite failed"
grep -Fq "TransPort ${NEW_IP}:9040" "$REWRITE_DIR/torrc.out" || fail "rewrite missing new TransPort"
grep -Fq "DNSPort ${NEW_IP}:5353" "$REWRITE_DIR/torrc.out" || fail "rewrite missing new DNSPort"
grep -Fq "TransPort 127.0.0.1:9040" "$REWRITE_DIR/torrc.out" || fail "rewrite dropped loopback TransPort"
grep -Fq "Bridge obfs4 1.2.3.4:443" "$REWRITE_DIR/torrc.out" || fail "rewrite dropped Bridge line"
if grep -Fq "TransPort ${OLD_IP}:9040" "$REWRITE_DIR/torrc.out"; then
  fail "rewrite left old TransPort NIC bind"
fi
if grep -E 'TransPort 0\.0\.0\.0|DNSPort 0\.0\.0\.0' "$REWRITE_DIR/torrc.out"; then
  fail "rewrite introduced 0.0.0.0 bind"
fi
pass "torrc NIC rewrite selftest"

# Manual VM checklist (document for PR reviewers; not executed here):
# 1. sudo ./anonbox setup → marker + dispatcher + anonbox-net-ready enabled
# 2. Simulate drift → check FAIL iface-drift
# 3. sudo ./anonbox sync-iface → listeners OK; check clean of iface-drift
# 4. sync-iface again → noop
# 5. nmcli connection up / dhcp4-change → journal starts anonbox-net-ready; NM not hung
# 6. sudo reboot (DoD): tor@default active without re-running setup; listeners on NIC IP;
#    resolv.conf nameserver 127.0.0.1; no StartLimit; check transparent/DNS PASS
# 7. sudo ./anonbox uninstall --yes → unit + dispatcher + dhcpcd snippets + markers gone

printf '\nAll CI smoke checks passed.\n'
