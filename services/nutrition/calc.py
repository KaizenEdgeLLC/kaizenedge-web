# Deterministic roll-up: ingredient -> recipe -> day plan
def sum_nutrients(ingredients):
    keys=set().union(*[i["nutrients"].keys() for i in ingredients]) if ingredients else set()
    return {k: round(sum(i["nutrients"].get(k,0) for i in ingredients),2) for k in keys}
def enforce_thresholds(totals, limits):
    violations = {k: totals.get(k,0) for k,v in limits.items() if totals.get(k,0) > v}
    return {"violations": violations, "hard_fail": bool(violations)}
