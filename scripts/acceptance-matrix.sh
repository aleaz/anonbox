#!/usr/bin/env bash
# Release acceptance helper — maps docs/THREAT_MODEL.md checks 01–25.
# On a live anonbox host, prefer: sudo ./anonbox check
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  cat << 'EOF'
usage: scripts/acceptance-matrix.sh [--help] [--list] [--run]

  --list   Print the threat-model verification matrix (from docs).
  --run    Execute sudo ./anonbox check (requires root on a configured host).
  --help   This message.

Release gate: all in-scope checks must PASS; LUKS FAIL blocks SAFE by design.
EOF
}

list_matrix() {
  if [[ -f "$ROOT/docs/THREAT_MODEL.md" ]]; then
    awk '/^## 3\. Acceptance Verification Matrix/{p=1} p && /^\| \*\*/{print} p && /^---$/{if(seen++) exit}' \
      "$ROOT/docs/THREAT_MODEL.md" || sed -n '/Acceptance Verification Matrix/,/^## /p' "$ROOT/docs/THREAT_MODEL.md" | head -n 40
  else
    echo "docs/THREAT_MODEL.md not found"
    exit 1
  fi
}

case "${1:---help}" in
  --help|-h) usage ;;
  --list)
    list_matrix
    ;;
  --run)
    if [[ "$(id -u)" -ne 0 ]]; then
      echo "acceptance --run requires root (sudo)" >&2
      exit 1
    fi
    exec "$ROOT/anonbox" check
    ;;
  *)
    usage
    exit 1
    ;;
esac
