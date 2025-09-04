#!/usr/bin/env zsh
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
IN="$ROOT/books/kaizenedge-guide/inbox/all-in-one.md"
OUTDIR="$ROOT/books/kaizenedge-guide/manuscript"
[[ -f "$IN" ]] || { echo "❌ Missing $IN"; exit 1; }
mkdir -p "$OUTDIR"
current=""
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
while IFS= read -r line; do
  if [[ "$line" == '=== FILE:'*'===' ]]; then
    if [[ -n "$current" ]]; then
      dest="$OUTDIR/$current"
      mkdir -p "$(dirname "$dest")"
      sed -e '1{/^$/d}' "$tmp" > "$dest"
      echo "✅ Wrote $dest"
      : > "$tmp"
    fi
    fname="${line#=== FILE: }"; fname="${fname% ===}"
    [[ "$fname" == *.md ]] || { echo "❌ Bad marker filename: $fname"; exit 1; }
    current="$fname"
  else
    print -r -- "$line" >> "$tmp"
  fi
done < "$IN"
if [[ -n "$current" ]]; then
  dest="$OUTDIR/$current"
  sed -e '1{/^$/d}' "$tmp" > "$dest"
  echo "✅ Wrote $dest"
fi
echo "🎯 Split complete. Commit & push to trigger CI."
