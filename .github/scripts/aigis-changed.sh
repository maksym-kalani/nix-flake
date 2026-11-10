#!/usr/bin/env bash
set -euo pipefail

expression="$(dirname "${BASH_SOURCE[0]}")/aigis-fingerprint.nix"
base=$(AIGIS_FLAKE_REF="$1" nix eval --json --no-update-lock-file --file "$expression")
candidate=$(AIGIS_FLAKE_REF="$2" nix eval --json --no-update-lock-file --file "$expression")
if [[ -z "$base" || -z "$candidate" ]]; then
  echo "::error::Missing Aigis fingerprint" >&2
  exit 1
fi
printf 'base: %s\ncandidate: %s\n' "$base" "$candidate" >&2
if [[ "$base" == "$candidate" ]]; then
  echo false
else
  echo true
fi
