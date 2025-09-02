#!/bin/zsh
set -e

ts=$(date +"%Y-%m-%d_%H-%M-%S")
mkdir -p docs
out="docs/system_audit_${ts}.md"

add(){ echo "$1" >> "$out"; }
has(){ command -v "$1" >/dev/null 2>&1; }
existsf(){ [[ -f "$1" ]]; }
existsd(){ [[ -d "$1" ]]; }

# zsh-safe env readers
has_env() {
  local key="$1"
  local files=(.env .env.local apps/web/.env.local apps/mobile/.env)
  for f in $files; do
    [[ -f "$f" ]] && grep -E "^[[:space:]]*$key[[:space:]]*=" "$f" >/dev/null 2>&1 && return 0
  done
  return 1
}
get_env() {
  local key="$1"
  local files=(.env .env.local apps/web/.env.local apps/mobile/.env)
  for f in $files; do
    if [[ -f "$f" ]]; then
      local line
      line=$(grep -E "^[[:space:]]*$key[[:space:]]*=" "$f" | tail -n1 2>/dev/null)
      if [[ -n "$line" ]]; then
        echo "${line#*=}"
        return 0
      fi
    fi
  done
  echo ""
}

line(){ add "| $1 | $2 | $3 |"; }

echo "# KaizenEdge Full System Audit (${ts})" > "$out"
add ""
add "Repo: \`$(pwd)\`"
add ""
add "## Legend"
add "| Status | Meaning |"
add "|---|---|"
add "| OK | present/working |"
add "| WARN | optional or not configured yet |"
add "| MISSING | required and not present |"
add ""

# Tooling
add "## Tooling"
add "| Check | Status | Notes |"
add "|---|---|---|"
for c in git bun node; do
  if has $c; then line "cmd:$c" "OK" "$($c --version | head -n1)"; else line "cmd:$c" "MISSING" "install required"; fi
done
for c in psql redis-cli docker jq stripe vercel expo brew curl; do
  if has $c; then line "cmd:$c" "OK" "present"; else line "cmd:$c" "WARN" "optional"; fi
done
add ""

# Repo layout
add "## Repo Layout"
add "| Check | Status | Notes |"
add "|---|---|---|"
[[ -d apps && -d packages ]] && line "monorepo" "OK" "apps/, packages/ found" || line "monorepo" "MISSING" "expect apps/ + packages/"
[[ -f turbo.json ]] && line "turborepo" "OK" "turbo.json present" || line "turborepo" "MISSING" "add turbo.json"
if [[ -f package.json ]]; then
  mgr=$(node -e "try{let p=require('./package.json');console.log(p.packageManager||'');}catch(e){console.log('');}")
  [[ -n "$mgr" ]] && line "packageManager" "OK" "$mgr" || line "packageManager" "WARN" "no packageManager pinned"
else
  line "package.json" "MISSING" "root package.json not found"
fi
add ""

# Web app
add "## Web App (Next.js)"
add "| Check | Status | Notes |"
add "|---|---|---|"
if existsd apps/web; then
  existsf apps/web/package.json && line "apps/web/package.json" "OK" "exists" || line "apps/web/package.json" "MISSING" "create Next.js app"
  existsd apps/web/src/app && line "App Router (src/app)" "OK" "exists" || line "App Router (src/app)" "WARN" "prefer App Router"
  (existsf apps/web/tailwind.config.ts || existsf apps/web/tailwind.config.js) && line "Tailwind config" "OK" "found" || line "Tailwind config" "WARN" "add Tailwind"
  existsd apps/web/src/app/api && line "API routes" "OK" "folder present" || line "API routes" "WARN" "optional; add later"
  if existsf apps/web/package.json; then
    has_next=$(node -e "let p=require('./apps/web/package.json');let d={...p.dependencies,...p.devDependencies};console.log(d['next']?1:0)")
    [[ "$has_next" = "1" ]] && line "Next dependency" "OK" "next installed" || line "Next dependency" "MISSING" "add next to deps"
  fi
else
  line "apps/web" "MISSING" "scaffold Next.js app in apps/web"
fi
add ""

