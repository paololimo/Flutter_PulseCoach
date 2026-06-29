// [19.3-WIDGET-001..002] Drop-out tolerance widget tests
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

@GenerateMocks([SharedSessionBloc])
import 'drop_out_tolerance_widget_test.mocks.dart';

Widget _buildTestWidget(SharedSessionState state) {
  final mockBloc = MockSharedSessionBloc();
  when(mockBloc.state).thenReturn(state);
  when(mockBloc.stream).thenAnswer((_) => const Stream.empty());
  when(mockBloc.close()).thenAnswer((_) async {});

  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.darkTheme,
    locale: const Locale('it'),
    home: BlocProvider<SharedSessionBloc>.value(
      value: mockBloc,
      child: const SharedSessionLobbyPage(),
    ),
  );
}

void main() {
  setUp(() {
    provideDummy<SharedSessionState>(const SharedSessionState.initial());
  });

  group('Drop-Out Tolerance — Widget (19.3)', () {
    testWidgets(
      '19.3-WIDGET-001: inSession with droppedHandle renders disconnect note (AC1, E18R-2)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 30,
              isHost: false,
              steps: [],
              droppedHandle: 'bob',
              sessionType: 'mobility',
              intensity: 5,
              durationMinutes: 20,
            ),
          ),
        );
        await tester.pump();
        // E18R-2: localized IT string; NOT raw 'bob disconnected'
        expect(find.textContaining('bob si è disconnesso'), findsOneWidget);
        // Step content still visible: IT locale generates 'Riscaldamento' (inSessionWarmupTitle)
        expect(find.text('Riscaldamento'), findsOneWidget);
      },
    );

    testWidgets(
      '19.3-WIDGET-002: sessionEnded state renders localized completion message (AC4, E18R-2)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(const SharedSessionState.sessionEnded()),
        );
        await tester.pump();
        // E18R-2: localized IT string
        expect(find.text('Sessione terminata'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
