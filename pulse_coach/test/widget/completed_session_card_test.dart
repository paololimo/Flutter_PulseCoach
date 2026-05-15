import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/completed_session_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

PlannedSession _session({
  String type = 'mobility',
  int duration = 5,
  String explanation = 'Questo non deve apparire.',
}) => PlannedSession(
  sessionType: type,
  intensity: 3,
  durationMinutes: duration,
  isIndoor: true,
  explanation: explanation,
);

void main() {
  group('CompletedSessionCard', () {
    testWidgets('7.3-COMPLETED-001: displays session display name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(CompletedSessionCard(session: _session(type: 'mobility'))),
      );

      expect(find.text('Mobilità'), findsOneWidget);
    });

    testWidgets('7.3-COMPLETED-002: displays duration label', (tester) async {
      await tester.pumpWidget(
        _wrap(CompletedSessionCard(session: _session(duration: 5))),
      );

      expect(find.text('5 min'), findsOneWidget);
    });

    testWidgets('7.3-COMPLETED-003: shows check icon', (tester) async {
      await tester.pumpWidget(_wrap(CompletedSessionCard(session: _session())));

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('7.3-COMPLETED-004: is non-interactive', (tester) async {
      await tester.pumpWidget(_wrap(CompletedSessionCard(session: _session())));

      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('7.3-COMPLETED-005: hides AI explanation text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CompletedSessionCard(
            session: _session(explanation: 'Dettaglio AI nascosto.'),
          ),
        ),
      );

      expect(find.text('Dettaglio AI nascosto.'), findsNothing);
    });
  });
}
