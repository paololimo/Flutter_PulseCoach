import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_step_generator.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

const _testSession = PlannedSession(
  sessionType: 'cardio',
  intensity: 5,
  durationMinutes: 5,
  isIndoor: true,
);

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  home: child,
);

Future<List<ExerciseStep>> _generate(
  WidgetTester tester,
  PlannedSession? session,
) async {
  late List<ExerciseStep> steps;
  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) {
          steps = SessionStepGenerator.generate(
            session,
            AppLocalizations.of(context)!,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();
  return steps;
}

void main() {
  group('SessionStepGenerator', () {
    testWidgets('8.2-UNIT-001: 5-minute session generates 3 steps', (
      tester,
    ) async {
      final steps = await _generate(tester, _testSession);
      final totalSeconds = steps.fold<int>(
        0,
        (sum, step) => sum + step.durationSeconds,
      );

      expect(steps, hasLength(3));
      expect(totalSeconds, 300);
    });

    testWidgets('8.2-UNIT-002: phases respect minimum and warm/cool share', (
      tester,
    ) async {
      final steps = await _generate(tester, _testSession);
      final warmup = steps[0].durationSeconds;
      final cooldown = steps[2].durationSeconds;

      expect(steps.every((step) => step.durationSeconds >= 60), isTrue);
      expect(warmup + cooldown, lessThanOrEqualTo(120));
    });

    testWidgets('8.2-UNIT-003: main title matches cardio session type', (
      tester,
    ) async {
      final steps = await _generate(tester, _testSession);

      expect(steps[1].title, 'Cardio');
    });

    testWidgets('8.2-UNIT-004: null session uses default mobility session', (
      tester,
    ) async {
      final steps = await _generate(tester, null);
      final totalSeconds = steps.fold<int>(
        0,
        (sum, step) => sum + step.durationSeconds,
      );

      expect(totalSeconds, 300);
      expect(steps[1].title, 'Mobilità');
    });
  });
}
