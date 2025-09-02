#!/usr/bin/env bash
# ke_audit_plus_llm.sh — KaizenEdge Gap Analysis + Local LLM Unlock (LM Studio / Ollama)
# Run from the ROOT of your KaizenEdge repo (where apps/ and packages/ live).
# macOS (Apple Silicon) friendly; safe to re-run.
set -euo pipefail

CE="\033[0m"; B="\033[1m"; BLUE="\033[1;34m"; RED="\033[1;31m"; YEL="\033[1;33m"; GRN="\033[1;32m"; DIM="\033[2m"
say(){ printf "${BLUE}[KE]${CE} %s\n" "$*"; }
ok(){  printf "${GRN}✔${CE} %s\n" "$*"; }
warn(){printf "${YEL}▲${CE} %s\n" "$*"; }
err(){ printf "${RED}✘${CE} %s\n" "$*"; }

have(){ command -v "$1" >/dev/null 2>&1; }
existsf(){ [ -f "$1" ]; }
existsd(){ [ -d "$1" ]; }
timestamp(){ date +"%Y-%m-%d_%H-%M-%S"; }

env_get(){
  local key="$1"
  local files=(".env" ".env.local" "apps/web/.env.local" "apps/mobile/.env")
  for f in "${files[@]}"; do
    if [ -f "$f" ]; then
      local line
      line=$(grep -E "^\s*${key}\s*=" "$f" | tail -n1 || true)
      if [ -n "${line:-}" ]; then
        echo "$line" | sed -E "s/^\s*${key}\s*=\s*//"
        return 0
      fi
    fi
  done
  echo ""
}

TS=$(timestamp)
OUT_DIR="docs"
mkdir -p "$OUT_DIR"
MD_PATH="${OUT_DIR}/system_audit_${TS}.md"
JSON_PATH="${OUT_DIR}/system_audit_${TS}.json"

MD=""; JSON_ITEMS=()
add_md(){ MD+="$1\n"; }
add_json(){ JSON_ITEMS+=("$1"); }
row_md(){ add_md "| $1 | $2 | $3 |"; }
row_json(){ add_json "{\"check\":\"$1\",\"status\":\"$2\",\"severity\":\"$3\",\"notes\":\"$4\"}"; }

audit_tools(){
  say "Checking required/optional tools…"
  add_md "## Tooling"; add_md "| Check | Status | Notes |"; add_md "|---|---|---|"
  local required=(git bun node)
  local optional=(psql redis-cli docker jq stripe vercel expo brew curl)

  for c in "${required[@]}"; do
    if have "$c"; then row_md "cmd:$c" "OK" "$($c --version 2>/dev/null | head -n1)"; row_json "cmd:$c" "ok" "low" "present"; ok "Found $c"
    else row_md "cmd:$c" "MISSING" "Install required tool"; row_json "cmd:$c" "missing" "high" "required"; err "Missing $c"; fi
  done
  for c in "${optional[@]}"; do
    if have "$c"; then row_md "cmd:$c" "OK" "$($c --version 2>/dev/null | head -n1)"; row_json "cmd:$c" "ok" "low" "present"
    else row_md "cmd:$c" "WARN" "optional"; row_json "cmd:$c" "missing" "low" "optional"; fi
  done
}

audit_repo(){
  add_md "\n## Repo Layout"; add_md "| Check | Status | Notes |"; add_md "|---|---|---|"
  if existsd "apps" && existsd "packages"; then row_md "monorepo:folders" "OK" "apps/, packages/"; row_json "monorepo:folders" "ok" "low" "ok"
  else row_md "monorepo:folders" "MISSING" "Expect apps/, packages/"; row_json "monorepo:folders" "missing" "high" "setup turborepo"; fi

  if existsf "turbo.json"; then row_md "turborepo" "OK" "turbo.json present"; row_json "turborepo" "ok" "low" "ok"
  else row_md "turborepo" "MISSING" "add turbo.json"; row_json "turborepo" "missing" "med" "add turbo"; fi
}

