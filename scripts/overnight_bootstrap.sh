#!/usr/bin/env bash
set -euo pipefail

echo "[KE] Overnight bootstrap starting…"

# 1) Folders
mkdir -p models/data docs/validation/v1/golden services/inventory services/nutrition services/cookbook services/common tools/lint reports/perf scripts

# 2) Stubs (minimal, importable, with TODOs)
cat > scripts/validate_profile.py <<'PY'
#!/usr/bin/env python3
import sys, json
from jsonschema import Draft202012Validator
import pathlib
schema = json.load(open("schemas/input_taxonomy_v1.json"))
v = Draft202012Validator(schema)
ok=True
for p in sys.argv[1:]:
    data=json.load(open(p))
    try: v.validate(data)
    except Exception as e:
        print(f"❌ {p}: {e}"); ok=False
    else:
        print(f"✅ {p}: PASS")
sys.exit(0 if ok else 1)
PY
chmod +x scripts/validate_profile.py

cat > services/inventory/common.py <<'PY'
from dataclasses import dataclass
from typing import List, Optional
@dataclass
class Item:
    sku: str; name: str; store: str; price_usd: float; unit: str; in_stock: bool; nutrition_hint: Optional[dict]=None
def build_cart(items: List[Item]) -> dict:
    total = round(sum(i.price_usd for i in items), 2)
    return {"items":[i.__dict__ for i in items], "total_usd": total}
PY

for s in costco walmart instacart; do
cat > "services/inventory/${s}.py" <<'PY'
from .common import Item, build_cart
def search_items(query: str, location: str):
    # MOCK: replace with real API in Phase 2
    return [Item(sku="MOCK-001", name=f"{query} (mock)", store=__name__.split('.')[-1], price_usd=3.49, unit="each", in_stock=True)]
def get_price(sku: str, location: str):
    return 3.49
def build_demo_cart(q: str, loc: str):
    return build_cart(search_items(q, loc))
PY
done

cat > services/nutrition/calc.py <<'PY'
# Deterministic roll-up: ingredient -> recipe -> day plan
def sum_nutrients(ingredients):
    keys=set().union(*[i["nutrients"].keys() for i in ingredients]) if ingredients else set()
    return {k: round(sum(i["nutrients"].get(k,0) for i in ingredients),2) for k in keys}
def enforce_thresholds(totals, limits):
    violations = {k: totals.get(k,0) for k,v in limits.items() if totals.get(k,0) > v}
    return {"violations": violations, "hard_fail": bool(violations)}
PY

cat > services/cookbook/build.py <<'PY'
import argparse, json, pathlib
def build(user_id: str, out: str):
    p=pathlib.Path(out); p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(f"Cookbook for user {user_id}\\n(placeholder)", encoding="utf-8")
    print("Wrote", p)
if __name__=="__main__":
    ap=argparse.ArgumentParser(); ap.add_argument("--user", required=True); ap.add_argument("--out", required=True)
    a=ap.parse_args(); build(a.user, a.out)
PY

cat > tools/lint/style_lint.py <<'PY'
import sys
BANNED = ["just trust me", "probably fine"]
VOICE = "friendly"
def lint(txt: str):
    errs=[]
    for b in BANNED:
        if b.lower() in txt.lower(): errs.append(f"banned phrase: {b}")
    return errs
if __name__=="__main__":
    data=sys.stdin.read()
    errs=lint(data)
    if errs: print("\\n".join(errs)); sys.exit(1)
    print("OK"); sys.exit(0)
PY

# 3) Golden samples folder marker
echo "# Golden cases (JSON + 1-page PDF per case)" > docs/validation/v1/golden/README.md

# 4) Overnight TODO with acceptance criteria
cat > TODO.md <<'MD'
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
MD

# 5) Git add + commit (triggers pre-commit)
git add TODO.md scripts/validate_profile.py services tools docs/validation/v1/golden/README.md
git commit -m "chore: overnight bootstrap (stubs, validator, TODO) — ready for Deep & 🦙"
echo "[KE] Overnight bootstrap done."
