#!/usr/bin/env bash
#
# Publish all Codigrate themes to the VS Code Marketplace (https://marketplace.visualstudio.com).
#
# Usage:
#   1. Put your Azure DevOps PAT (Marketplace > Manage > publish scope) in vscode.token next to this script.
#   2. From the repo root, run:  bash publish-vsmarketplace.sh
#
# Publishes the pre-built .vsix from each theme's dist/vs-marketplace/ (the README.md variant).
# Requirements: Node.js / npm (fetches @vscode/vsce via npx).
#
set -uo pipefail
cd "$(dirname "$0")"

TOKEN_FILE="vscode.token"
if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "ERROR: $TOKEN_FILE not found next to this script." >&2
  exit 1
fi
export VSCE_PAT="$(tr -d '[:space:]' < "$TOKEN_FILE")"
if [[ -z "$VSCE_PAT" ]]; then
  echo "ERROR: $TOKEN_FILE is empty." >&2
  exit 1
fi

ok=0; fail=0; failed=()
for vsix in cities/*-theme/dist/vs-marketplace/*.vsix nature/*-theme/dist/vs-marketplace/*.vsix; do
  [[ -e "$vsix" ]] || continue
  # skip iCloud/Finder conflict copies ("<name> 2.vsix") so we never double-publish
  [[ "$vsix" == *" "[0-9]".vsix" ]] && { echo "Skipping duplicate copy: $vsix"; continue; }
  echo "==> Publishing $vsix"
  if npx --yes @vscode/vsce publish --packagePath "$vsix" --pat "$VSCE_PAT"; then
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
echo "  https://marketplace.visualstudio.com/items?itemName=codigrate.<extension-name>"
echo "e.g. https://marketplace.visualstudio.com/items?itemName=codigrate.cod-aurora-borealis-theme"