audit_apps(){
  add_md "\n## Apps"; add_md "| Check | Status | Notes |"; add_md "|---|---|---|"
  if existsd "apps/web"; then
    NOTES=(); STATUS="OK"
    existsf "apps/web/package.json" || { STATUS="WARN"; NOTES+=("no package.json"); }
    existsd "apps/web/src/app" || { STATUS="WARN"; NOTES+=("no src/app"); }
    (existsf "apps/web/tailwind.config.ts" || existsf "apps/web/tailwind.config.js") || { STATUS="WARN"; NOTES+=("no tailwind config"); }
    existsd "apps/web/src/app/api" || NOTES+=("no API routes (optional)")
    row_md "apps/web" "$STATUS" "${NOTES[*]:-ok}"; row_json "apps/web" "${STATUS,,}" "med" "${NOTES[*]:-ok}"
  else
    row_md "apps/web" "MISSING" "scaffold Next.js"; row_json "apps/web" "missing" "high" "create web"
  fi

  if existsd "apps/mobile"; then
    NOTES=(); STATUS="OK"
    existsf "apps/mobile/app.json" || { STATUS="WARN"; NOTES+=("no app.json"); }
    existsf "apps/mobile/App.tsx" || { STATUS="WARN"; NOTES+=("missing App.tsx"); }
    existsf "apps/mobile/babel.config.js" || { STATUS="WARN"; NOTES+=("missing babel.config.js"); }
    existsf "apps/mobile/tailwind.config.js" || { STATUS="WARN"; NOTES+=("no RN tailwind"); }
    row_md "apps/mobile" "$STATUS" "${NOTES[*]:-ok}"; row_json "apps/mobile" "${STATUS,,}" "med" "${NOTES[*]:-ok}"
  else
    row_md "apps/mobile" "MISSING" "scaffold Expo"; row_json "apps/mobile" "missing" "high" "create mobile"
  fi
}

audit_packages(){
  add_md "\n## Packages"; add_md "| Check | Status | Notes |"; add_md "|---|---|---|"
  for p in ui db config utils; do
    if existsd "packages/$p"; then row_md "packages/$p" "OK" "present"; row_json "packages/$p" "ok" "low" "present"
    else row_md "packages/$p" "MISSING" "create $p"; row_json "packages/$p" "missing" "med" "should exist"; fi
  done
}

audit_db(){
  add_md "\n## Database & Drizzle"; add_md "| Check | Status | Notes |"; add_md "|---|---|---|"
  if existsd "packages/db"; then
    STATUS="OK"; NOTES=()
    existsf "packages/db/drizzle.config.ts" || { STATUS="WARN"; NOTES+=("no drizzle.config.ts"); }
    existsf "packages/db/src/schema.ts" || { STATUS="WARN"; NOTES+=("no schema.ts"); }
    existsd "packages/db/drizzle" && NOTES+=("migrations present") || NOTES+=("no migrations yet")
    row_md "database:drizzle" "$STATUS" "${NOTES[*]}"; row_json "database:drizzle" "${STATUS,,}" "med" "${NOTES[*]}"
  else
    row_md "database:drizzle" "MISSING" "packages/db not found"; row_json "database:drizzle" "missing" "high" "create db package"
  fi

  local DB_URL; DB_URL="$(env_get DATABASE_URL)"
  if [ -n "$DB_URL" ]; then
    if have psql && psql "$DB_URL" -c "SELECT 1;" >/dev/null 2>&1; then
      row_md "postgres:connect" "OK" "DATABASE_URL reachable"; row_json "postgres:connect" "ok" "low" "reachable"
    else
      row_md "postgres:connect" "WARN" "set/verify DATABASE_URL; ensure Postgres running"; row_json "postgres:connect" "warn" "med" "not reachable"
    fi
  else
    row_md "postgres:connect" "MISSING" "DATABASE_URL not set"; row_json "postgres:connect" "missing" "high" "set env"
  fi
}

audit_redis(){
  add_md "\n## Redis"; add_md "| Check | Status | Notes |"; add_md "|---|---|---|"
  local RURL; RURL="$(env_get REDIS_URL)"
  if have redis-cli; then
    if [ -n "$RURL" ] && redis-cli -u "$RURL" ping >/dev/null 2>&1; then
      row_md "redis:connect" "OK" "REDIS_URL reachable"; row_json "redis:connect" "ok" "low" "reachable"
    else
      row_md "redis:connect" "WARN" "no REDIS_URL or not reachable"; row_json "redis:connect" "warn" "low" "optional"
    fi
  else
    row_md "redis:connect" "WARN" "redis-cli not installed (optional)"; row_json "redis:connect" "warn" "low" "optional"
  fi
}

audit_env(){
  add_md "\n## Environment Vars"; add_md "| Check | Status | Notes |"; add_md "|---|---|---|"
  local supa_url supa_key spk ssk swh
  supa_url="$(env_get NEXT_PUBLIC_SUPABASE_URL)"
  supa_key="$(env_get NEXT_PUBLIC_SUPABASE_ANON_KEY)"
  spk="$(env_get NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY)"
  ssk="$(env_get STRIPE_SECRET_KEY)"
  swh="$(env_get STRIPE_WEBHOOK_SECRET)"
  [ -n "$supa_url" ] && [ -n "$supa_key" ] && row_md "supabase" "OK" "URL+ANON present" || row_md "supabase" "MISSING" "add Supabase URL/ANON"
  [ -n "$spk" ] && [ -n "$ssk" ] && [ -n "$swh" ] && row_md "stripe" "OK" "PK+SK+WH set" || row_md "stripe" "MISSING" "set Stripe envs"
}

