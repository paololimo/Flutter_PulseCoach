import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/settings/data/models/ai_decision_record.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/ai_decision_log_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/ai_decision_log_state.dart';
import 'package:pulse_coach/features/settings/presentation/pages/ai_decision_log_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

import 'ai_decision_log_page_test.mocks.dart';

@GenerateMocks([AiDecisionLogCubit])
void main() {
  late MockAiDecisionLogCubit cubit;

  setUp(() {
    cubit = MockAiDecisionLogCubit();
    when(cubit.stream).thenAnswer((_) => const Stream.empty());
    when(cubit.close()).thenAnswer((_) async {});
    when(cubit.load()).thenAnswer((_) async {});
  });

  Widget buildPage(AiDecisionLogState state) {
    when(cubit.state).thenReturn(state);

    return MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      home: BlocProvider<AiDecisionLogCubit>.value(
        value: cubit,
        child: const AiDecisionLogPage(),
      ),
    );
  }

  group('AiDecisionLogPage', () {
    testWidgets('14.4-WIDGET-001: empty state text is shown', (tester) async {
      await tester.pumpWidget(
        buildPage(const AiDecisionLogState(isLoading: false, decisions: [])),
      );

      expect(
        find.text(
          "Nessuna decisione ancora. Completa la tua prima sessione per vedere come l'AI sta imparando.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('14.4-WIDGET-002: decision rows render arm key and RPE', (
      tester,
    ) async {
      final decisions = [
        AiDecisionRecord(
          decidedAt: DateTime.utc(2026, 6, 5, 8, 30),
          armKey: 'mobility_medium',
          rpeValue: 6,
          stateVector: null,
        ),
      ];

      await tester.pumpWidget(
        buildPage(AiDecisionLogState(isLoading: false, decisions: decisions)),
      );

      expect(find.text('Mobilità / Media'), findsOneWidget);
      expect(find.text('StateVector non disponibile'), findsOneWidget);
      expect(find.text('RPE 6'), findsOneWidget);
    });

    testWidgets('14.4-WIDGET-003: loading indicator shown', (tester) async {
      await tester.pumpWidget(buildPage(const AiDecisionLogState()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
