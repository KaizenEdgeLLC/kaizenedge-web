#!/usr/bin/env zsh
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
BOOT="$ROOT/docs/llm-boot-context.txt"
CHECK="$ROOT/docs/llm-activation-checklist.txt"

[[ -f "$BOOT" ]]  || { echo "❌ Missing $BOOT"; exit 1; }
[[ -f "$CHECK" ]] || { echo "❌ Missing $CHECK"; exit 1; }

TMP="$(mktemp)"
{
  cat "$BOOT"
  echo ""
  echo "-----"
  echo ""
  cat "$CHECK"
} > "$TMP"

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$TMP"
  echo "✅ Boot context + Activation Checklist copied to clipboard."
  echo "Paste into Llama & Deep as the system/init message."
else
  echo "ℹ️ pbcopy not found. Showing combined content:"
  cat "$TMP"
fi
rm -f "$TMP"