audit_ci_docs(){
  add_md "\n## CI & Docs"; add_md "| Check | Status | Notes |"; add_md "|---|---|---|"
  existsf ".github/workflows/ci.yml" && row_md "ci:github" "OK" "workflow exists" || row_md "ci:github" "WARN" "add CI workflow"
  existsd "docs" && row_md "docs" "OK" "docs folder exists" || row_md "docs" "WARN" "create docs folder"
  existsf "docs/ADR-000-stack.md" && row_md "docs:ADR-000" "OK" "stack ADR exists" || row_md "docs:ADR-000" "WARN" "create ADR-000"
}

probe_llm(){
  add_md "\n## Local LLM Endpoints"; add_md "| Check | Status | Notes |"; add_md "|---|---|---|"
  local any="no"
  if curl -sS -m 2 http://127.0.0.1:1234/v1/models >/dev/null 2>&1; then
    row_md "LM Studio API" "OK" "http://127.0.0.1:1234 (OpenAI-compatible)"; any="yes"
  else
    row_md "LM Studio API" "MISSING" "Enable Local Server in LM Studio (Dev settings)"
  fi
  if curl -sS -m 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    row_md "Ollama API" "OK" "http://127.0.0.1:11434"; any="yes"
  else
    row_md "Ollama API" "MISSING" "Install/start Ollama to enable"
  fi
  [ "$any" = "no" ] && warn "No local LLM endpoints detected."
}

unlock_ollama(){
  say "Attempting to install/start Ollama and pull Llama/Deep models…"
  if ! have brew; then
    warn "Homebrew not found — install brew from https://brew.sh and re-run."
    return 0
  fi
  if ! have ollama; then
    say "Installing Ollama via Homebrew…"
    brew install ollama || { err "Failed to install Ollama"; return 0; }
  fi
  say "Starting Ollama service…"
  brew services start ollama >/dev/null 2>&1 || true
  (ollama serve >/dev/null 2>&1 &) || true
  sleep 2

  pull_try(){ local m="$1"; say "Pulling model: $m"; ollama pull "$m" && ok "Pulled $m" || warn "Could not pull $m"; }
  pull_try "llama3.1:8b" || pull_try "llama3.1" || pull_try "llama3:8b" || pull_try "llama3" || true
  pull_try "deepseek-r1:7b" || pull_try "deepseek-coder:6.7b" || pull_try "deepseek:7b" || true

  if have jq; then
    say "Testing chat completion on Ollama…"
    MODEL=$(ollama list 2>/dev/null | awk '/llama3/{print $1; exit}' || true)
    if [ -n "${MODEL:-}" ]; then
      curl -s http://127.0.0.1:11434/api/chat \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Say 'KaizenEdge ready'.\"}]}" \
        | jq -r '.message.content // .response' | sed 's/^/> /'
    fi
  fi
  ok "Ollama unlock step finished."
}

lmstudio_instructions(){
  add_md "\n## LM Studio — Enable OpenAI-compatible server"
  add_md "1. Open LM Studio (Applications)."
  add_md "2. Settings → Developer → toggle **Enable Local Server**."
  add_md "3. Note port (default 1234) and download an Instruct model (Llama 3 / DeepSeek)."
  add_md "4. Verify: \`curl http://127.0.0.1:1234/v1/models\`"
}

write_report(){
  add_md "# KaizenEdge System Audit ($(date))"
  add_md ""; add_md "Repo: \`$(pwd)\`"; add_md ""
  printf "%b" "$(echo -e "$MD")" > "$MD_PATH"
  JSON="[$(IFS=,; echo "${JSON_ITEMS[*]-}")]"
  printf "%s\n" "${JSON:-[]}" > "$JSON_PATH"
  say "Reports written:"; echo " - ${MD_PATH}"; echo " - ${JSON_PATH}"
}

say "Starting gap analysis…"
add_md "| Check | Status | Notes |"; add_md "|---|---|---|"
audit_tools
audit_repo
audit_apps
audit_packages
audit_db
audit_redis
audit_env
audit_ci_docs
probe_llm
lmstudio_instructions
write_report

if [[ "${1-}" == "--unlock-llms" ]]; then
  say "Flag --unlock-llms detected."
  unlock_ollama
  say "Re-probing LLM endpoints after unlock…"
  probe_llm
  write_report
fi

printf "\n${DIM}Tip:${CE} Re-run with ${B}--unlock-llms${CE} to auto-install/start Ollama and pull Llama/Deep models.\n"
