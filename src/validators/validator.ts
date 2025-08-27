import Ajv, { ErrorObject } from "ajv";
import addFormats from "ajv-formats";
import schema from "../../schemas/fitness-onboarding.v1.json";
import type { FitnessOnboarding } from "../../types/types";

const ajv = new Ajv({ strict: true, allErrors: true });
addFormats(ajv);

export const validateOnboarding = ajv.compile<FitnessOnboarding>(schema);

export function assertOnboarding(input: unknown): FitnessOnboarding {
  const ok = validateOnboarding(input);
  if (!ok) {
    const errs = (validateOnboarding.errors ?? []).map(formatAjvError).join("\n");
    throw new Error(`Onboarding payload failed validation:\n${errs}`);
  }
  return input as FitnessOnboarding;
}

function formatAjvError(e: ErrorObject): string {
  const path = e.instancePath && e.instancePath.length ? e.instancePath : "(root)";
  const msg = e.message ?? "";
  const params = e.params ? ` ${JSON.stringify(e.params)}` : "";
  return `• ${path} ${msg}${params}`.trim();
}
