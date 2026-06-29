// [20.5-TODAY-001..005] suppressSharedSessionCta unit tests
// Tests the protective-state social suppression guard (UX-DR31, Story 20.5).
// suppressSharedSessionCta is @visibleForTesting and accessible from this file.
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';

void main() {
  group('suppressSharedSessionCta (20.5)', () {
    test(
      '[20.5-TODAY-001] atRisk → returns true (CTA suppressed)',
      () {
        expect(suppressSharedSessionCta(BehavioralState.atRisk), isTrue);
      },
    );

    test(
      '[20.5-TODAY-002] recovering → returns true (CTA suppressed)',
      () {
        expect(suppressSharedSessionCta(BehavioralState.recovering), isTrue);
      },
    );

    test(
      '[20.5-TODAY-003] active → returns false (CTA allowed)',
      () {
        expect(suppressSharedSessionCta(BehavioralState.active), isFalse);
      },
    );

    test(
      '[20.5-TODAY-004] fatigued → returns false (CTA allowed)',
      () {
        expect(suppressSharedSessionCta(BehavioralState.fatigued), isFalse);
      },
    );

    // AC3: Epic 21 guard contract — exactly {atRisk, recovering} suppress the CTA.
    // Any new BehavioralState added to the enum MUST be consciously classified here.
    test(
      '[20.5-TODAY-005] exhaustive contract: suppressed states == {atRisk, recovering}',
      () {
        final suppressed = BehavioralState.values
            .where(suppressSharedSessionCta)
            .toSet();
        expect(
          suppressed,
          equals({BehavioralState.atRisk, BehavioralState.recovering}),
        );
      },
    );
  });
}
