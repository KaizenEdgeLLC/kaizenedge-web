type Meal = { name: string; carbsG?: number; ingredients?: { item: string; qty?: string }[] };
type Ctx = { nutrition?: { diabetesSupport?: { carbLimitPerMealG?: number; type?: string }, dietaryLaws?: string[], allergens?: string[] } };
export function annotateMeal(meal: Meal, ctx: Ctx) {
  // TODO: add tags based on ctx (non-clinical)
  return { tags: [] as string[] };
}
export function normalizeIngredientName(s: string): string {
  // TODO: noun normalizer: lowercase + underscores -> spaces
  return s;
}
