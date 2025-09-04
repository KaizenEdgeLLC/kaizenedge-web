#!/usr/bin/env bash
set -euo pipefail
BOOK_DIR="books/kaizenedge-guide"
MANU="$BOOK_DIR/manuscript"
BUILD="$BOOK_DIR/build"
mkdir -p "$BUILD"
mapfile -t files < <(ls -1 "$MANU"/*.md 2>/dev/null | sort || true)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No chapters found in $MANU" >&2; exit 1
fi
pandoc "${files[@]}" -o "$BUILD/KaizenEdge_Guide.pdf"  --toc --standalone -V geometry:margin=1in -V mainfont="Helvetica" -V monofont="Menlo"
pandoc "${files[@]}" -o "$BUILD/KaizenEdge_Guide.epub" --toc --standalone --metadata title="KaizenEdge: AI Business in a Box" --metadata author="KaizenEdge"
pandoc "${files[@]}" -o "$BUILD/KaizenEdge_Guide.html" --toc --standalone
echo "Built:"
ls -1 "$BUILD"/KaizenEdge_Guide.*
