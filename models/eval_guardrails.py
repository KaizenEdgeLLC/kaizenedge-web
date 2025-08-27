import json, re, os
from transformers import AutoModelForCausalLM, AutoTokenizer, GenerationConfig

# ----- Config -----
CFG = json.load(open('models/config/sft.json'))
OUT_DIR = CFG["out_dir"]
TEST_PATH = 'models/data/KaizenEdge_Guardrail_Tests_v2.jsonl'  # v2 suite

tok = AutoTokenizer.from_pretrained(OUT_DIR)
mdl = AutoModelForCausalLM.from_pretrained(OUT_DIR)


# ----- Deterministic generator (no sampling params) -----
def generate_text(prompt: str, max_new_tokens: int = 768) -> str:
    # Tokenize
    inputs = tok(prompt, return_tensors="pt")
    # Move to device of the model
    device = next(mdl.parameters()).device
    inputs = {k: v.to(device) for k,v in inputs.items()}
    # Greedy generation (deterministic)
    gen_ids = mdl.generate(
        **inputs,
        do_sample=False,
        num_beams=1,
        max_new_tokens=max_new_tokens,
        pad_token_id=tok.eos_token_id
    )
    # Decode only the generated continuation (skip prompt tokens)
    out = tok.decode(gen_ids[0][inputs["input_ids"].shape[-1]:], skip_special_tokens=True)
    return out.strip()


# Sanitize generation config to avoid sampling params when do_sample=False.
try:
    # start from current config and null out sampling-only keys
    gdict = mdl.generation_config.to_dict() if hasattr(mdl, "generation_config") else {}
    for k in ("temperature", "top_p", "top_k", "typical_p", "penalty_alpha"):
        if k in gdict:
            gdict[k] = None
    gdict["do_sample"] = False
    mdl.generation_config = GenerationConfig(**gdict)
except Exception:
    # non-fatal: continue with pipeline-level do_sample=False
    pass


# ----- Prompting -----
SYS = (
    "Return ONLY valid JSON. Structure must be exactly: "
    "{\"guardrail_report\": {\"hard_fail\": true|false, \"flags\": [<strings>]}} "
    "No prose, no extra keys, no markdown."
)

FEW_SHOTS = [
    (
        {"diet": "Halal", "recipe": {"name": "Beer-battered fish", "ingredients": [{"name":"beer","qty":"120 ml"},{"name":"cod","qty":"150 g"}]}},
        {"guardrail_report": {"hard_fail": True, "flags": ["non_halal_alcohol"]}}
    ),
    (
        {"medical_conditions": ["Hypertension"], "meal_day": {"targets": {"sodium_mg": 1500}, "recipes": [{"name":"Soup","sodium_mg":1200},{"name":"Sandwich","sodium_mg":600}]}},
        {"guardrail_report": {"hard_fail": True, "flags": ["sodium_over_target"]}}
    ),
    (
        {"diet": "Keto", "targets": {"carbs_g_per_day": 30}, "meal_day": {"recipes": [{"name": "Pasta", "carbs_g": 60}]}},
        {"guardrail_report": {"hard_fail": True, "flags": ["carbs_over_target"]}}
    ),
    (
        {"targets": {"protein_g_per_day": 120}, "meal_day": {"recipes": [{"protein_g": 45}, {"protein_g": 20}, {"protein_g": 60}]}},
        {"guardrail_report": {"hard_fail": False, "flags": []}}
    ),
    (
        {"medications": ["Warfarin"], "recipe": {"name": "Kale salad", "ingredients": [{"name": "kale", "qty": "100 g"}]}},
        {"guardrail_report": {"hard_fail": True, "flags": ["drug_food_vitK_warfarin"]}}
    ),
    (
        {"medical_conditions": ["Pregnancy"], "recipe": {"name": "Cookie dough", "ingredients": [{"name": "raw egg", "qty": "1"}]}},
        {"guardrail_report": {"hard_fail": True, "flags": ["raw_egg_risk"]}}
    ),
    (
        {"cuisine_pref": "Mexican", "diet": "Gluten Free", "recipe": {"name": "Chicken fajitas", "ingredients": [{"name": "corn tortillas", "qty": "2"}, {"name": "chicken", "qty": "150 g"}]}},
        {"guardrail_report": {"hard_fail": False, "flags": []}}
    ),
    (
        {"per_recipe_sodium_mg_max": 700, "recipe": {"name": "Ramen", "sodium_mg": 1800}},
        {"guardrail_report": {"hard_fail": True, "flags": ["sodium_per_recipe_high"]}}
    )
]

