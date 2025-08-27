#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/archive_validation_artifacts.sh /path/to/Summary.pdf /path/to/Results.pdf
# Both files should already have matching .sha256 sidecars next to them (if not, this script will create them).

if [ $# -lt 2 ]; then
  echo "Usage: $0 <Validation_Summary.pdf> <Validation_Results.pdf>"
  exit 1
fi

SUMMARY_SRC="$1"
RESULTS_SRC="$2"

# Resolve absolute paths
SUMMARY_SRC="$(cd "$(dirname "$SUMMARY_SRC")" && pwd)/$(basename "$SUMMARY_SRC")"
RESULTS_SRC="$(cd "$(dirname "$RESULTS_SRC")" && pwd)/$(basename "$RESULTS_SRC")"

# Where to store in the monorepo
DEST_BASE="docs/validation/v1"
DEST_REPORTS="$DEST_BASE/reports"
DEST_SIGS="$DEST_BASE/signatures"

mkdir -p "$DEST_REPORTS" "$DEST_SIGS"

# Function to ensure sha256 sidecar exists and matches
ensure_signature () {
  local file="$1"
  local sidecar="${file}.sha256"
  if [ ! -f "$sidecar" ]; then
    echo "No sidecar for $file — creating..."
    python - <<'PY'
import sys, hashlib, pathlib
p=pathlib.Path(sys.argv[1]); s=p.with_suffix(p.suffix+".sha256")
s.write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"\n",encoding="utf-8")
print("Created", s)
PY
  "$file"
  fi

  # Verify
  python - <<'PY'
import sys, hashlib, pathlib
p=pathlib.Path(sys.argv[1]); s=p.with_suffix(p.suffix+".sha256")
h1=hashlib.sha256(p.read_bytes()).hexdigest().strip()
h2=s.read_text().strip()
print("VERIFY", p.name, "=>", "OK" if h1==h2 else "MISMATCH")
exit(0 if h1==h2 else 1)
PY
  "$file"
}

ensure_signature "$SUMMARY_SRC"
ensure_signature "$RESULTS_SRC"

# Copy reports and signatures into versioned folders
cp -f "$SUMMARY_SRC" "$DEST_REPORTS/"
cp -f "$RESULTS_SRC" "$DEST_REPORTS/"
cp -f "${SUMMARY_SRC}.sha256" "$DEST_SIGS/"
cp -f "${RESULTS_SRC}.sha256" "$DEST_SIGS/"

echo "✅ Archived:"
echo "  - $DEST_REPORTS/$(basename "$SUMMARY_SRC")"
echo "  - $DEST_REPORTS/$(basename "$RESULTS_SRC")"
echo "  - $DEST_SIGS/$(basename "$SUMMARY_SRC").sha256"
echo "  - $DEST_SIGS/$(basename "$RESULTS_SRC").sha256"

# Optional: print a short tree
command -v tree >/dev/null 2>&1 && tree -a "$DEST_BASE" || ls -l "$DEST_REPORTS" "$DEST_SIGS"
