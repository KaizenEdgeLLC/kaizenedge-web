import type { FitnessOnboarding, UnlockEvaluation, UnlockFlag, PremiumTheme } from "../../types/types";

export function computeUnlocks(input: FitnessOnboarding): UnlockEvaluation {
  const flags = new Set<UnlockFlag>();
  const reasons: string[] = [];

  const tf = input.timeFrequency;
  if (tf.daysPerWeek >= 4) { flags.add("freq_4plus"); reasons.push("Trains ≥4 days/week"); }
  if (tf.intensityPreference === "high") { flags.add("intensity_high"); reasons.push("High intensity preference"); }

  const env = input.environment;
  if (env?.stylePreferences?.some(s => s === "martial_arts" || s === "calisthenics")) {
    flags.add("style_martial_or_calisthenics");
    reasons.push("Style preference includes martial arts or calisthenics");
  }

  const goals = input.goals;
  if ((goals.targetTimelineDays ?? 0) >= 90) {
    flags.add("timeline_90plus");
    reasons.push("Target timeline ≥ 90 days");
  }

  const nut = input.nutrition;
  if (nut?.culturalFlavors?.some(f => f === "japan" || f === "korea")) {
    flags.add("flavor_japan_or_korea");
    reasons.push("Cultural flavors include Japan/Korea");
  }
  if (nut?.snackStyle === "gamer_snacks") {
    flags.add("snack_gamer");
    reasons.push("Snack style suggests gamer snacks");
  }
  if (nut?.timingStyle === "night_owl") {
    flags.add("timing_night_owl");
    reasons.push("Night-owl timing");
  }

  const beh = input.behavior;
  if (beh?.gamificationOptIn) {
    flags.add("gamification_on");
    reasons.push("Gamification opt-in enabled");
  }
  const tooEasyCount = beh?.sessionFeedbackHistory?.filter(s => s.perceivedDifficulty === "too_easy").length ?? 0;
  if (tooEasyCount >= 2) {
    flags.add("too_easy_trend");
    reasons.push("Multiple 'too easy' feedback entries");
  }

  if (input.integrations?.devices && input.integrations.devices.some(d => d !== "none")) {
    flags.add("tech_biofeedback_interest");
    reasons.push("Health device integrations connected");
  }

  const flagCount = flags.size;
  const ascensionCandidate = flagCount >= 3;
  const otherCandidates: PremiumTheme[] = [];

  if (input.behavior?.motivationArchetype === "explorer" || env?.trainingLocation === "outdoor") {
    otherCandidates.push("adventure");
  }
  if ((env?.stylePreferences ?? []).includes("yoga") || input.nutrition?.dietaryPattern === "vegetarian" || input.timeFrequency.impactLevel === "low") {
    otherCandidates.push("zen");
  }
  if ((input.integrations?.devices ?? []).some(d => d === "apple_health" || d === "garmin") && (input.integrations?.metricsIngest ?? []).length) {
    otherCandidates.push("cybernetic");
  }

  return {
    flags: Array.from(flags),
    flagCount,
    ascensionCandidate,
    otherCandidates: otherCandidates.filter((v, i, a) => a.indexOf(v) === i && v !== "ascension") as UnlockEvaluation["otherCandidates"],
    unlockReason: reasons
  };
}
