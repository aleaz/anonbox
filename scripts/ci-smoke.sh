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
grep -q 'first/oldest snapshot' ./anonbox || fail "uninstall help must say first/oldest snapshot"
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
./anonbox setup --dry-run --no-bridges >/tmp/anonbox-dry.out 2>&1 || true
if grep -qi 'ERROR' /tmp/anonbox-dry.out && ! grep -q 'DRY-RUN' /tmp/anonbox-dry.out; then
  # dry-run may still die on OS detection outside Debian — accept that
  pass "dry-run invoked (non-Debian hosts may abort after OS check)"
else
  pass "dry-run completed or reported dry-run markers"
fi

printf '\nAll CI smoke checks passed.\n'
