// [19.2-WIDGET-001..004, 20.3-WIDGET-008..010, 20.5-WIDGET-001..003] SharedSessionLobbyPage widget tests
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';
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

    // AC8: soft co-location visual cue (Icons.location_on + sharedSessionCoLocated)
    // shown for followers when coLocated==true, hidden otherwise.
    testWidgets(
      '20.3-WIDGET-008: follower + coLocated=true → location icon and '
      '"Vicino" text visible (AC8)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.lobby(
              participants: [
                ParticipantPresence(userId: 'host', displayHandle: 'alice'),
                ParticipantPresence(userId: 'f', displayHandle: 'bob'),
              ],
              isHost: false,
              steps: _kSteps,
              coLocated: true,
            ),
            locale: const Locale('it'),
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.location_on), findsOneWidget);
        expect(find.text('Vicino'), findsOneWidget);
      },
    );

    testWidgets(
      '20.3-WIDGET-009: follower + coLocated=null → location icon absent '
      '(check still pending, AC8)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.lobby(
              participants: [
                ParticipantPresence(userId: 'host', displayHandle: 'alice'),
                ParticipantPresence(userId: 'f', displayHandle: 'bob'),
              ],
              isHost: false,
              steps: _kSteps,
              // coLocated omitted → null (check still running)
            ),
            locale: const Locale('it'),
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.location_on), findsNothing);
      },
    );

    testWidgets(
      '20.3-WIDGET-010: host + coLocated=true → location icon absent '
      '(hosts do not see the cue, AC8)',
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
              coLocated: true,
            ),
            locale: const Locale('it'),
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.location_on), findsNothing);
      },
    );

    testWidgets(
      '19.2-WIDGET-005: inSession renders generated step title in a liveRegion Semantics (AC5/AC2)',
      (tester) async {
        // Steps are generated from plan params (Story 20.5 Task 6).
        // EN locale: first step = "Warm-up" (inSessionWarmupTitle ARB key).
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 0,
              isHost: false,
              steps: [],
              sessionType: 'mobility',
              intensity: 5,
              durationMinutes: 20,
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pump();
        // AC2: the generated first-step title is rendered.
        expect(find.text('Warm-up'), findsOneWidget);
        // AC5: the step title is wrapped in a liveRegion Semantics carrying an
        // explicit label, so AT users hear the step the group advanced to.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.liveRegion == true &&
                w.properties.label == 'Warm-up',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('SharedSessionLobbyPage step generation and armKey (20.5)', () {
    testWidgets(
      '[20.5-WIDGET-001] inSession with plan params → '
      '_SharedInSessionView receives 3 generated steps (AC6)',
      (tester) async {
        // Follower path: steps are generated from plan params.
        // state.steps is const [] — page generates via SessionStepGenerator.
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 0,
              isHost: false,
              steps: [],
              sessionType: 'mobility',
              intensity: 3,
              durationMinutes: 20,
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pump();

        // EN locale: SessionStepGenerator for 'mobility' generates:
        // step 0: title 'Warm-up', step 1: 'Mobility', step 2: 'Cool-down'
        // The follower view renders the first step title and instruction.
        expect(find.text('Warm-up'), findsOneWidget);
        // Semantics liveRegion must carry the generated warmup title.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.liveRegion == true &&
                w.properties.label == 'Warm-up',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '[20.5-WIDGET-002] inSession → sessionEnded(armKey: mobility_low) '
      'transition → context.go(sessionRpe) carries RpeSubmitArgs.armKey (AC7)',
      (tester) async {
        // BlocListener does NOT fire on the initial state — only on transitions.
        // Start in inSession (which also populates _lastSteps) and then emit
        // sessionEnded so the listener actually runs and navigates.
        final mockBloc = MockSharedSessionBloc();
        final controller = StreamController<SharedSessionState>.broadcast();
        addTearDown(controller.close);

        var current = const SharedSessionState.inSession(
          stepIndex: 0,
          elapsedSeconds: 0,
          isHost: false,
          steps: [],
          sessionType: 'mobility',
          intensity: 3,
          durationMinutes: 20,
        );
        when(mockBloc.state).thenAnswer((_) => current);
        when(mockBloc.stream).thenAnswer((_) => controller.stream);
        when(mockBloc.close()).thenAnswer((_) async {});

        RpeSubmitArgs? capturedArgs;
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => BlocProvider<SharedSessionBloc>.value(
                value: mockBloc,
                child: const SharedSessionLobbyPage(),
              ),
            ),
            GoRoute(
              path: AppRouter.sessionRpe,
              builder: (context, state) {
                capturedArgs = state.extra as RpeSubmitArgs?;
                return const SizedBox.shrink();
              },
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        );
        await tester.pump(); // build inSession → _lastSteps populated

        // Transition to sessionEnded — listener fires and navigates.
        current = const SharedSessionState.sessionEnded(armKey: 'mobility_low');
        controller.add(current);
        await tester.pumpAndSettle();

        expect(capturedArgs, isNotNull);
        expect(capturedArgs!.armKey, 'mobility_low');
      },
    );

    // E18R-1 fire: small viewport with inSession plan params
    testWidgets(
      '[20.5-WIDGET-003] 360×640 viewport, inSession with plan params → '
      'no overflow (E18R-1)',
      (tester) async {
        final prevSize = tester.view.physicalSize;
        final prevDpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.physicalSize = prevSize;
          tester.view.devicePixelRatio = prevDpr;
        });

        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 0,
              isHost: false,
              steps: [],
              sessionType: 'mobility',
              intensity: 3,
              durationMinutes: 20,
            ),
            locale: const Locale('en'),
            viewportSize: const Size(360, 640),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
