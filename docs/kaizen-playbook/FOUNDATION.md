# KaizenEdge Foundation (Locked)
**Date:** 2025-09-02 20:59 UTC

## What’s locked
- Next.js app at `apps/web`
- Production deploy on Vercel (public, JSON APIs)
- Env: `OPENAI_API_KEY`, `OPENAI_MODEL` set in Vercel (Production)
- Health endpoints: `/api/health`, `/api/local-llm` (GET/POST)

## Sanity check
```bash
export PROD_URL="$(cat config/prod-url.txt)"; scripts/prod-sanity.sh
```

## Deployment rules
- All work via PR → `main`
- CI must be green before merge
- If prod breaks: rollback to previous green deployment via Vercel

## Next milestones
- Auth & DB (Supabase)
- Payments (Stripe)
- UI polish to match kaizenedge.org
