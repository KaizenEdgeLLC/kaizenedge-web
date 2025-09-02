# DEEP — 10h Packet (Phase 1/1.1 safe)

## D1) Recipe annotator (diabetes/laws/allergens aware, non-clinical)
- Function: `annotateMeal(meal, ctx) -> { tags: string[] }`
- Source fields:
  - ctx.nutrition.diabetesSupport (carb cap only as a tag, *no advice*),
  - ctx.nutrition.dietaryLaws (tag compliance),
  - ctx.nutrition.allergens (tag risk if present).
- Acceptance:
  - Adds tags like: `carb_cap_45g`, `law_halal_ok`, `allergen_risk_gluten`.

## D2) Shopping list noun-normalizer
- Normalize ingredient names (lowercase, replace `_` with space).
- Acceptance:
  - "Greek_yogurt" → "greek yogurt"
  - Idempotent; unit tests show before/after.

## D3) Signed report assembler (JSON only)
- Function: `assembleMealReport(input, annotations) -> signed JSON`
- Acceptance:
  - Includes `version`, `issuedAt`, `exclusionsApplied`, and a dummy `signature: "DEMO-LOCAL"`.
  - Deterministic snapshot.

> Keep all tests as `test.todo` until each step is implemented.
