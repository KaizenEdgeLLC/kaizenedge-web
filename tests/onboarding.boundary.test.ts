/**
 * VERIFIES: SRS-001 — userProfile.age MUST be 13..100 inclusive
 * PURPOSE: Hard boundary verification to complement fuzz/property tests.
 */
import { assertOnboarding } from "../src/validators/validator";
import type { FitnessOnboarding } from "../types/types";

// Known-good BASE payload (matches your schema & the passing fuzz test)
const BASE: FitnessOnboarding = {
  meta: { version: "1.2.0", timestamp: new Date().toISOString(), source: "ios" },
  userProfile: {
    age: 35,
    heightCm: 178,
    weightKg: 86,
    biologicalSex: "unspecified",
    conditions: ["injuries"],
    injuries: ["knee"],
    medicalClearance: "self-cleared",
    medications: ["Lisinopril"]
  },
  goals: { primary: "strength", secondary: ["mobility"], targetTimelineDays: 120 },
  environment: {
    trainingLocation: "hybrid",
    equipment: ["dumbbells", "yoga_mat"],
    stylePreferences: ["calisthenics", "hiit", "yoga"],
    culturalTags: ["brazil_capoeira", "india_yoga"]
  },
  timeFrequency: {
    minutesPerSession: 45,
    daysPerWeek: 5,
    restStrategy: "auto",
    intensityPreference: "high",
    impactLevel: "medium"
  },
  nutrition: {
    dietaryPattern: "omnivore",
    culturalFlavors: ["korea", "japan"],
    snackStyle: "gamer_snacks",
    proteinTargetGPerDay: 150,
    calorieTargetKcalPerDay: 2600,
    allergens: ["peanut", "gluten"],
    diabetesSupport: { type: "type2", carbLimitPerMealG: 45, preferLowGI: true },
    dietaryLaws: ["halal"],
    foodAvoidances: ["pork", "alcohol"]
  }
};

describe("SRS-001 age boundaries", () => {
  test("age = 13 (lower bound) passes", () => {
    const p: FitnessOnboarding = { ...BASE, userProfile: { ...BASE.userProfile, age: 13 } };
    expect(() => assertOnboarding(p)).not.toThrow();
  });

  test("age = 100 (upper bound) passes", () => {
    const p: FitnessOnboarding = { ...BASE, userProfile: { ...BASE.userProfile, age: 100 } };
    expect(() => assertOnboarding(p)).not.toThrow();
  });

  test("age = 12 (below lower bound) fails", () => {
    const p: FitnessOnboarding = { ...BASE, userProfile: { ...BASE.userProfile, age: 12 } };
    expect(() => assertOnboarding(p)).toThrow();
  });

  test("age = 101 (above upper bound) fails", () => {
    const p: FitnessOnboarding = { ...BASE, userProfile: { ...BASE.userProfile, age: 101 } };
    expect(() => assertOnboarding(p)).toThrow();
  });
});
