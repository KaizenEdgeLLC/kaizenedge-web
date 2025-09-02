import type { FitnessOnboarding } from "../../types/types";

export function computeDietaryExclusions(input: FitnessOnboarding): string[] {
  const set = new Set<string>();
  (input.nutrition?.allergens ?? []).forEach((a: string) => set.add(`allergen:${a}`));
  (input.nutrition?.dietaryLaws ?? []).forEach((l: string) => set.add(`law:${l}`));
  (input.nutrition?.foodAvoidances ?? []).forEach((x: string) => set.add(`avoid:${x}`));
  if ((input.userProfile.medications ?? []).length) set.add("medications:present");
  return Array.from(set).sort();
}
