import * as fc from "fast-check";
import { assertOnboarding } from "../../src/validators/validator";
import type { FitnessOnboarding } from "../../types/types";

/**
 * BASE: start from a valid onboarding payload.
 *  - Removed invalid fields ('medicatingBP', 'eatingWindow')
 *  - Fixed typo: targetTimeLineDays -> targetTimelineDays
 */
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

// ---- Constrained arbitraries that match your schema ----
const ageArb     = fc.integer({ min: 13, max: 100 });
const heightArb  = fc.double({ min: 100, max: 230, noNaN: true, noDefaultInfinity: true }); // cm
const weightArb  = fc.double({ min: 25,  max: 350, noNaN: true, noDefaultInfinity: true }); // kg

// minutesPerSession is a union: 10 | 20 | 30 | 45 | 60 | 75 | 90
const minutesValues = [10, 20, 30, 45, 60, 75, 90] as const;
type Minutes = typeof minutesValues[number];
const minutesArb: fc.Arbitrary<Minutes> = fc.constantFrom(...minutesValues);

const daysArb    = fc.integer({ min: 1,  max: 7 });

// ---- Property: only mutate safe numeric fields ----
test("valid payloads pass", () => {
  fc.assert(
    fc.property(ageArb, heightArb, weightArb, minutesArb, daysArb, (age, h, w, mins, days) => {
      const payload: FitnessOnboarding = {
        ...BASE,
        userProfile: { ...BASE.userProfile, age, heightCm: h, weightKg: w },
        timeFrequency: { ...BASE.timeFrequency, minutesPerSession: mins, daysPerWeek: days }
      };
      expect(() => assertOnboarding(payload)).not.toThrow();
    }),
    { numRuns: 100, verbose: true, endOnFailure: true }
  );
});
