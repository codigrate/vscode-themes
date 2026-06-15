#!/usr/bin/env bash
#
# Publish all Codigrate themes to the Open VSX Registry (https://open-vsx.org).
#
# Usage:
#   1. Make sure openvsx.token (your Open VSX access token) sits next to this script.
#   2. From the repo root, run:  bash publish-openvsx.sh
#
# Requirements: Node.js / npm (the script fetches the `ovsx` CLI via npx).
#
set -uo pipefail
cd "$(dirname "$0")"

TOKEN_FILE="openvsx.token"
if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "ERROR: $TOKEN_FILE not found next to this script." >&2
  exit 1
fi
export OVSX_PAT="$(tr -d '[:space:]' < "$TOKEN_FILE")"
if [[ -z "$OVSX_PAT" ]]; then
  echo "ERROR: $TOKEN_FILE is empty." >&2
  exit 1
fi

# Ensure the 'codigrate' namespace exists (harmless if it already does).
echo "==> Ensuring 'codigrate' namespace exists..."
npx --yes ovsx create-namespace codigrate || true
echo

ok=0; fail=0; failed=()
for vsix in cities/*-theme/dist/open-vsx/*.vsix nature/*-theme/dist/open-vsx/*.vsix; do
  [[ -e "$vsix" ]] || continue
  # skip iCloud/Finder conflict copies ("<name> 2.vsix") so we never double-publish
  [[ "$vsix" == *" "[0-9]".vsix" ]] && { echo "Skipping duplicate copy: $vsix"; continue; }
  echo "==> Publishing $vsix"
  if npx --yes ovsx publish "$vsix"; then
    ok=$((ok+1))
  else
    fail=$((fail+1))
    failed+=("$vsix")
  fi
  echo
done

echo "========================================"
echo "Published OK : $ok"
echo "Failed       : $fail"
for f in "${failed[@]:-}"; do [[ -n "$f" ]] && echo "  - $f"; done
echo
echo "Once published, each theme is live at:"
echo "  https://open-vsx.org/extension/codigrate/<extension-name>"
echo "e.g. https://open-vsx.org/extension/codigrate/cod-rio-de-janeiro-theme"
