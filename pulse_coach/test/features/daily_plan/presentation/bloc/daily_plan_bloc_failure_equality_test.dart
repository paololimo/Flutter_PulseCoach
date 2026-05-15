import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';

void main() {
  group('DailyPlanBloc error state equality - BLoC re-emission regression', () {
    test('6.5-EQ-BLOC-001: two consecutive equal CacheFailure emissions coalesce', () {
      // DailyPlanState.error equality is structural: equal failure plus equal
      // retryAttempts stays equal, matching flutter_bloc's duplicate-drop behavior.
      const s1 = DailyPlanState.error(
        failure: CacheFailure('Profile not found'),
        retryAttempts: 0,
      );
      const s2 = DailyPlanState.error(
        failure: CacheFailure('Profile not found'),
        retryAttempts: 0,
      );

      expect(s1, equals(s2));
    });

    test('6.5-EQ-BLOC-002: retry counter increments produce distinct states', () {
      const s1 = DailyPlanState.error(
        failure: CacheFailure('Profile not found'),
        retryAttempts: 1,
      );
      const s2 = DailyPlanState.error(
        failure: CacheFailure('Profile not found'),
        retryAttempts: 2,
      );

      expect(s1, isNot(equals(s2)));
    });

    test('6.5-EQ-BLOC-003: CacheFailure and ServerFailure with same message do not coalesce', () {
      const s1 = DailyPlanState.error(
        failure: CacheFailure('connection failed'),
        retryAttempts: 0,
      );
      const s2 = DailyPlanState.error(
        failure: ServerFailure('connection failed'),
        retryAttempts: 0,
      );

      expect(s1, isNot(equals(s2)));
    });
  });
}
