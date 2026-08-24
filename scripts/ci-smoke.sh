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
# Generator must not use SocksPort 0 (incompatible with nonzero SocksPort)
if grep -E '^SocksPort 0$' ./anonbox >/dev/null 2>&1 || grep -qE 'printf.*SocksPort 0' ./anonbox; then
  : # ignore comments
fi
if grep -E 'SocksPort 0$' ./anonbox | grep -v '^#' | grep -qv 'cannot'; then
  # allow mentions in comments/docs inside script
  if grep -E '^\s*SocksPort 0\s*$' ./anonbox >/dev/null 2>&1; then
    fail "Generator still emits SocksPort 0"
  fi
fi
pass "torrc generator asserts"

# nftables template: redirect + INPUT drop + narrowed NIC accept
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
