# LLAMA — 10h Packet (Phase 1/1.1 safe)

## L1) Workout templates (equipment-aware)
- Add simple template map keyed by equipment: none, dumbbells, kettlebell, barbell, machines.
- Function: `pickExercises(equipment: string[]): string[]`
- Acceptance:
  - Always returns ≥4 unique exercises.
  - If `none` only → bodyweight variants (squat, push-up, row/inverted, hip hinge).
  - Knee injury present → exclude plyometrics & deep lunges.

## L2) Intensity progression stub
- Function: `progression(prev: "too_easy"|"just_right"|"too_hard"): { setsDelta: number; cue: string }`
- Acceptance:
  - too_easy → sets +1, cue “increase load or reps”
  - just_right → sets +0
  - too_hard → sets −1 (min 1), cue “reduce load / rest longer”

## L3) Builder integration
- Wire L1/L2 into `buildWorkouts` without changing external shape.
- Acceptance: contract test still green; add a snapshot of one generated day.

> All new tests should be `test.todo` until you’ve implemented each step, then flip to `test(...)`.
