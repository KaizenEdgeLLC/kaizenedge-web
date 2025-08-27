# Overnight Action Pack (Deep 🐋 + 🦙)

- [ ] **Dataset v1.4** → models/data/KaizenEdge_Instruct_v1.4.jsonl (1–2k examples, validate against schemas/input_taxonomy_v1.json)
- [ ] **Golden samples (20)** → docs/validation/v1/golden/ (JSON + printable 1-page PDF; guardrails 0 fails)
- [ ] **Inventory stubs** → services/inventory/{costco,walmart,instacart}.py (mock SKUs + unit tests)
- [ ] **Nutrition calc** → services/nutrition/calc.py (deterministic totals + threshold flags)
- [ ] **Guardrails v2 add 20** → models/data/KaizenEdge_Guardrail_Tests_v2.jsonl (pre-commit stays green)
- [ ] **Profile validator CLI** → scripts/validate_profile.py (PASS/FAIL)
- [ ] **Cookbook compiler** → services/cookbook/build.py (generate sample PDF placeholder)
- [ ] **Style linter** → tools/lint/style_lint.py (warn on banned phrases; friendly tone)
- [x] **Perf smoke** → reports/perf/smoke_YYYYMMDD.json (p50/p95 latency; sign later)

**Acceptance:** All stubs import/run; repo commits pass pre-commit guardrail eval.

## Wave-Stripe-and-Services (2025-08-26)

### Stripe Integration (Phase 1.5 → Day 2–3)
- [ ] Add backend **/api/checkout/session** (creates Checkout Session; idempotency key; logs).
- [ ] Add backend **/api/stripe/webhook** (verify signature; write event logs under reports/stripe/; map checkout.session.completed → user active).
- [x] Create **.env.sample** (STRIPE_PUBLISHABLE_KEY, STRIPE_SECRET_KEY) + README for local setup.
- [ ] Add **billing status** field in user model; backfill migration (if needed).

### Inventory & Pricing (toward real data)
- [ ] Define **Item** schema v1 (SKU, gtin, store_id, price, unit, allergens, nutrition map, stock_flag).
- [ ] Write normalizer mock→canonical in .
- [ ] Add 30 realistic mock SKUs per store (Costco/Walmart/Instacart) with varied pack sizes.
- [ ] Unit tests: recipe → ingredient list → item mapping → cart total.

### Nutrition Calculator (hardening)
- [ ] Implement micronutrient rollups (Vit A, D, K, etc.) + sodium/potassium/phosphorus.
- [ ] Add per-meal, per-day, per-week totals + flags.
- [ ] Unit tests for 10 recipes with exact expected totals.

### Frontend Wiring (web + app)
- [ ] Next.js:  page → call  and redirect to Stripe.
- [ ] Return routes  and  (clean UI).
- [ ] Expo: Billing screen with placeholder; wire to backend endpoint (dev base URL).

### Compliance & DHF
- [ ] Create  and log today’s commits + tags.
- [ ] Sign & archive any new reports in  with .
- [ ] Add  (schema validation, guardrails, style lint, signature verify).

### Data & Datasets
- [ ] Expand **Instruct v1.4 → v1.5** (5k examples; cover every input taxonomy field + edge cases).
- [ ] Enrich **Guardrail v2 → v3** (+50 tests: mercury fish, pasteurization, min cook temps, CKD potassium/phosphorus, expiry windows).
- [ ] Generate **Golden Samples (50)** →  (JSON + 1-page PDFs), all passing guardrails.

### Model & Orchestration
- [ ] Pin default adapter: ; keep Deep as fallback (config flag).
- [ ] Add  (cross-field constraints; CKD/pregnancy blocks; statin/grapefruit).
- [ ] Update  to run against ruleset v2.

### Logging & Signatures
- [ ] Implement  (sha256(file) → sidecar + audit log).
- [ ] Ensure plans/carts produced by services get  +  entry.

### Performance Smoke
- [ ] Run 10 golden cases end-to-end; save  with p50/p95 latency & peak RAM; sign & commit.

