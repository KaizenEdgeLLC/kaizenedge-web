export function pickExercises(equipment: string[] = []): string[] {
  // TODO: return equipment-aware set (see docs/workpackets/LLAMA.md)
  return ["Squat","Push-up","Row","Hip Hinge"];
}
export function progression(prev: "too_easy"|"just_right"|"too_hard") {
  // TODO: implement logic per spec
  return { setsDelta: 0, cue: "hold" };
}
