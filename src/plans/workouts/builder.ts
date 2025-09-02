import type { FitnessOnboarding, WorkoutSession } from "../../../types/types";

export function buildWorkouts(input: FitnessOnboarding): { weeklySplit: string[]; sessions: WorkoutSession[] } {
  const days = input.timeFrequency.daysPerWeek;
  const mins = input.timeFrequency.minutesPerSession;
  const injuries = new Set(input.userProfile.injuries ?? []);

  const weeklySplit = Array.from({ length: days }, (_, i) => `Day ${i + 1}`);
  const baseBlocks = [
    { name: "Warm-up", sets: 1, reps: "5-10 min", restSec: 0, intensity: "easy" },
    { name: injuries.has("knee") ? "Goblet Squat (short ROM)" : "Squat", sets: 3, reps: "8-10", restSec: 90 },
    { name: "Push-up", sets: 3, reps: "8-12", restSec: 90 },
    { name: "Row", sets: 3, reps: "8-12", restSec: 90 }
  ];

  const sessions: WorkoutSession[] = weeklySplit.map((day) => ({
    day,
    blocks: [
      ...baseBlocks,
      { name: "Cool-down", sets: 1, reps: `${Math.round(mins * 0.15)} min`, restSec: 0, intensity: "easy" }
    ]
  }));

  return { weeklySplit, sessions };
}
