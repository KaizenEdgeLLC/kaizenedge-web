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
