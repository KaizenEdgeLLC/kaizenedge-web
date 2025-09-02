#!/usr/bin/env bash
set -euo pipefail
if [[ -z "${PROD_URL:-}" ]]; then
  if [[ -f "config/prod-url.txt" ]]; then
    PROD_URL="$(cat config/prod-url.txt)"
  else
    echo "❌ PROD_URL not set. Set env PROD_URL or put URL in config/prod-url.txt"
    exit 1
  fi
fi
echo "🔎 Sanity on $PROD_URL"
echo "1) HEADERS"
curl -s -D - -o /dev/null "$PROD_URL/api/health" | sed -n "1,20p" | sed "s/^/   /"
CT=$(curl -sI "$PROD_URL/api/health" | awk -F": " 'tolower($1)=="content-type"{print tolower($2)}' | tr -d "\r")
if ! printf "%s" "$CT" | grep -q "application/json"; then
  echo "❌ content-type not JSON (deployment protection or misroute)."
  exit 2
fi
echo "✅ JSON Content-Type"
echo "2) HEALTH JSON"
curl -s "$PROD_URL/api/health" | jq .
echo "3) LLM STATUS"
curl -s "$PROD_URL/api/local-llm" | jq .
echo "4) LLM ROUND-TRIP"
curl -s "$PROD_URL/api/local-llm" -H "Content-Type: application/json" -d '{"prompt":"Say hello from KaizenEdge prod","model":"gpt-4o-mini"}' | jq '.ok, .data.choices[0].message.content'
echo "✅ Done"
