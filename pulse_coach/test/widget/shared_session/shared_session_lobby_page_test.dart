// [19.2-WIDGET-001..004] SharedSessionLobbyPage widget tests
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

@GenerateMocks([SharedSessionBloc])
import 'shared_session_lobby_page_test.mocks.dart';

const _kSteps = [
  ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 60),
];

Widget _buildTestWidget(
  SharedSessionState state, {
  Size viewportSize = const Size(390, 844),
  Locale? locale,
}) {
  final mockBloc = MockSharedSessionBloc();
  when(mockBloc.state).thenReturn(state);
  when(mockBloc.stream).thenAnswer((_) => const Stream.empty());
  when(mockBloc.close()).thenAnswer((_) async {});

  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    theme: AppTheme.darkTheme,
    home: MediaQuery(
      data: MediaQueryData(size: viewportSize),
      child: BlocProvider<SharedSessionBloc>.value(
        value: mockBloc,
        child: const SharedSessionLobbyPage(),
      ),
    ),
  );
}

void main() {
  setUp(() {
    provideDummy<SharedSessionState>(const SharedSessionState.initial());
  });

  group('SharedSessionLobbyPage (19.2)', () {
    testWidgets(
      '19.2-WIDGET-001: loading state renders _LobbyShimmer at 390×844',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          _buildTestWidget(const SharedSessionState.loading()),
        );
        await tester.pump();
        // Shimmer renders containers (no participant text rows)
        expect(find.byType(Container), findsWidgets);
        expect(find.text('Warm Up'), findsNothing);
      },
    );

    testWidgets(
      '19.2-WIDGET-002: lobby with 1 participant (host) — Start button disabled',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.lobby(
              participants: [
                ParticipantPresence(userId: 'host', displayHandle: 'alice'),
              ],
              isHost: true,
              steps: _kSteps,
            ),
          ),
        );
        await tester.pump();
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull); // disabled when < 2 participants
      },
    );

    testWidgets(
      '19.2-WIDGET-003: lobby with 2 participants (host) — Start button enabled',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.lobby(
              participants: [
                ParticipantPresence(userId: 'h', displayHandle: 'alice'),
                ParticipantPresence(userId: 'f', displayHandle: 'bob'),
              ],
              isHost: true,
              steps: _kSteps,
            ),
          ),
        );
        await tester.pump();
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNotNull); // enabled
      },
    );

    // E18R-1 fire: 360×640 shimmer test (scrollable shimmer, small viewport)
    testWidgets(
      '19.2-WIDGET-004: loading shimmer is scrollable at 360×640 (E18R-1)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.loading(),
            viewportSize: const Size(360, 640),
          ),
        );
        await tester.pump();
        // Scrollable must exist so shimmer degrades gracefully on small screens
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        // Should render without overflow
        expect(tester.takeException(), isNull);
      },
    );

    // AC4: 5-minute wait message (no countdown), host-only.
    testWidgets(
      '20.1-WIDGET-005: host lobby shows "no one yet" after 5 min (AC4)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.lobby(
              participants: [
                ParticipantPresence(userId: 'host', displayHandle: 'alice'),
              ],
              isHost: true,
              steps: _kSteps,
              joinCode: 'ABC123',
            ),
            locale: const Locale('it'),
          ),
        );
        await tester.pump();
        // Not shown before the 5-minute window elapses (no countdown pressure).
        expect(
          find.text('Nessuno ancora — condividi il codice'),
          findsNothing,
        );

        await tester.pump(const Duration(minutes: 5));
        expect(
          find.text('Nessuno ancora — condividi il codice'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '20.1-WIDGET-006: "no one yet" stays hidden when a participant is present '
      '(AC4)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.lobby(
              participants: [
                ParticipantPresence(userId: 'host', displayHandle: 'alice'),
                ParticipantPresence(userId: 'f', displayHandle: 'bob'),
              ],
              isHost: true,
              steps: _kSteps,
              joinCode: 'ABC123',
            ),
            locale: const Locale('it'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(minutes: 5));
        // Someone already joined → the nudge must never appear.
        expect(
          find.text('Nessuno ancora — condividi il codice'),
          findsNothing,
        );
      },
    );

    testWidgets(
      '19.2-WIDGET-005: inSession renders step title in a liveRegion Semantics (AC5/AC2)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 0,
              isHost: false,
              steps: _kSteps,
            ),
          ),
        );
        await tester.pump();
        // AC2: the received step content is rendered.
        expect(find.text('Warm Up'), findsOneWidget);
        expect(find.text('Breathe'), findsOneWidget);
        // AC5: the step title is wrapped in a liveRegion Semantics carrying an
        // explicit label, so AT users hear the step the group advanced to.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.liveRegion == true &&
                w.properties.label == 'Warm Up',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
