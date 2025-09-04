#!/usr/bin/env zsh
set -euo pipefail
BR="$(git rev-parse --abbrev-ref HEAD)"
gh workflow run ".github/workflows/book-build.yml" -r "$BR"
gh run watch --exit-status
RUN_ID=$(gh run list --workflow "book-build.yml" --branch "$BR" --limit 1 --json databaseId -q '.[0].databaseId')
mkdir -p books/kaizenedge-guide/build
rm -f books/kaizenedge-guide/build/KaizenEdge_Guide.* 2>/dev/null || true
gh run download "$RUN_ID" -D books/kaizenedge-guide/build
ls -1 books/kaizenedge-guide/build
