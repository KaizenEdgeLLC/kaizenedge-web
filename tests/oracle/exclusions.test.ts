import { computeDietaryExclusions } from "../../src/oracle/exclusions";

test("dedup and stable ordering", () => {
  const out = computeDietaryExclusions({
    userProfile: { age: 30, heightCm: 170, weightKg: 70, medications: ["lisinopril"] },
    goals: { primary: "strength" },
    timeFrequency: { minutesPerSession: 45, daysPerWeek: 4 },
    nutrition: { allergens: ["peanut","peanut"], dietaryLaws: ["halal"], foodAvoidances: ["alcohol","alcohol"] }
  } as any);
  expect(out).toContain("medications:present");
  expect(out.filter((x, i, a) => a.indexOf(x) === i).length).toBe(out.length); // deduped
});
