#!/usr/bin/env bash
set -euo pipefail

# --- settings ---
RULESET="rulesets/v1.json"
BACKUP="rulesets/v1.json.bak.verify"
EVAL="models/eval_guardrails.py"
VENV=".venv"

echo "== Verify ruleset is in effect (temporary threshold tweak) =="

# Ensure venv
if [ ! -d "$VENV" ]; then
  echo "ERROR: $VENV not found. Run: python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"
  exit 1
fi
source "$VENV/bin/activate"

# 1) Backup current ruleset
cp -f "$RULESET" "$BACKUP"
echo "Backed up $RULESET -> $BACKUP"

# 2) Lower diabetes sugar threshold to force failures
python - <<'PY'
import json
path = "rulesets/v1.json"
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
thr = data.setdefault("thresholds", {})
thr["diabetes_added_sugars_high_g"] = 1  # TEMP tweak for verification
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
print("Temporarily set diabetes_added_sugars_high_g = 1")
PY

# 3) Run evaluator (expect some diabetes tests to fail)
echo
echo "-- RUN with TEMP threshold (expect FAILs) --"
python "$EVAL" | tail -n 5

# 4) Restore ruleset
mv -f "$BACKUP" "$RULESET"
echo "Restored original $RULESET"

# 5) Run evaluator again (expect all green)
echo
echo "-- RUN with ORIGINAL threshold (expect all PASS) --"
python "$EVAL" | tail -n 5

echo
echo "✅ Verification complete."
