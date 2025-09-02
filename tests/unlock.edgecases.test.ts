import { assertOnboarding } from "../src/validators/validator";
import { computeUnlocks } from "../src/validators/unlock";
import type { FitnessOnboarding } from "../types/types";

const base: FitnessOnboarding = {
  meta: { version: "1.2.0" },
  userProfile: { age: 28, heightCm: 175, weightKg: 74 },
  goals: { primary: "strength", targetTimelineDays: 120 },
  environment: { trainingLocation: "home" }, // <- minimal to satisfy schema
  timeFrequency: { minutesPerSession: 45, daysPerWeek: 5, intensityPreference: "high" },
  nutrition: { culturalFlavors: ["japan"], snackStyle: "gamer_snacks", timingStyle: "night_owl" },
  behavior: { gamificationOptIn: true }
};

test("low frequency removes freq_4plus", () => {
  const data = assertOnboarding({ ...base, timeFrequency: { ...base.timeFrequency, daysPerWeek: 2 } });
  const u = computeUnlocks(data);
  expect(u.flags?.includes("freq_4plus")).toBe(false);
});

test("no devices -> no tech_biofeedback_interest", () => {
  const data = assertOnboarding({ ...base, integrations: { devices: ["none"] } });
  const u = computeUnlocks(data);
  expect(u.flags?.includes("tech_biofeedback_interest")).toBe(false);
});

test("remove JP/KR flavor -> drops flavor flag", () => {
  const data = assertOnboarding({ ...base, nutrition: { ...base.nutrition, culturalFlavors: ["mexico"] } });
  const u = computeUnlocks(data);
  expect(u.flags?.includes("flavor_japan_or_korea")).toBe(false);
});
