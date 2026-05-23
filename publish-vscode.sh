#!/usr/bin/env bash
#
# Publish all Codigrate themes to the VS Code Marketplace (marketplace.visualstudio.com).
#
# Usage:
#   1. Put vscode.token (your Azure DevOps Personal Access Token) next to this script.
#      The token needs the "Marketplace > Manage" scope and must be created with
#      Organization = "All accessible organizations".
#   2. The publisher "codigrate" must already exist at
#      https://marketplace.visualstudio.com/manage
#   3. From the repo root, run:  bash publish-vscode.sh
#
# Requirements: Node.js / npm (the script fetches the `vsce` CLI via npx).
# It publishes the prebuilt packages in dist/vscode/ (built with the Marketplace README.md).
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

shopt -s nullglob
packages=(dist/vscode/*.vsix)
if [[ ${#packages[@]} -eq 0 ]]; then
  echo "ERROR: no .vsix files found in dist/vscode/" >&2
  exit 1
fi

ok=0; fail=0; failed=()
for vsix in "${packages[@]}"; do
  echo "==> Publishing $vsix"
  if npx --yes @vscode/vsce publish --packagePath "$vsix"; then
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
echo "e.g. https://marketplace.visualstudio.com/items?itemName=codigrate.cod-rio-de-janeiro-theme"
