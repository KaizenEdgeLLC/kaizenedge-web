import { assertOnboarding } from "../src/validators/validator";
import { computeUnlocks } from "../src/validators/unlock";
import type { FitnessOnboarding } from "../types/types";

const payload: FitnessOnboarding = {
  meta: { version: "1.0.0", timestamp: new Date().toISOString(), source: "ios" },
  userProfile: {
    age: 35, heightCm: 178, weightKg: 86,
    biologicalSex: "unspecified",
    restingHrBpm: 58,
    conditions: [], injuries: ["knee"],
    medicalClearance: "self-cleared"
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
    calorieTargetKcalPerDay: 2600
  },
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
  }
};

describe("KaizenEdge Fitness Onboarding — validation & unlocks", () => {
  test("validates and computes unlocks deterministically", () => {
    const data = assertOnboarding(payload);
    const unlocks = computeUnlocks(data);

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

    expect(unlocks).toMatchSnapshot();
  });

  test("invalid payload fails validation", () => {
    const bad: any = { meta: { version: "1.0.0" } };
    expect(() => assertOnboarding(bad)).toThrow(/Onboarding payload failed validation/);
  });
});
