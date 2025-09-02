import { buildShoppingList } from "../../src/plans/nutrition/shopping";
import meals from "../fixtures/mealplan.sample.json";

test("pantry removal, retailer tag, substitutions", () => {
  const out = buildShoppingList((meals as any).dailyMeals, [], "trader_joes", true);
  expect(out.find(i => i.item.toLowerCase().includes("basmati"))).toBeUndefined();
  expect(out.find(i => i.item.toLowerCase().includes("jasmine"))?.preferredRetailer).toBe("trader_joes");
  expect(out.find(i => i.item.toLowerCase().includes("yogurt"))?.substitution).toBe("plain yogurt");
});
