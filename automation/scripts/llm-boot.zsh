#!/usr/bin/env zsh
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
FILE="$ROOT/docs/llm-boot-context.txt"
if [[ ! -f "$FILE" ]]; then
  echo "❌ Missing $FILE"; exit 1
fi
if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$FILE"
  echo "✅ Boot context copied to clipboard."
else
  # Linux fallback: print path and content
  echo "ℹ️ pbcopy not found. Here is the path and content:"
  echo "$FILE"
  echo "---------------------------------------------"
  cat "$FILE"
fi
echo "Paste into Llama & Deep as the first/system message."
