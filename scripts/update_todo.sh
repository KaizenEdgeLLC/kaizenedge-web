#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
WAVE_NAME="${1:-Wave-Next}"
TODAY="$(date +%Y-%m-%d)"
MARKER="## ${WAVE_NAME} (${TODAY})"

# create TODO.md if missing
if [ ! -f TODO.md ]; then
  cat > TODO.md <<'HDR'
# KaizenEdge 90-Day Launch Plan — Execution Backlog
*(Deep 🐋 + 🦙 pick tasks from here, mark complete, commit with guardrail eval)*

**Execution Rule:**
1) Commit with a clear message (`feat:`, `chore:`, `docs:`)
2) Pass pre-commit FDA guardrail eval ✅
3) Update `TODO.md` (check off `[x]`)
4) Sign & archive any artifacts (`.sha256` → `docs/validation/`)
HDR
fi

# skip if this wave already exists
if grep -q "^${MARKER}\$" TODO.md; then
  echo "[KE] ${WAVE_NAME} already present for ${TODAY}. Nothing to do."
  exit 0
fi

# append new wave
cat >> TODO.md <<EOF

${MARKER}

### Stripe Integration (Phase 1.5 → Day 2–3)
- [ ] Add backend **/api/checkout/session** (creates Checkout Session; idempotency key; logs).
- [ ] Add backend **/api/stripe/webhook** (verify signature; write event logs under reports/stripe/; map checkout.session.completed → user active).
- [ ] Create **.env.sample** (STRIPE_PUBLISHABLE_KEY, STRIPE_SECRET_KEY) + README for local setup.
- [ ] Add **billing status** field in user model; backfill migration (if needed).

### Inventory & Pricing (toward real data)
- [ ] Define **Item** schema v1 (SKU, gtin, store_id, price, unit, allergens, nutrition map, stock_flag).
- [ ] Write normalizer mock→canonical in `services/inventory/normalize.py`.
- [ ] Add 30 realistic mock SKUs per store (Costco/Walmart/Instacart) with varied pack sizes.
- [ ] Unit tests: recipe → ingredient list → item mapping → cart total.

### Nutrition Calculator (hardening)
- [ ] Implement micronutrient rollups (Vit A, D, K, etc.) + sodium/potassium/phosphorus.
- [ ] Add per-meal, per-day, per-week totals + flags.
- [ ] Unit tests for 10 recipes with exact expected totals.

### Frontend Wiring (web + app)
- [ ] Next.js: `/billing` page → call `/api/checkout/session` and redirect to Stripe.
- [ ] Return routes `/billing/success` and `/billing/cancel` (clean UI).
- [ ] Expo: Billing screen with placeholder; wire to backend endpoint (dev base URL).

### Compliance & DHF
- [ ] Create `docs/compliance/Design_History_Log.md` and log today’s commits + tags.
- [ ] Sign & archive any new reports in `docs/validation/v1/` with `.sha256`.
- [ ] Add `scripts/run_all_tests.sh` (schema validation, guardrails, style lint, signature verify).

### Data & Datasets
- [ ] Expand **Instruct v1.4 → v1.5** (5k examples; cover every input taxonomy field + edge cases).
- [ ] Enrich **Guardrail v2 → v3** (+50 tests: mercury fish, pasteurization, min cook temps, CKD potassium/phosphorus, expiry windows).
- [ ] Generate **Golden Samples (50)** → `docs/validation/v1/golden/` (JSON + 1-page PDFs), all passing guardrails.

### Model & Orchestration
- [ ] Pin default adapter: `ke-sft-llama3.2-3b-v0.1`; keep Deep as fallback (config flag).
- [ ] Add `rulesets/v2.json` (cross-field constraints; CKD/pregnancy blocks; statin/grapefruit).
- [ ] Update `models/eval_guardrails.py` to run against ruleset v2.

### Logging & Signatures
- [ ] Implement `services/common/signing.py` (sha256(file) → sidecar + audit log).
- [ ] Ensure plans/carts produced by services get `.sha256` + `logs/audit.log` entry.

### Performance Smoke
- [ ] Run 10 golden cases end-to-end; save `reports/perf/smoke_${TODAY//-/}.json` with p50/p95 latency & peak RAM; sign & commit.

EOF

git add TODO.md
git commit -m "chore: add ${WAVE_NAME} (${TODAY}) to TODO backlog" || true
echo "[KE] Appended ${WAVE_NAME} and committed."
