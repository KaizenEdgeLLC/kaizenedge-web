import { schedulingHints } from "../../src/oracle/scheduling";

test("collects non-binding hints", () => {
  const out = schedulingHints({
    userProfile: { age: 30, heightCm: 170, weightKg: 70 },
    goals: { primary: "strength" },
    timeFrequency: { minutesPerSession: 30, daysPerWeek: 3 },
    observanceConstraints: { consentProvided: true, restDays: ["sat"], scheduleBlackouts: [{ from: "18:00", to: "20:00" }] }
  } as any);
  expect(out.blackout).toContain("18:00-20:00");
  expect(out.restDays).toContain("sat");
});
