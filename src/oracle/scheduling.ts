import type { FitnessOnboarding } from "../../types/types";

export function schedulingHints(input: FitnessOnboarding) {
  const o = input.observanceConstraints;
  if (!o) return { blackout: [] as string[], restDays: [] as string[], fasting: [] as string[] };
  const blackout = (o.scheduleBlackouts ?? []).map((b: {from:string;to:string}) => `${b.from}-${b.to}`);
  const restDays = o.restDays ?? [];
  const fasting = (o.fastingWindows ?? []).map((f: {daylightOnly?:boolean}) => f.daylightOnly ? "daylight" : "time-bounded");
  return { blackout, restDays, fasting };
}
