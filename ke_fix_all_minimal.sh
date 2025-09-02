#!/bin/zsh
set -e

echo "[KE] starting minimal fix…"

# ----- .env (create + ensure keys) -----
[[ -f .env ]] || touch .env

ensure_line() {
  local key="$1"; local val="$2"
  if ! grep -q "^${key}=" .env 2>/dev/null; then
    printf "%s=%s\n" "$key" "$val" >> .env
  fi
}

ensure_line DATABASE_URL "postgres://postgres:postgres@localhost:5432/kaizenedge"
ensure_line REDIS_URL "redis://localhost:6379"
ensure_line NEXT_PUBLIC_SUPABASE_URL ""
ensure_line NEXT_PUBLIC_SUPABASE_ANON_KEY ""
ensure_line NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY ""
ensure_line STRIPE_SECRET_KEY ""
ensure_line STRIPE_WEBHOOK_SECRET ""
ensure_line LOCAL_OPENAI_BASE_URL "http://127.0.0.1:1234/v1"
ensure_line LOCAL_OPENAI_API_KEY "lmstudio-local"
ensure_line LOCAL_OPENAI_MODEL "meta-llama-3.1-70b-instruct"

echo "[KE] .env now contains:"
grep -E '^(DATABASE_URL|REDIS_URL|NEXT_PUBLIC_|STRIPE_|LOCAL_OPENAI_)' .env | sed 's/=.*$/=<redacted>/'

# ----- services (best effort) -----
if command -v brew >/dev/null 2>&1; then
  brew services start postgresql >/dev/null 2>&1 || true
  createdb kaizenedge 2>/dev/null || true
  brew services start redis >/dev/null 2>&1 || true
fi

# connectivity checks (won’t fail script)
DB_URL=$(sed -n 's/^DATABASE_URL=//p' .env)
if command -v psql >/dev/null 2>&1; then
  psql "$DB_URL" -c "SELECT 1;" >/dev/null 2>&1 && echo "[KE] Postgres ✔" || echo "[KE] Postgres not reachable (ok to continue)."
fi
RURL=$(sed -n 's/^REDIS_URL=//p' .env)
if command -v redis-cli >/dev/null 2>&1; then
  redis-cli -u "$RURL" ping >/dev/null 2>&1 && echo "[KE] Redis ✔" || echo "[KE] Redis not reachable (optional)."
fi

# ----- scaffold web (Next.js) if missing -----
if [[ ! -d apps/web ]]; then
  echo "[KE] Scaffolding Next.js (apps/web)…"
  bunx --bun create-next-app@latest apps/web --ts --app --eslint --tailwind --use-bun
fi
mkdir -p apps/web/src/app/api/health
cat > apps/web/src/app/api/health/route.ts <<'EOT'
import { NextResponse } from "next/server";
export async function GET() { return NextResponse.json({ ok: true, ts: Date.now() }); }
EOT

# ----- scaffold mobile (Expo) if missing -----
if [[ ! -d apps/mobile ]]; then
  echo "[KE] Scaffolding Expo (apps/mobile)…"
  bunx --bun create-expo-app@latest apps/mobile -t expo-template-blank-typescript
fi
[[ -f apps/mobile/App.tsx ]] || cat > apps/mobile/App.tsx <<'EOT'
import { Text, View } from "react-native";
export default function App() {
  return (
    <View style={{ flex:1, alignItems:"center", justifyContent:"center" }}>
      <Text>KaizenEdge — Mobile Ready</Text>
    </View>
  );
}
EOT
[[ -f apps/mobile/babel.config.js ]] || cat > apps/mobile/babel.config.js <<'EOT'
module.exports = function(api) { api.cache(true); return { presets: ['babel-preset-expo'] }; };
EOT

# ----- baseline configs (idempotent) -----
[[ -f turbo.json ]] || cat > turbo.json <<'EOT'
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**", ".next/**"] },
    "dev":   { "cache": false },
    "lint":  { "outputs": [] },
    "test":  { "outputs": [] }
  }
}
EOT

mkdir -p .github/workflows docs
[[ -f docs/ADR-000-stack.md ]] || cat > docs/ADR-000-stack.md <<'EOT'
# ADR-000: Stack
- Monorepo: Turborepo
- Web: Next.js (App Router, TypeScript, Tailwind)
- Mobile: Expo (TypeScript)
- DB: Postgres + Drizzle ORM
- Auth: Supabase
- Payments: Stripe
EOT

[[ -f .github/workflows/ci.yml ]] || cat > .github/workflows/ci.yml <<'EOT'
name: CI
on:
  push: { branches: [ main ] }
  pull_request: {}
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v2
        with: { bun-version: 1.2.21 }
      - run: bun install
      - run: bunx turbo run lint --continue
      - run: bunx turbo run build --continue
EOT

# ----- install deps & final audit -----
bun install
./ke_audit_full_zsh.sh
latest=$(ls -t docs/system_audit_*.md | head -n1)
echo "[KE] Latest report => $latest"
