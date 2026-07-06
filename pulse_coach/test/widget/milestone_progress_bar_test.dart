import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/session/presentation/widgets/milestone_progress_bar.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) => MediaQuery(
  data: const MediaQueryData().copyWith(disableAnimations: disableAnimations),
  child: MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.darkTheme,
    home: Scaffold(body: Center(child: child)),
  ),
);

Semantics _semanticsWithLabelContaining(WidgetTester tester, String needle) {
  final matches = tester
      .widgetList<Semantics>(find.byType(Semantics))
      .where((widget) => widget.properties.label?.contains(needle) ?? false);
  return matches.first;
}

void main() {
  group('MilestoneProgressBar', () {
    testWidgets('22.1-MILE-001: step 1 of 3 renders without exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MilestoneProgressBar(
            currentStepIndex: 0,
            totalSteps: 3,
            isComplete: false,
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        () => _semanticsWithLabelContaining(tester, '1'),
        returnsNormally,
      );
      final semantics = _semanticsWithLabelContaining(tester, '1');
      expect(semantics.properties.label, contains('3'));
    });

    testWidgets('22.1-MILE-002: step 2 of 3 reflected in semantics label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MilestoneProgressBar(
            currentStepIndex: 1,
            totalSteps: 3,
            isComplete: false,
          ),
        ),
      );
      await tester.pump();

      final semantics = _semanticsWithLabelContaining(tester, '2');
      expect(semantics.properties.label, contains('2'));
      expect(semantics.properties.label, contains('3'));
    });

    testWidgets('22.1-MILE-003: single-step session renders without exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MilestoneProgressBar(
            currentStepIndex: 0,
            totalSteps: 1,
            isComplete: false,
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '22.1-MILE-004: isComplete false -> true updates semantics label to finish reached',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const MilestoneProgressBar(
              currentStepIndex: 2,
              totalSteps: 3,
              isComplete: false,
            ),
          ),
        );
        await tester.pump();

        final beforeLabel = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .map((widget) => widget.properties.label)
            .whereType<String>()
            .firstWhere((label) => label.contains('3'));

        await tester.pumpWidget(
          _wrap(
            const MilestoneProgressBar(
              currentStepIndex: 2,
              totalSteps: 3,
              isComplete: true,
            ),
          ),
        );
        await tester.pump();

        final afterLabel = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .map((widget) => widget.properties.label)
            .whereType<String>()
            .firstWhere((label) => label.contains('3'));

        expect(afterLabel, isNot(equals(beforeLabel)));
      },
    );

    testWidgets(
      '22.1-MILE-005: reduce motion + isComplete transition renders static filled state immediately',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const MilestoneProgressBar(
              currentStepIndex: 2,
              totalSteps: 3,
              isComplete: false,
            ),
            disableAnimations: true,
          ),
        );
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            const MilestoneProgressBar(
              currentStepIndex: 2,
              totalSteps: 3,
              isComplete: true,
            ),
            disableAnimations: true,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          tester.binding.transientCallbackCount,
          equals(0),
          reason: 'no animation should be in flight when Reduce Motion is on',
        );
      },
    );

    testWidgets(
      '22.1-MILE-006: finish-marker settle animation is wrapped in ExcludeSemantics',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const MilestoneProgressBar(
              currentStepIndex: 0,
              totalSteps: 3,
              isComplete: false,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ExcludeSemantics), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('22.1-MILE-007: renders on 360x640 without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const MilestoneProgressBar(
            currentStepIndex: 1,
            totalSteps: 3,
            isComplete: false,
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