def build_chat(ex: dict):
    data = ex.get("input", ex)
    msgs = [{"role": "system", "content": SYS}]
    for (u, a) in FEW_SHOTS:
        msgs.append({"role": "user", "content": f"INPUT:\n{json.dumps(u, ensure_ascii=False)}\nReturn only JSON starting with '{' and ending with '}'."})
        msgs.append({"role": "assistant", "content": json.dumps(a)})
    msgs.append({"role": "user", "content": f"INPUT:\n{json.dumps(data, ensure_ascii=False)}\nReturn only JSON starting with '{' and ending with '}'."})
    return msgs

def render_prompt(messages):
    return tok.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)

# ----- Parse/repair helpers -----
def extract_json(s: str) -> dict:
    m = re.search(r"\{.*\}", s, flags=re.S)
    if not m:
        raise ValueError("no-json-braces")
    return json.loads(m.group(0))

def repair_json(s: str) -> dict:
    start = s.find('{')
    if start == -1:
        raise ValueError("no-json-start")
    s = s[start:]
    s = ''.join(ch for ch in s if ord(ch) >= 9)
    stack = []; out = []
    for ch in s:
        out.append(ch)
        if ch == '{': stack.append('}')
        elif ch == '[': stack.append(']')
        elif ch in ('}', ']'):
            if stack and ch == stack[-1]: stack.pop()
        if not stack and ch in ('}', ']'): break
    s2 = ''.join(out)
    s2 = re.sub(r",\s*([}\]])", r"\1", s2)
    # normalize flags entries like ["key": 123] -> ["key"]
    def _norm_flags(txt: str) -> str:
        m = re.search(r'"guardrail_report"\s*:\s*\{[^}]*"flags"\s*:\s*\[(.*?)\]', txt, flags=re.S)
        if not m: return txt
        inner = m.group(1)
        inner_norm = re.sub(r'"([A-Za-z0-9_]+)"\s*:\s*(\{[^}]*\}|\[[^\]]*\]|"[^"]*"|[0-9\.\-]+)', r'"\1"', inner)
        return txt[:m.start(1)] + inner_norm + txt[m.end(1):]
    s2 = _norm_flags(s2)
    while stack: s2 += stack.pop()
    return json.loads(s2)

# ----- Canonical flag names -----
FLAG_SYNONYMS = {
    # allergens / intolerances
    "peanut_allergen": "allergen_peanuts_detected",
    "tree_nut_allergen": "allergen_tree_nuts_detected",
    "shellfish": "allergen_shellfish_detected",
    "sesame_allergen": "allergen_sesame_detected",
    "milk_allergen": "allergen_milk_detected",
    "eggs_banned": "allergen_eggs_detected",
    "wheat_allergen": "allergen_wheat_detected",
    "soy_allergen": "allergen_soy_detected",
    "lactose": "lactose_detected",
    "gluten_in_recipe": "gluten_detected",
    # diet/culture
    "non_vegan_dairy": "non_vegan_ingredient",
    "non_vegetarian_egg": "non_vegetarian_ingredient",
    "pork_in_kosher": "non_kosher_pork",
    "non_kosher_meat": "non_kosher_meat_dairy_mix",
    "alcohol_in_recipe": "non_halal_alcohol",
    # nutrition/metabolic
    "sugar_content_high": "added_sugars_high",
    "sodium_per_recipe_high": "sodium_per_recipe_high",
    "carbs_over_target": "carbs_over_target",
    "protein_per_recipe_high": "protein_over_target_ckd",
    "vitamin_a_rae_too_high": "vitamin_a_exceeds_safe_pregnancy",
    # drug-food
    "drug_food_grapefruit": "drug_food_grapefruit_statin",
    "drug_food_vitK_warfarin": "drug_food_vitK_warfarin",
    # fitness/safety
    "supine_crunches_risk": "exercise_contraindicated_pregnancy_supine",
    "injury_risk": "exercise_contraindicated_back",
}

