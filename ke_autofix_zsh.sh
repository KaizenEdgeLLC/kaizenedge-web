#!/bin/zsh
set -e

echo "[KE] autofix: starting…"

# 1) ensure apps/ and packages/ exist
mkdir -p apps packages

# 2) Next.js web (if missing)
if [[ ! -d apps/web ]]; then
  echo "[KE] creating Next.js app (apps/web)…"
  bunx --bun create-next-app@latest apps/web --ts --app --eslint --tailwind --use-bun
fi

# 3) Expo mobile (optional; create if missing)
if [[ ! -d apps/mobile ]]; then
  echo "[KE] creating Expo app (apps/mobile)…"
  bunx --bun create-expo-app@latest apps/mobile -t expo-template-blank-typescript
  # basic RN tailwind setup markers (files only; you can wire later)
  [[ -f apps/mobile/babel.config.js ]] || cat > apps/mobile/babel.config.js <<'EOB'
module.exports = function(api){api.cache(true);return{presets:['babel-preset-expo']};}
EOB
fi

# 4) shared packages skeletons (create if missing)
for p in ui db config utils; do
  if [[ ! -d packages/$p ]]; then
    mkdir -p packages/$p/src
    cat > packages/$p/package.json <<EOP
{
  "name": "@kaizenedge/$p",
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "types": "src/index.ts"
}
EOP
    echo "export {};" > packages/$p/src/index.ts
    echo "[KE] created packages/$p"
  fi
done

# 5) drizzle config + schema placeholders (if db pkg exists but files missing)
if [[ -d packages/db ]]; then
  mkdir -p packages/db/drizzle packages/db/src
  [[ -f packages/db/drizzle.config.ts ]] || cat > packages/db/drizzle.config.ts <<'EOD'
import { defineConfig } from "drizzle-kit";
export default defineConfig({
  schema: "./src/schema.ts",
  out: "./drizzle",
  driver: "pg",
  dbCredentials: { connectionString: process.env.DATABASE_URL! }
});
EOD
  [[ -f packages/db/src/schema.ts ]] || cat > packages/db/src/schema.ts <<'EOD'
import { pgTable, uuid, text, timestamp } from "drizzle-orm/pg-core";
export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: text("email").notNull().unique(),
  createdAt: timestamp("created_at").defaultNow(),
});
EOD
fi

# 6) docs + ADR
mkdir -p docs .github/workflows
[[ -f docs/ADR-000-stack.md ]] || cat > docs/ADR-000-stack.md <<'EOT'
# ADR-000: Stack
- Monorepo: Turborepo
- Web: Next.js (App Router, TypeScript, Tailwind)
- Mobile: Expo (TypeScript)
- DB: Postgres + Drizzle ORM
- Auth: Supabase
- Payments: Stripe
EOT

# 7) simple CI (runs lint/build)
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

# 8) env example
[[ -f .env.example ]] || cat > .env.example <<'EOT'
DATABASE_URL=postgres://postgres:postgres@localhost:5432/kaizenedge
REDIS_URL=redis://localhost:6379
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
EOT

echo "[KE] autofix: done."
