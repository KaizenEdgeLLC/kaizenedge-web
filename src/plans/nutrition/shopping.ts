type Ingredient = { item: string; qty: string };
type Meal = { name: string; ingredients?: Ingredient[] };
export type ShoppingLine = { item: string; quantity: string; preferredRetailer?: string; substitution?: string };

const SUBS: Record<string,string> = { basmati: "jasmine rice", greek_yogurt: "plain yogurt" };

export function buildShoppingList(
  meals: Meal[],
  pantry: string[] = [],
  retailer?: string,
  allowSubs = false
): ShoppingLine[] {
  const lines: Record<string, ShoppingLine> = {};
  const pantrySet = new Set(pantry.map(p => p.toLowerCase()));
  for (const meal of meals) {
    for (const ing of meal.ingredients ?? []) {
      const key = ing.item.toLowerCase();
      if (pantrySet.has(key)) continue;
      const substitution = allowSubs && SUBS[key] ? SUBS[key] : undefined;
      const item = substitution ?? ing.item;
      const k = item.toLowerCase();
      if (!lines[k]) {
        lines[k] = { item, quantity: ing.qty, preferredRetailer: retailer, substitution };
      } else {
        lines[k].quantity = `${lines[k].quantity} + ${ing.qty}`;
      }
    }
  }
  return Object.values(lines);
}
