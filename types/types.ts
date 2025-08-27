// types.ts — KaizenEdge Fitness & Nutrition Onboarding v1.2.0

export type BiologicalSex = "female" | "male" | "intersex" | "unspecified";
export type DeviceIntegration = "apple_health" | "google_fit" | "fitbit" | "garmin" | "cgm" | "none";
export type MetricIngest = "heart_rate" | "steps" | "sleep" | "calories_burned" | "glucose";
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
  | "gluten_free" | "dairy_free" | "low_fodmap" | "other";
export type CulturalFlavor =
  | "japan" | "korea" | "mexico" | "india" | "italy" | "mediterranean"
  | "caribbean" | "brazil" | "china" | "us" | "middle_east" | "thai" | "vietnam";
export type DietaryLaw = "halal" | "kosher" | "jain" | "sattvic" | "buddhist_veg" | "ital_rastafarian";
export type Allergen =
  | "peanut" | "tree_nut" | "milk" | "egg" | "wheat" | "soy" | "fish" | "shellfish" | "sesame" | "gluten" | "sulfites" | "other";

export type TimingStyle = "early_bird" | "standard" | "night_owl";
export type SnackStyle = "minimal" | "balanced" | "gamer_snacks";

export type ChefStyle = "quick" | "gourmet" | "batch" | "one_pot" | "grill" | "minimal_cleanup";
export type SkillLevel = "novice" | "intermediate" | "advanced";

export type MotivationArchetype = "self_improver" | "competitor" | "explorer" | "collector" | "unspecified";
export type NotificationStyle = "clinical" | "system_update";

export type Zone = "zone1" | "zone2" | "zone3" | "zone4" | "zone5";

export type UnlockFlag =
  | "freq_4plus" | "intensity_high" | "style_martial_or_calisthenics" | "timeline_90plus"
  | "flavor_japan_or_korea" | "snack_gamer" | "timing_night_owl"
  | "gamification_on" | "too_easy_trend" | "consistency_80_plus"
  | "tech_biofeedback_interest";

export type PremiumTheme = "ascension" | "cybernetic" | "zen" | "hero" | "adventure";

export interface Meta {
  version: "1.2.0";
  timestamp?: string;
  source?: "ios" | "android" | "web" | "import";
}

export interface UserProfile {
  age: number;
  heightCm: number;
  weightKg: number;
  biologicalSex?: BiologicalSex;
  restingHrBpm?: number;
  conditions?: string[];
  injuries?: ("knee" | "back" | "shoulder" | "wrist" | "ankle" | "other")[];
  medicalClearance?: "none" | "self-cleared" | "clinician-cleared" | "rehab-program";
  medications?: string[];
}

export interface Goals {
  primary: Goal;
  secondary?: Goal[];
  targetTimelineDays?: number;
}

export interface Environment {
  trainingLocation?: TrainingLocation;
  equipment?: Equipment[];
  stylePreferences?: StylePreference[];
  culturalTags?: CulturalEnvTag[];
}

export interface TimeFrequency {
  minutesPerSession: 10 | 20 | 30 | 45 | 60 | 75 | 90;
  daysPerWeek: number;
  restStrategy?: RestStrategy;
  intensityPreference?: IntensityPref;
  impactLevel?: ImpactLevel;
}

export interface Nutrition {
  dietaryPattern?: DietaryPattern;
  dietaryLaws?: DietaryLaw[];
  culturalFlavors?: CulturalFlavor[];
  timingStyle?: TimingStyle;
  snackStyle?: SnackStyle;
  proteinTargetGPerDay?: number;
  calorieTargetKcalPerDay?: number;
  allergens?: Allergen[];
  foodAvoidances?: string[];
  diabetesSupport?: {
    type?: "none" | "type1" | "type2" | "gestational" | "unspecified";
    carbLimitPerMealG?: number;
    preferLowGI?: boolean;
  };
}

export interface CookingProfile {
  chefStyle?: ChefStyle;
  skillLevel?: SkillLevel;
  maxPrepMinutes?: number;
  budgetPerMealUSD?: number;
  spiceTolerance?: "mild" | "medium" | "hot";
  appliances?: ("stove" | "oven" | "microwave" | "air_fryer" | "slow_cooker" | "pressure_cooker" | "grill" | "blender")[];
}

export interface PantryAndShopping {
  pantryItems?: string[];
  preferredRetailers?: ("whole_foods" | "trader_joes" | "kroger" | "walmart" | "costco" | "aldi" | "amazon_fresh" | "instacart" | "local_other")[];
  storeZip?: string;
  allowSubstitutions?: boolean;
}

export interface Localization {
  country?: string;
  region?: string;
  seasonalityPreference?: "in_season_only" | "prefer_in_season" | "no_preference";
}

export interface Integrations {
  devices?: DeviceIntegration[];
  metricsIngest?: MetricIngest[];
}

export interface SessionFeedback {
  date: string;
  perceivedDifficulty: "too_easy" | "just_right" | "too_hard" | "painful";
}

export interface Behavior {
  motivationArchetype?: MotivationArchetype;
  gamificationOptIn?: boolean;
  notificationStyle?: NotificationStyle;
  streakTargetDays?: number;
  sessionFeedbackHistory?: SessionFeedback[];
}

export interface ObservanceConstraints {
  consentProvided?: boolean;
  fastingWindows?: { startDate: string; endDate: string; daylightOnly?: boolean }[];
  restDays?: ("sun"|"mon"|"tue"|"wed"|"thu"|"fri"|"sat")[];
  scheduleBlackouts?: { from: string; to: string }[];
  modestyConstraints?: "none" | "prefer_gender_separate" | "home_only";
}

export interface Oracle {
  contraindications?: string[];
  clearedZones?: Zone[];
  dietaryExclusions?: string[];
  schedulingExclusions?: string[];
  criticalAlerts?: string[];
}

export interface UnlockEvaluation {
  flags?: UnlockFlag[];
  flagCount?: number;
  ascensionCandidate?: boolean;
  otherCandidates?: Exclude<PremiumTheme, "ascension">[];
  unlockReason?: string[];
}

export interface WorkoutBlock {
  name: string;
  sets: number;
  reps: string;
  restSec?: number;
  intensity?: string;
}
export interface WorkoutSession { day: string; blocks: WorkoutBlock[]; }

export interface SignedReport {
  indication?: string;
  rationale?: string;
  sources?: string[];
  version: string;
  signature?: string;
  issuedAt: string;
  exclusionsApplied?: string[];
}

export interface PlanOutputs {
  workoutPlan?: {
    weeklySplit?: string[];
    sessions?: WorkoutSession[];
    signedReport?: SignedReport & { indication: string };
  };
  mealPlan?: {
    dailyMeals?: {
      name: string;
      calories: number;
      proteinG?: number;
      carbsG?: number;
      fatG?: number;
      culturalTag?: string;
    }[];
    shoppingList?: { item: string; quantity: string; preferredRetailer?: string; substitution?: string }[];
    signedReport?: SignedReport;
  };
}

export interface FitnessOnboarding {
  meta?: Meta;
  userProfile: UserProfile;
  goals: Goals;
  environment?: Environment;
  timeFrequency: TimeFrequency;
  nutrition?: Nutrition;
  cookingProfile?: CookingProfile;
  pantryAndShopping?: PantryAndShopping;
  localization?: Localization;
  integrations?: Integrations;
  behavior?: Behavior;
  observanceConstraints?: ObservanceConstraints;
  oracle?: Oracle;
  unlockEvaluation?: UnlockEvaluation;
  planOutputs?: PlanOutputs;
}
