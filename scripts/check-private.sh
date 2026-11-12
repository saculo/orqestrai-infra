#!/usr/bin/env bash
# The private values stay encrypted: every *.private.yaml is a SOPS file, its private values are
# ENC[...], and it has no comments (SOPS leaves comments readable). No other file holds such a value.
set -euo pipefail
cd "$(dirname "$0")/.."
KEYS='(cidr|tailscale\.com/hostname):'
fail=0
while IFS= read -r f; do
  grep -q '^sops:' "$f" || { echo "$f: not encrypted (no sops metadata)"; fail=1; }
  if grep -nE "$KEYS" "$f" | grep -v 'ENC\['; then echo "$f: a private value in plain text"; fail=1; fi
  if grep -nE '^\s*#|\s#\s' "$f"; then echo "$f: a comment (SOPS does not encrypt comments)"; fail=1; fi
done < <(git ls-files '*.private.yaml')
if git grep -nE "$KEYS" -- ':!*.private.yaml' ':!.sops.yaml' ':!scripts/'; then
  echo "a private value outside a *.private.yaml file"; fail=1
fi
[ "$fail" = 0 ] && echo "private files: ok"
exit "$fail"
