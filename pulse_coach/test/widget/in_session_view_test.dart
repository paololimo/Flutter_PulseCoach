import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
import 'package:pulse_coach/features/session/presentation/widgets/in_session_view.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

const _steps = [
  ExerciseStep(
    title: 'Riscaldamento',
    instruction: 'Muoviti lentamente.',
    durationSeconds: 60,
  ),
  ExerciseStep(
    title: 'Cardio',
    instruction: 'Mantieni il ritmo.',
    durationSeconds: 180,
  ),
  ExerciseStep(
    title: 'Defaticamento',
    instruction: 'Rallenta.',
    durationSeconds: 60,
  ),
];

const _longTitle =
    'Sequenza di mobilita controllata per spalle e colonna toracica';
const _longInstruction =
    'Mantieni il respiro regolare, lascia scendere le spalle e procedi con '
    'movimenti lenti senza forzare il range articolare durante la fase centrale.';

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  home: child,
);

InSessionView _view({int step = 0, int seconds = 60, int? liveHr}) =>
    InSessionView(
      sessionState: InSessionState(
        steps: _steps,
        currentStepIndex: step,
        secondsRemaining: seconds,
        liveHr: liveHr,
      ),
      onAbandon: () {},
    );

InSessionView _longContentView() => InSessionView(
  sessionState: const InSessionState(
    steps: [
      ExerciseStep(
        title: _longTitle,
        instruction: _longInstruction,
        durationSeconds: 90,
      ),
    ],
    currentStepIndex: 0,
    secondsRemaining: 90,
  ),
  onAbandon: () {},
);

void main() {
  group('InSessionView', () {
    testWidgets('8.2-WIDGET-001: step name in H2 style', (tester) async {
      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();

      final text = tester.widget<Text>(find.text('Riscaldamento'));

      expect(text.style?.fontSize, AppTextStyles.h2.fontSize);
      expect(text.style?.fontWeight, AppTextStyles.h2.fontWeight);
    });

    testWidgets('8.2-WIDGET-002: timer shows MM:SS format', (tester) async {
      await tester.pumpWidget(_wrap(_view(seconds: 90)));
      await tester.pump();

      expect(find.text('01:30'), findsOneWidget);
    });

    testWidgets('8.2-WIDGET-003: LinearProgressIndicator is present', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('8.2-WIDGET-004: abandon button is muted', (tester) async {
      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();

      expect(find.widgetWithText(TextButton, 'Abbandona'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Abbandona'));
      expect(text.style?.color, PulseCoachTheme.dark.onSurfaceVariant);
    });

    testWidgets('8.2-WIDGET-005: step instruction text is visible', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_view(step: 1, seconds: 180)));
      await tester.pump();

      expect(find.text('Mantieni il ritmo.'), findsOneWidget);
    });

    testWidgets('8.2-WIDGET-006: timer uses JetBrains Mono', (tester) async {
      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();

      final timerText = tester.widget<Text>(find.text('01:00'));
      expect(
        timerText.style?.fontFamily,
        AppTextStyles.timerDisplay.fontFamily,
      );
    });

    testWidgets('8.2-WIDGET-007: renders on 360x640 without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('8.4-WIDGET-001: HR badge is absent when liveHr is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();

      expect(find.textContaining('♥'), findsNothing);
    });

    testWidgets('8.4-WIDGET-002: HR badge shows value when liveHr is present', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_view(liveHr: 72)));
      await tester.pump();

      expect(find.text('♥ 72 bpm'), findsOneWidget);
    });

    testWidgets('8.4-WIDGET-003: HR badge uses Caption typography', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_view(liveHr: 90)));
      await tester.pump();

      final text = tester.widget<Text>(find.text('♥ 90 bpm'));
      expect(text.style?.fontSize, AppTextStyles.caption.fontSize);
      expect(text.style?.fontWeight, AppTextStyles.caption.fontWeight);
    });

    testWidgets('8.4-WIDGET-004: HR badge is positioned in a Stack', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_view(liveHr: 65)));
      await tester.pump();

      expect(find.textContaining('♥'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.textContaining('♥'),
          matching: find.byType(Positioned),
        ),
        findsOneWidget,
      );
    });

    testWidgets('8.4-WIDGET-005: HR badge value updates when liveHr changes', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_view(liveHr: 70)));
      await tester.pump();
      expect(find.text('♥ 70 bpm'), findsOneWidget);

      await tester.pumpWidget(_wrap(_view(liveHr: 85)));
      await tester.pump();

      expect(find.text('♥ 85 bpm'), findsOneWidget);
      expect(find.text('♥ 70 bpm'), findsNothing);
    });

    testWidgets('8.4-WIDGET-006: HR badge disappearing does not overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_view(liveHr: 72)));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('11.3-WIDGET-001: landscape 640x360 renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('11.3-WIDGET-002: uses OrientationBuilder for rotation', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();

      expect(find.byType(OrientationBuilder), findsOneWidget);
    });

    testWidgets('11.3-WIDGET-003: landscape shows timer in left column', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_view(seconds: 90)));
      await tester.pump();

      expect(find.text('01:30'), findsOneWidget);
    });

    testWidgets(
      '11.3-WIDGET-004: landscape shows instruction text in right column',
      (tester) async {
        tester.view.physicalSize = const Size(640, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(_view(step: 1)));
        await tester.pump();

        expect(find.text('Mantieni il ritmo.'), findsOneWidget);
      },
    );

    testWidgets(
      '11.3-WIDGET-005: timer value is preserved when surface rotates landscape',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(_view(seconds: 75)));
        await tester.pump();
        expect(find.text('01:15'), findsOneWidget);

        tester.view.physicalSize = const Size(640, 360);
        await tester.pump();

        expect(find.text('01:15'), findsOneWidget);
      },
    );

    testWidgets(
      '11.3-WIDGET-007: long landscape content uses truncation contracts without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(_longContentView()));
        await tester.pump();

        final title = tester.widget<Text>(find.text(_longTitle));
        final instruction = tester.widget<Text>(find.text(_longInstruction));

        expect(title.maxLines, 2);
        expect(title.overflow, TextOverflow.ellipsis);
        expect(instruction.maxLines, 6);
        expect(instruction.overflow, TextOverflow.ellipsis);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
