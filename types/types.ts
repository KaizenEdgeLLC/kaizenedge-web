export type BiologicalSex = "female" | "male" | "intersex" | "unspecified";
export type DeviceIntegration = "apple_health" | "google_fit" | "fitbit" | "garmin" | "none";
export type MetricIngest = "heart_rate" | "steps" | "sleep" | "calories_burned";
export type Goal = "strength" | "endurance" | "weight_loss" | "mobility" | "general_fitness" | "rehab";
export type TrainingLocation = "home" | "gym" | "outdoor" | "hybrid";
export type Equipment =
  | "none" | "bands" | "dumbbells" | "kettlebell" | "barbell" | "machines"
  | "treadmill" | "bike" | "rower" | "yoga_mat";
export type StylePreference =
  | "calisthenics" | "weightlifting" | "yoga" | "pilates" | "martial_arts"
  | "cross_training" | "walking_running" | "cycling" | "hiit" | "tai_chi";
export type CulturalEnvTag =
  | "india_yoga" | "brazil_capoeira" | "us_crossfit" | "china_tai_chi" | "japan_karate" | "korea_taekwondo";
export type IntensityPref = "gentle" | "moderate" | "high";
export type ImpactLevel = "low" | "medium" | "high";
export type RestStrategy = "auto" | "user_selected";
export type DietaryPattern =
  | "omnivore" | "vegetarian" | "vegan" | "pescetarian" | "halal" | "kosher"
  | "gluten_free" | "dairy_free" | "other";
export type CulturalFlavor =
  | "japan" | "korea" | "mexico" | "india" | "italy" | "mediterranean"
  | "caribbean" | "brazil" | "china" | "us";
export type TimingStyle = "early_bird" | "standard" | "night_owl";
export type SnackStyle = "minimal" | "balanced" | "gamer_snacks";
export type MotivationArchetype = "self_improver" | "competitor" | "explorer" | "collector" | "unspecified";
export type NotificationStyle = "clinical" | "system_update";
export type Zone = "zone1" | "zone2" | "zone3" | "zone4" | "zone5";
export type UnlockFlag =
  | "freq_4plus" | "intensity_high" | "style_martial_or_calisthenics" | "timeline_90plus"
  | "flavor_japan_or_korea" | "snack_gamer" | "timing_night_owl"
  | "gamification_on" | "too_easy_trend" | "consistency_80_plus"
  | "tech_biofeedback_interest";
export type PremiumTheme = "ascension" | "cybernetic" | "zen" | "hero" | "adventure";

export interface Meta { version: "1.0.0"; timestamp?: string; source?: "ios"|"android"|"web"|"import"; }
export interface UserProfile {
  age: number; heightCm: number; weightKg: number; biologicalSex?: BiologicalSex; restingHrBpm?: number;
  conditions?: string[]; injuries?: ("knee"|"back"|"shoulder"|"wrist"|"ankle"|"other")[]; medicalClearance?: "none"|"self-cleared"|"clinician-cleared"|"rehab-program";
}
export interface Goals { primary: Goal; secondary?: Goal[]; targetTimelineDays?: number; }
export interface Environment { trainingLocation?: TrainingLocation; equipment?: Equipment[]; stylePreferences?: StylePreference[]; culturalTags?: CulturalEnvTag[]; }
export interface TimeFrequency { minutesPerSession: 10|20|30|45|60|75|90; daysPerWeek: number; restStrategy?: RestStrategy; intensityPreference?: IntensityPref; impactLevel?: ImpactLevel; }
export interface Nutrition { dietaryPattern?: DietaryPattern; culturalFlavors?: CulturalFlavor[]; timingStyle?: TimingStyle; snackStyle?: SnackStyle; proteinTargetGPerDay?: number; calorieTargetKcalPerDay?: number; }
export interface Integrations { devices?: DeviceIntegration[]; metricsIngest?: MetricIngest[]; }
export interface SessionFeedback { date: string; perceivedDifficulty: "too_easy"|"just_right"|"too_hard"|"painful"; }
export interface Behavior { motivationArchetype?: MotivationArchetype; gamificationOptIn?: boolean; notificationStyle?: NotificationStyle; streakTargetDays?: number; sessionFeedbackHistory?: SessionFeedback[]; }
export interface Oracle { contraindications?: string[]; clearedZones?: Zone[]; }
export interface UnlockEvaluation { flags?: UnlockFlag[]; flagCount?: number; ascensionCandidate?: boolean; otherCandidates?: Exclude<PremiumTheme,"ascension">[]; unlockReason?: string[]; }
export interface WorkoutBlock { name: string; sets: number; reps: string; restSec?: number; intensity?: string; }
export interface WorkoutSession { day: string; blocks: WorkoutBlock[]; }
export interface SignedReport { indication?: string; rationale?: string; sources?: string[]; version: string; signature?: string; issuedAt: string; }
export interface PlanOutputs {
  workoutPlan?: { weeklySplit?: string[]; sessions?: WorkoutSession[]; signedReport?: SignedReport & { indication: string }; };
  mealPlan?: { dailyMeals?: { name: string; calories: number; proteinG?: number; carbsG?: number; fatG?: number; culturalTag?: string; }[]; signedReport?: SignedReport; };
}
export interface FitnessOnboarding {
  meta?: Meta; userProfile: UserProfile; goals: Goals; environment?: Environment; timeFrequency: TimeFrequency; nutrition?: Nutrition;
  integrations?: Integrations; behavior?: Behavior; oracle?: Oracle; unlockEvaluation?: UnlockEvaluation; planOutputs?: PlanOutputs;
}