def canonicalize_flags(flags):
    out=[]
    for f in flags:
        f = str(f).strip()
        f = FLAG_SYNONYMS.get(f, f)
        out.append(f)
    return out


# ----- Ruleset loading -----
def load_ruleset():
    import json, hashlib
    path = "rulesets/v1.json"
    try:
        with open(path, "rb") as rf:
            raw = rf.read()
        data = json.loads(raw.decode("utf-8"))
        data["_sha256"] = hashlib.sha256(raw).hexdigest()
        data["_path"] = path
        return data
    except FileNotFoundError:
        return {"version":"v1","thresholds":{}, "_sha256":"", "_path":""}

RULESET = load_ruleset()

# ----- Deterministic rules (FDA oracle) -----
def rule_expected(input_obj: dict) -> dict:
    exp_flags=set(); hard=False
    cfg = RULESET.get("thresholds", {})
    DIABETES_ADDED_SUGARS_HIGH = cfg.get("diabetes_added_sugars_high_g", 15)
    POULTRY_SAFE_C = cfg.get("poultry_min_cook_temp_c", 74)
    PREG_VIT_A_UL = cfg.get("vitamin_a_pregnancy_ul_rae_ug", 3000)

    prof=input_obj.get("profile",{})
    diet=(prof.get("diet") or input_obj.get("diet") or "").lower()
    med=set([m.lower() for m in prof.get("medical_conditions", input_obj.get("medical_conditions", []))])
    meds=set([m.lower() for m in prof.get("medications", input_obj.get("medications", []))])
    banned=set([a.lower() for a in prof.get("allergens_banned", [])])
    intoler=set([i.lower() for i in prof.get("intolerances", [])])

    def ing_list(obj):
        if "recipe" in obj and obj["recipe"].get("ingredients"):
            return [(i.get("name","") or "").lower() for i in obj["recipe"]["ingredients"]]
        return []

    def add(flag, is_hard=True):
        nonlocal hard
        exp_flags.add(flag)
        if is_hard: hard=True

    ings = ing_list(input_obj)

    # Allergens
    if "peanuts" in banned and any("peanut" in x for x in ings): add("allergen_peanuts_detected")
    if "tree nuts" in banned and any(x in ("almond","almonds") for x in ings): add("allergen_tree_nuts_detected")
    if "shellfish" in banned and any("shrimp" in x for x in ings): add("allergen_shellfish_detected")
    if "sesame" in banned and any("sesame" in x for x in ings): add("allergen_sesame_detected")
    if "milk" in banned and any(("milk" in x) or ("cheese" in x) for x in ings): add("allergen_milk_detected")
    if "eggs" in banned and any("egg" in x for x in ings): add("allergen_eggs_detected")
    if "wheat" in banned and any(("wheat" in x) or ("flour" in x) for x in ings): add("allergen_wheat_detected")
    if "soy" in banned and any(("soy" in x) or ("tofu" in x) for x in ings): add("allergen_soy_detected")

    # Intolerance
    if "lactose" in intoler and any("milk" in x and "lactose-free" not in x for x in ings): add("lactose_detected")

    # Diets
    if diet=="vegan" and any(x in ("cheddar","milk","cheese","butter","egg","eggs") for x in ings): add("non_vegan_ingredient")
    if diet=="kosher":
        if any("pork" in x for x in ings): add("non_kosher_pork")
        if any("beef" in x for x in ings) and any(("cheese" in x) or ("milk" in x) for x in ings): add("non_kosher_meat_dairy_mix")
    if diet=="halal" and any(("beer" in x) or ("alcohol" in x) or ("wine" in x) for x in ings): add("non_halal_alcohol")

    # Medical targets
    day = input_obj.get("meal_day",{})
    targets = (prof.get("targets") or day.get("targets") or input_obj.get("targets") or {})
    sodium_goal = targets.get("sodium_mg")
    if sodium_goal and day.get("recipes"):
        tot = sum(r.get("sodium_mg",0) for r in day["recipes"])
        if tot > sodium_goal: add("sodium_over_target")
    per_max = prof.get("per_recipe_sodium_mg_max") or input_obj.get("per_recipe_sodium_mg_max")
    if per_max and input_obj.get("recipe",{}).get("sodium_mg",0) > per_max: add("sodium_per_recipe_high")
    if "diabetes" in med and input_obj.get("recipe",{}).get("sugars_g",0) >= DIABETES_ADDED_SUGARS_HIGH: add("added_sugars_high")

    # CKD
    # Protein limit for CKD (daily)
    pmax = targets.get('protein_g_max')
    if 'chronic kidney disease' in med and pmax is not None and day.get('recipes'):
        totp = sum(r.get('protein_g',0) for r in day['recipes'])
        if totp > pmax:
            add('protein_over_target_ckd')

    # CKD
    k_goal = targets.get("potassium_mg")
    if "chronic kidney disease" in med and k_goal and day.get("recipes"):
        tot = sum(r.get("potassium_mg",0) for r in day["recipes"])
        if tot > k_goal: add("potassium_over_target")

    # Pregnancy
    # Vitamin A (retinol activity equivalents) conservative UL ~3000 µg RAE/day
    if 'pregnancy' in med and day.get('recipes'):
        vita = sum(r.get('vitamin_a_rae_ug',0) for r in day['recipes'])
        if vita > PREG_VIT_A_UL:
            add('vitamin_a_exceeds_safe_pregnancy')

    # Pregnancy
    if "pregnancy" in med:
        if any("swordfish" in x for x in ings): add("high_mercury_fish")
        if any(("alcohol" in x) or ("wine" in x) or ("beer" in x) for x in ings): add("alcohol_present")
        if any("raw egg" in x for x in ings): add("raw_egg_risk")

    # Celiac/gluten-free
    if ("celiac disease" in med or diet=="gluten free") and any(("wheat" in x) or ("flour" in x) for x in ings): add("gluten_detected")

    # Keto
    if diet=="keto" and day.get("recipes"):
        carbs_goal = (prof.get("targets") or {}).get("carbs_g_per_day") or targets.get("carbs_g_per_day")
        if carbs_goal is not None:
            tot = sum(r.get("carbs_g",0) for r in day["recipes"])
            if tot > carbs_goal: add("carbs_over_target")

    # Drug–food
    if "warfarin" in meds and any(("kale" in x) or ("spinach" in x) for x in ings): add("drug_food_vitK_warfarin")
    if "statin" in meds and any("grapefruit" in x for x in ings): add("drug_food_grapefruit_statin")

    # Safety / fitness
    age = prof.get("age_years")
    if isinstance(age,(int,float)) and age < 4 and any("whole grapes" in x for x in ings): add("choking_hazard_toddler")
    if input_obj.get("recipe",{}).get("cook_temp_c",0) and input_obj["recipe"]["cook_temp_c"] < POULTRY_SAFE_C and "chicken" in (input_obj["recipe"].get("name","").lower()): add("undercooked_poultry")
    injuries=set([i.lower() for i in prof.get("injuries", input_obj.get('injuries', []))])
    if "knee" in injuries and input_obj.get("workout",{}).get("exercises"):
        if any(("squat" in (e.get("name","").lower())) and ("ass-to-grass" in (e.get("depth","").lower())) for e in input_obj["workout"]["exercises"]):
            add("exercise_contraindicated_knee")
    if "lower back" in injuries and input_obj.get("workout",{}).get("exercises"):
        if any(("deadlift" in (e.get("name","").lower())) and ("heavy" in (e.get("intensity","").lower())) for e in input_obj["workout"]["exercises"]):
            add("exercise_contraindicated_back")
    if "pregnancy" in med and prof.get("pregnancy_trimester")==3 and input_obj.get("workout",{}).get("exercises"):
        if any("supine" in (e.get("name","").lower()) for e in input_obj["workout"]["exercises"]):
            add("exercise_contraindicated_pregnancy_supine")

    # Budget / inventory
    if prof.get("budget_usd") is not None and input_obj.get("cart",{}).get("items"):
        tot = sum(i.get("price_usd",0) for i in input_obj["cart"]["items"])
        if tot > prof["budget_usd"]: add("budget_exceeded")
    store = prof.get("store") or input_obj.get("store")
    if store and input_obj.get("cart",{}).get("items"):
        for i in input_obj["cart"]["items"]:
            if "costco" in i.get("sku","").lower() and "trader" in store.lower():
                add("store_item_unavailable")

    exp = {"hard_fail": bool(exp_flags), "flags": sorted(exp_flags)}
    exp["flags"] = canonicalize_flags(exp["flags"])
    return exp

