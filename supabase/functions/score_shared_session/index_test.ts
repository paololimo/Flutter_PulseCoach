import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { computeAward, intensityWeightFor, SHARED_SESSION_MULTIPLIER } from "./index.ts";

Deno.test("[21.3-EDGE-001] computeAward at the live multiplier applies the 1.5x bonus", () => {
  assertEquals(computeAward(20, SHARED_SESSION_MULTIPLIER), 30);
});

Deno.test("[21.3-EDGE-002] computeAward at multiplier 1.0 (kill switch) equals base points, no residual bonus", () => {
  assertEquals(computeAward(20, 1.0), 20);
});

Deno.test("[21.3-EDGE-003] intensityWeightFor mirrors ScoringConstants.intensityWeightFor (Dart)", () => {
  assertEquals(intensityWeightFor("mobility_low"), 1.0);
  assertEquals(intensityWeightFor("mobility_medium"), 1.5);
  assertEquals(intensityWeightFor("mobility_high"), 2.0);
});
