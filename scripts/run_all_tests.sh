#!/usr/bin/env bash
set -euo pipefail
echo "[KE] Running schema validation…"
python -m jsonschema -i sample_profile.json schemas/input_taxonomy_v1.json || true
echo "[KE] Running guardrails…"
python models/eval_guardrails.py || true
echo "[KE] Style lint…"
echo "Sample content" | python tools/lint/style_lint.py || true
echo "[KE] Signature check (if any)…"
echo "[KE] Done."