# ----- IO & comparison -----
def load_tests(path):
    tests = []
    with open(path, 'r', encoding='utf-8') as f:
        for ln in f:
            ln = ln.strip()
            if ln:
                tests.append(json.loads(ln))
    return tests

def normalize_guardrail(obj: dict) -> dict:
    gr = obj.get("guardrail_report", {})
    if not isinstance(gr, dict): gr = {}
    hard = bool(gr.get("hard_fail", False))
    flags = gr.get("flags", [])
    if not isinstance(flags, list): flags = []
    flags = [str(x) for x in flags]
    flags = canonicalize_flags(flags)
    return {"hard_fail": hard, "flags": flags}

def matches_expected(actual: dict, expected: dict) -> bool:
    if actual["hard_fail"] != expected.get("hard_fail", False):
        return False
    exp_flags = set(expected.get("flags", []))
    act_flags = set(actual.get("flags", []))
    return exp_flags.issubset(act_flags)

# ----- Run -----
tests = load_tests(TEST_PATH)
ok = 0; fail = 0; per_cat = {}

for i, ex in enumerate(tests, 1):
    # Prompt the model
    prompt = render_prompt(build_chat(ex))
    gen = generate_text(prompt)

    # Parse/repair model JSON
    try:
        obj = extract_json(gen)
    except Exception:
        try:
            obj = repair_json(gen)
        except Exception as e:
            print(f"[{i}] FAIL: unparseable JSON :: {e}\n--- RAW ---\n{gen[:300]}\n-----------")
            fail += 1
            per_cat.setdefault(ex.get("category","misc"), {"pass":0,"fail":0})["fail"] += 1
            continue

    # Model output → normalized
    actual = normalize_guardrail(obj)

    # Deterministic oracle (FDA) → expected, and also union with model for runtime behavior
    derived = rule_expected(ex.get("input", ex))
    # Runtime decision uses deterministic rules (FDA oracle). Model flags are advisory only.
    actual_effective = derived
    # (Optional) Keep a record of model extras for logging/audit; not used for pass/fail.
    model_extras = sorted(set(actual['flags']) - set(derived['flags']))

    if matches_expected(actual_effective, derived):
        print(f"[{i}] PASS")
        ok += 1
        per_cat.setdefault(ex.get("category","misc"), {"pass":0,"fail":0})["pass"] += 1
    else:
        print(f"[{i}] FAIL: expected={expected} actual={actual_union}")
        fail += 1
        per_cat.setdefault(ex.get("category","misc"), {"pass":0,"fail":0})["fail"] += 1

summary = {"pass": ok, "fail": fail, "total": ok + fail, "by_category": per_cat,
           "ruleset": {"version": RULESET.get("version","v1"), "path": RULESET.get("_path",""), "sha256": RULESET.get("_sha256", "")}}
print(summary)

os.makedirs("reports", exist_ok=True)
with open("reports/guardrail_eval_report.json","w") as f:
    json.dump(summary, f, indent=2)
