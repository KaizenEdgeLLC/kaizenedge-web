#!/usr/bin/env bash
set -euo pipefail
BR="$(git rev-parse --abbrev-ref HEAD)"
WF_NAME="Build KaizenEdge Book"           # <- must match .github/workflows/book-build.yml 'name:'

# Kick a run (ok if workflow already running)
gh workflow run ".github/workflows/book-build.yml" -r "$BR" >/dev/null 2>&1 || true

# Wait for the newest run on this branch to complete, then fetch its ID
gh run watch --exit-status --branch "$BR" --workflow "$WF_NAME" >/dev/null

RUN_ID="$(gh run list --workflow "$WF_NAME" --branch "$BR" --limit 1 --json databaseId -q '.[0].databaseId')"
if [[ -z "${RUN_ID:-}" ]]; then
  echo "❌ Could not find a completed run for '$WF_NAME' on branch '$BR'."; exit 1
fi

mkdir -p books/kaizenedge-guide/build
# Clear old artifacts of same names (optional)
rm -f books/kaizenedge-guide/build/KaizenEdge_Guide.* 2>/dev/null || true

# Download artifacts for that run (non-interactive)
gh run download "$RUN_ID" -D books/kaizenedge-guide/build

echo "📦 Artifacts now in books/kaizenedge-guide/build:"
ls -1 books/kaizenedge-guide/build | sed 's/^/  - /'
