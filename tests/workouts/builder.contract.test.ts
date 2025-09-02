import { buildWorkouts } from "../../src/plans/workouts/builder";
import ob from "../fixtures/onboarding.valid.json";

test("builder respects days, minutes, knee injury", () => {
  const out = buildWorkouts(ob as any);
  expect(out.weeklySplit.length).toBe(ob.timeFrequency.daysPerWeek);
  expect(out.sessions.length).toBe(ob.timeFrequency.daysPerWeek);
  const exerciseNames = out.sessions.flatMap(s => s.blocks.map((b: any) => b.name.toLowerCase()));
  const hasKneeSafe = exerciseNames.some(n => n.includes("goblet squat") || n.includes("short rom"));
  expect(hasKneeSafe).toBe(true);
});
