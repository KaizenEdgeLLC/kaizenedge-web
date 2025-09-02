#!/usr/bin/env bash
set -euo pipefail
PROJ="kaizenedge_web"
echo "→ Fetching latest Production deployment URL for $PROJ"
RAW="$(pnpm dlx vercel@latest ls "$PROJ" --prod 2>/dev/null || pnpm dlx vercel@latest list "$PROJ" --prod 2>/dev/null || true)"
URL="$(printf "%s\n" "$RAW" | grep -Eo "https://[a-zA-Z0-9.-]+\.vercel\.app" | head -n1)"
if [[ -z "$URL" ]]; then
  echo "❌ Could not detect prod URL. Open Vercel → Project → Deployments and copy the top Production URL."
  exit 1
fi
mkdir -p config
echo "$URL" > config/prod-url.txt
echo "✅ Wrote config/prod-url.txt → $URL"
