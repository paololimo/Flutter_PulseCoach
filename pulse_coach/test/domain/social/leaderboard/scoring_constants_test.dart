import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/scoring_constants.dart';

void main() {
  group('ScoringConstants.intensityWeightFor', () {
    test('21.1-SCORE-001: mobility_low returns 1.0', () {
      expect(ScoringConstants.intensityWeightFor('mobility_low'), 1.0);
    });

    test('21.1-SCORE-002: cardio_medium returns 1.5', () {
      expect(ScoringConstants.intensityWeightFor('cardio_medium'), 1.5);
    });

    test('21.1-SCORE-003: breathing_high returns 2.0', () {
      expect(ScoringConstants.intensityWeightFor('breathing_high'), 2.0);
    });
  });
}
