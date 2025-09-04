#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
INBOX="$ROOT/books/kaizenedge-guide/inbox"
ALL="$INBOX/all-in-one.md"
MANU="$ROOT/books/kaizenedge-guide/manuscript"
BUILD="$ROOT/books/kaizenedge-guide/build"
WF_NAME="Build KaizenEdge Book"

MODE="clipboard"
SRC=""
SPLIT="no"
BUILD_FLAG="no"
COMMIT_MSG="docs(book): append llama output"

usage(){
  cat <<USAGE
Usage: ke-append [--from-clipboard] [--from-file <path>] [--split] [--build] [--message "<commit msg>"]
USAGE
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from-clipboard) MODE="clipboard"; shift ;;
    --from-file) MODE="file"; SRC="${2:-}"; shift 2 ;;
    --split) SPLIT="yes"; shift ;;
    --build) BUILD_FLAG="yes"; SPLIT="yes"; shift ;;
    --message) COMMIT_MSG="${2:-$COMMIT_MSG}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

mkdir -p "$INBOX" "$MANU" "$BUILD"
touch "$ALL"

# Capture input to temp
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
if [[ "$MODE" == "clipboard" ]]; then
  command -v pbpaste >/dev/null || { echo "❌ pbpaste not found"; exit 1; }
  pbpaste > "$TMP"
else
  [[ -n "$SRC" && -f "$SRC" ]] || { echo "❌ Missing/invalid --from-file path"; exit 1; }
  cat "$SRC" > "$TMP"
fi

# Optional marker check (warn only)
if ! grep -q '^=== FILE: .*\.md ===$' "$TMP"; then
  echo "⚠️  No file markers found (=== FILE: name.md ===). Appending anyway."
fi

# Append with timestamp
{
  echo ""
  echo "<!-- APPEND @ $(date '+%Y-%m-%d %H:%M:%S') -->"
  cat "$TMP"
  echo ""
} >> "$ALL"
echo "✅ Appended to $ALL"

# Split if requested
if [[ "$SPLIT" == "yes" ]]; then
  [[ -x "$ROOT/automation/scripts/ke-splitmanuscript.zsh" ]] || { echo "❌ Missing splitter"; exit 1; }
  "$ROOT/automation/scripts/ke-splitmanuscript.zsh"

  # Commit manuscript changes if any
  if ! git -C "$ROOT" diff --quiet -- "$MANU"; then
    git -C "$ROOT" add "$MANU"
    git -C "$ROOT" commit -m "$COMMIT_MSG" || true
    git -C "$ROOT" push || true
  else
    echo "ℹ️  No manuscript changes to commit."
  fi
fi

# Non-interactive build (if requested)
if [[ "$BUILD_FLAG" == "yes" ]]; then
  BR="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
  # Trigger (ok if already running)
  gh workflow run ".github/workflows/book-build.yml" -r "$BR" >/dev/null 2>&1 || true
  # Wait for the newest run to finish on this branch
  gh run watch --exit-status --branch "$BR" --workflow "$WF_NAME" >/dev/null
  # Fetch newest run id
  RUN_ID="$(gh run list --workflow "$WF_NAME" --branch "$BR" --limit 1 --json databaseId -q '.[0].databaseId')"
  if [[ -z "${RUN_ID:-}" ]]; then
    echo "❌ Could not find a completed run for '$WF_NAME' on branch '$BR'."; exit 1
  fi
  mkdir -p "$BUILD"
  gh run download "$RUN_ID" -D "$BUILD"
  echo "📦 Artifacts:"
  ls -1 "$BUILD" | sed 's/^/  - /'
fi
