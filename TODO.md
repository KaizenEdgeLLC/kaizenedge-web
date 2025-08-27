# Overnight Action Pack (Deep 🐋 + 🦙)

- [ ] **Dataset v1.4** → models/data/KaizenEdge_Instruct_v1.4.jsonl (1–2k examples, validate against schemas/input_taxonomy_v1.json)
- [ ] **Golden samples (20)** → docs/validation/v1/golden/ (JSON + printable 1-page PDF; guardrails 0 fails)
- [ ] **Inventory stubs** → services/inventory/{costco,walmart,instacart}.py (mock SKUs + unit tests)
- [ ] **Nutrition calc** → services/nutrition/calc.py (deterministic totals + threshold flags)
- [ ] **Guardrails v2 add 20** → models/data/KaizenEdge_Guardrail_Tests_v2.jsonl (pre-commit stays green)
- [ ] **Profile validator CLI** → scripts/validate_profile.py (PASS/FAIL)
- [ ] **Cookbook compiler** → services/cookbook/build.py (generate sample PDF placeholder)
- [ ] **Style linter** → tools/lint/style_lint.py (warn on banned phrases; friendly tone)
- [ ] **Perf smoke** → reports/perf/smoke_YYYYMMDD.json (p50/p95 latency; sign later)

**Acceptance:** All stubs import/run; repo commits pass pre-commit guardrail eval.