# Mobile app
add "## Mobile App (Expo)"
add "| Check | Status | Notes |"
add "|---|---|---|"
if existsd apps/mobile; then
  (existsf apps/mobile/app.json || existsf apps/mobile/app.config.js || existsf apps/mobile/app.config.ts) && line "Expo app config" "OK" "found" || line "Expo app config" "WARN" "add app.json/app.config"
  existsf apps/mobile/App.tsx && line "App.tsx" "OK" "found" || line "App.tsx" "MISSING" "create entry file"
  existsf apps/mobile/babel.config.js && line "babel.config.js" "OK" "found" || line "babel.config.js" "MISSING" "add babel config"
  existsf apps/mobile/tailwind.config.js && line "RN Tailwind" "OK" "found" || line "RN Tailwind" "WARN" "optional"
  if existsf apps/mobile/package.json; then
    has_expo=$(node -e "let p=require('./apps/mobile/package.json');let d={...p.dependencies,...p.devDependencies};console.log(d['expo']?1:0)")
    [[ "$has_expo" = "1" ]] && line "Expo dependency" "OK" "expo installed" || line "Expo dependency" "MISSING" "add expo to deps"
  fi
else
  line "apps/mobile" "WARN" "mobile app not found; ok if web-first"
fi
add ""

# Shared packages
add "## Shared Packages"
add "| Check | Status | Notes |"
add "|---|---|---|"
for p in ui db config utils; do
  if existsd packages/$p; then line "packages/$p" "OK" "present"; else line "packages/$p" "WARN" "create if needed"; fi
done
add ""

# Database & ORM
add "## Database & ORM"
add "| Check | Status | Notes |"
add "|---|---|---|"
if existsd packages/db; then
  existsf packages/db/drizzle.config.ts && line "drizzle.config.ts" "OK" "present" || line "drizzle.config.ts" "WARN" "add config"
  existsf packages/db/src/schema.ts && line "schema.ts" "OK" "present" || line "schema.ts" "WARN" "add schema"
  existsd packages/db/drizzle && line "migrations folder" "OK" "present" || line "migrations folder" "WARN" "generate & migrate"
else
  line "packages/db" "WARN" "db package missing"
fi

DB_URL="$(get_env DATABASE_URL)"
if [[ -n "$DB_URL" ]]; then
  if has psql && PGPASSWORD="" psql "$DB_URL" -c "SELECT 1;" >/dev/null 2>&1; then
    line "postgres:connect" "OK" "DATABASE_URL reachable"
  else
    line "postgres:connect" "WARN" "DATABASE_URL set but not reachable"
  fi
else
  line "postgres:connect" "MISSING" "DATABASE_URL not set in .env"
fi
add ""

# Redis
add "## Redis (optional)"
add "| Check | Status | Notes |"
add "|---|---|---|"
REDIS_URL="$(get_env REDIS_URL)"
if has redis-cli; then
  if [[ -n "$REDIS_URL" ]] && redis-cli -u "$REDIS_URL" ping >/dev/null 2>&1; then
    line "redis:connect" "OK" "REDIS_URL reachable"
  else
    line "redis:connect" "WARN" "no REDIS_URL or not reachable"
  fi
else
  line "redis:cli" "WARN" "redis-cli not installed (optional)"
fi
add ""

# Env blocks
add "## Environment Variables"
add "| Check | Status | Notes |"
add "|---|---|---|"
( has_env NEXT_PUBLIC_SUPABASE_URL && has_env NEXT_PUBLIC_SUPABASE_ANON_KEY ) \
  && line "Supabase" "OK" "URL + ANON key set" \
  || line "Supabase" "MISSING" "set NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY"
( has_env NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY && has_env STRIPE_SECRET_KEY && has_env STRIPE_WEBHOOK_SECRET ) \
  && line "Stripe" "OK" "PK + SK + webhook secret set" \
  || line "Stripe" "MISSING" "set NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY / STRIPE_SECRET_KEY / STRIPE_WEBHOOK_SECRET"
add ""

# CI / Docs
add "## CI & Docs"
add "| Check | Status | Notes |"
add "|---|---|---|"
existsf .github/workflows/ci.yml && line "GitHub Actions (CI)" "OK" "workflow found" || line "GitHub Actions (CI)" "WARN" "add CI workflow"
existsd docs && line "docs folder" "OK" "present" || line "docs folder" "WARN" "create docs/"
existsf docs/ADR-000-stack.md && line "ADR-000 (stack)" "OK" "present" || line "ADR-000 (stack)" "WARN" "add ADR-000"
add ""

# Local LLM
add "## Local LLM Endpoints (optional)"
add "| Check | Status | Notes |"
add "|---|---|---|"
if curl -sS -m 2 http://127.0.0.1:1234/v1/models >/dev/null 2>&1; then
  line "LM Studio" "OK" "OpenAI-compatible server on :1234"
else
  line "LM Studio" "WARN" "Enable Local Server in LM Studio (Dev → Local Server)"
fi
if curl -sS -m 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  line "Ollama" "OK" "API on :11434"
else
  line "Ollama" "WARN" "Install/start Ollama (brew install ollama; brew services start ollama)"
fi

echo "Report written to $out"
