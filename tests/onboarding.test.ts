import { assertOnboarding } from "../src/validators/validator";
import { computeUnlocks } from "../src/validators/unlock";
import type { FitnessOnboarding } from "../types/types";

const payload: FitnessOnboarding = {
  meta: { version: "1.2.0", timestamp: new Date().toISOString(), source: "ios" },
  userProfile: {
    age: 35, heightCm: 178, weightKg: 86,
    biologicalSex: "unspecified",
    restingHrBpm: 58,
    conditions: [],
    injuries: ["knee"],
    medicalClearance: "self-cleared",
    medications: ["lisinopril"]
  },
  goals: { primary: "strength", secondary: ["mobility"], targetTimelineDays: 120 },
  environment: {
    trainingLocation: "hybrid",
    equipment: ["dumbbells", "yoga_mat"],
    stylePreferences: ["calisthenics", "hiit", "yoga"],
    culturalTags: ["brazil_capoeira", "india_yoga"]
  },
  timeFrequency: {
    minutesPerSession: 45, daysPerWeek: 5,
    restStrategy: "auto", intensityPreference: "high", impactLevel: "medium"
  },
  nutrition: {
    dietaryPattern: "omnivore",
    culturalFlavors: ["korea", "japan"],
    timingStyle: "night_owl",
    snackStyle: "gamer_snacks",
    proteinTargetGPerDay: 150,
    calorieTargetKcalPerDay: 2600,
    allergens: ["peanut", "gluten"],
    diabetesSupport: { type: "type2", carbLimitPerMealG: 45, preferLowGI: true },
    dietaryLaws: ["halal"],
    foodAvoidances: ["pork", "alcohol"]
  },
  cookingProfile: { chefStyle: "quick", maxPrepMinutes: 25, appliances: ["stove", "microwave"] },
  pantryAndShopping: { pantryItems: ["brown rice", "olive oil"], preferredRetailers: ["trader_joes"], allowSubstitutions: true },
  localization: { country: "US", region: "NY", seasonalityPreference: "prefer_in_season" },
  integrations: { devices: ["apple_health"], metricsIngest: ["heart_rate", "sleep", "steps"] },
  behavior: {
    motivationArchetype: "competitor",
    gamificationOptIn: true,
    notificationStyle: "system_update",
    streakTargetDays: 30,
    sessionFeedbackHistory: [
      { date: "2025-08-20", perceivedDifficulty: "too_easy" },
      { date: "2025-08-22", perceivedDifficulty: "just_right" },
      { date: "2025-08-24", perceivedDifficulty: "too_easy" }
    ]
  },
  observanceConstraints: { consentProvided: true, restDays: ["sat"], scheduleBlackouts: [{ from: "18:00", to: "20:00" }] }
};

describe("KaizenEdge Fitness Onboarding — validation & unlocks", () => {
  test("validates and computes unlocks deterministically", () => {
    const data = assertOnboarding(payload);
    const unlocks = computeUnlocks(data);

    // New v1.2.0 fields present
    expect(data.userProfile.medications).toEqual(expect.arrayContaining(["lisinopril"]));
    expect(data.nutrition?.allergens).toEqual(expect.arrayContaining(["peanut", "gluten"]));
    expect(data.nutrition?.dietaryLaws).toEqual(expect.arrayContaining(["halal"]));
    expect(data.cookingProfile?.chefStyle).toBe("quick");
    expect(data.pantryAndShopping?.preferredRetailers).toEqual(expect.arrayContaining(["trader_joes"]));
    expect(data.observanceConstraints?.consentProvided).toBe(true);

    // Unlock basics still deterministic
    expect(unlocks.flagCount).toBeGreaterThanOrEqual(3);
    expect(unlocks.flags).toEqual(
      expect.arrayContaining([
        "freq_4plus",
        "intensity_high",
        "style_martial_or_calisthenics",
        "flavor_japan_or_korea",
        "timing_night_owl",
        "snack_gamer",
        "gamification_on",
        "too_easy_trend",
        "tech_biofeedback_interest"
      ])
    );
    expect(unlocks.ascensionCandidate).toBe(true);
    expect(unlocks.unlockReason && unlocks.unlockReason.length).toBeGreaterThan(0);

    // Snapshot for FDA-grade determinism
    expect(unlocks).toMatchSnapshot();
  });

  test("invalid payload fails validation", () => {
    const bad: any = { meta: { version: "1.2.0" } };
    expect(() => assertOnboarding(bad)).toThrow(/Onboarding payload failed validation/);
  });
});
