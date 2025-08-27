# KaizenEdge All-in-One Orchestrator (AOO) — v1
Generated: 2025-08-26 18:11:03

## Goal
Single conversational unit that acts as: personal recipe creator, meal planner, fitness instructor, grocery-list builder, and shopping assistant — always enforcing guardrails and backed by FDA/USDA sources (Phase 1 Lifestyle; Phase 2 FDA SaMD).

## Top-Level Flow (Always-On Guardrails Pipeline — AOGP)
1. **Profile Normalize** → Parse user inputs (allergens, diets, medical conditions, physical ability, age/life stage, culture, budget, retailers, pantry).
2. **Retrieve Knowledge** → USDA FoodData Central (nutrients), standards from MKD v1.2 (guardrails), retailer catalogs (availability).
3. **Constraint Builder**
   - Hard: allergens, celiac, religious diets, medical thresholds, physical limits, age/life stage safety.
   - Soft: budget, brand preferences, sustainability, flavor prefs.
   - Objectives: taste satisfaction, macro targets, cost, cultural authenticity.
4. **Plan Proposals**
   - Recipe Candidates (n≥3 per meal) using food-science heuristics + cultural tags.
   - Workout Block (if requested) respecting ability & schedule.
   - Grocery Candidates mapped to retailer SKUs.
5. **Validation Loop (Fail-Closed)**
   - Compute nutrition from FDC, check medical thresholds.
   - Allergen/Religious exclusion verification.
   - Physical ability checks for workouts (no unsafe drills).
   - Inventory/Price check; propose safe substitutions when needed.
   - If any hard constraint fails → fix & revalidate; otherwise produce **Guardrail Report**.
6. **Explain & Log**
   - Generate user-facing explanation (why chosen, cultural notes, substitutions).
   - Summarize guardrail decisions (what was excluded/adjusted).
   - Log minimal reasoning for QMS audit (Phase 2).

## Internal Modules (can be separate services, presented as one unit)
- M0 Orchestrator: coordinates steps, merges outputs
- M1 Profile Normalizer: builds normalized profile JSON
- M2 Nutrition Planner: sets macro targets per user (and condition)
- M3 Recipe Generator: original, style-based recipes
- M4 Workout Planner: ability-aware programs
- M5 Grocery Mapper: ingredient→SKU conversion + OOS substitutions
- M6 Cart Builder: consolidates items across meals
- M7 Guardrail Validator: rules engine + calculators
- M8 Explainer/Labeler: user explanations, labels, disclaimers
- M9 Evidence Logger: stores traces & reports for Phase 2

## Food-Science Knowledge (heuristics used)
- Cooking loss/retention factors applied to protein, fat, sodium when relevant
- Portion scaling + satiety balance across meals
- Glycemic load approximations for diabetes plans
- Sodium/added sugar caps for hypertension/heart-health
- Protein timing for strength days; carb periodization for endurance

## FDA / Lifestyle Positioning
- Phase 1: Lifestyle-only wording; disclaimers; no diagnostic/therapeutic claims.
- Phase 2: Same pipeline; add QMS, clinical validation, Safety Case; update labeling.

## Output Contract (high level)
- MealPlan, Recipes, GroceryCart, WorkoutPlan, GuardrailReport, Rationale, Disclaimers

