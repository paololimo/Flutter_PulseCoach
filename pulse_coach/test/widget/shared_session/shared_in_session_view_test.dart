// [20.4-WIDGET-001..006] _SharedInSessionView widget tests (via SharedSessionLobbyPage)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/widgets/in_session_view.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

// Reuse mocks from the existing lobby page test file.
import 'shared_session_lobby_page_test.mocks.dart';

const _kSteps = [
  ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 30),
  ExerciseStep(title: 'Cardio', instruction: 'Run', durationSeconds: 60),
];

const _kParticipants = [
  ParticipantPresence(userId: 'host', displayHandle: 'alice'),
  ParticipantPresence(userId: 'follower', displayHandle: 'bob'),
];

Widget _buildTestWidget(
  SharedSessionState initialState, {
  Stream<SharedSessionState>? stream,
  Locale locale = const Locale('it'),
  Size viewportSize = const Size(390, 844),
}) {
  final mockBloc = MockSharedSessionBloc();
  when(mockBloc.state).thenReturn(initialState);
  when(mockBloc.stream)
      .thenAnswer((_) => stream ?? const Stream.empty());
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

  group('_SharedInSessionView (20.4)', () {
    testWidgets(
      '20.4-WIDGET-001: follower path renders step title + participant badge '
      '(2 partecipanti for IT locale)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 0,
              isHost: false,
              steps: [],
              participants: _kParticipants,
              sessionType: 'mobility',
              intensity: 5,
              durationMinutes: 20,
            ),
            locale: const Locale('it'),
          ),
        );
        await tester.pump();

        // Step title generated from plan params; IT locale: 'Riscaldamento' (inSessionWarmupTitle)
        expect(find.text('Riscaldamento'), findsOneWidget);
        expect(find.text('2 partecipanti'), findsOneWidget);
      },
    );

    testWidgets(
      '20.4-WIDGET-002: follower didUpdateWidget with new stepIndex '
      '→ displayedElapsed resets to broadcast elapsedSeconds',
      (tester) async {
        final stateController =
            StreamController<SharedSessionState>.broadcast();
        addTearDown(stateController.close);

        const initialState = SharedSessionState.inSession(
          stepIndex: 0,
          elapsedSeconds: 0,
          isHost: false,
          steps: _kSteps,
          participants: _kParticipants,
        );
        const updatedState = SharedSessionState.inSession(
          stepIndex: 1,
          elapsedSeconds: 100,
          isHost: false,
          steps: _kSteps,
          participants: _kParticipants,
        );

        final mockBloc = MockSharedSessionBloc();
        when(mockBloc.state).thenReturn(initialState);
        when(mockBloc.stream)
            .thenAnswer((_) => stateController.stream);
        when(mockBloc.close()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('it'),
            theme: AppTheme.darkTheme,
            home: BlocProvider<SharedSessionBloc>.value(
              value: mockBloc,
              child: const SharedSessionLobbyPage(),
            ),
          ),
        );
        await tester.pump();
        // Initial render shows elapsedSeconds: 0 → "00:00"
        expect(find.text('00:00'), findsOneWidget);

        // Emit updated state with new stepIndex and elapsedSeconds: 100
        when(mockBloc.state).thenReturn(updatedState);
        stateController.add(updatedState);
        // Two pumps: first processes BlocBuilder rebuild (calls didUpdateWidget
        // which calls setState); second processes the setState rebuild.
        await tester.pump();
        await tester.pump();

        // didUpdateWidget fires (stepIndex changed) → _displayedElapsed = 100
        expect(find.text('01:40'), findsOneWidget);
      },
    );

    testWidgets(
      '20.4-WIDGET-003: host path renders InSessionView widget and participant badge',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 0,
              isHost: true,
              steps: _kSteps,
              participants: _kParticipants,
            ),
            locale: const Locale('it'),
          ),
        );
        await tester.pump();

        expect(find.byType(InSessionView), findsOneWidget);
        expect(find.text('2 partecipanti'), findsOneWidget);
      },
    );

    testWidgets(
      '20.4-WIDGET-004: host path abandon button is present',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 0,
              isHost: true,
              steps: _kSteps,
              participants: _kParticipants,
            ),
            locale: const Locale('it'),
          ),
        );
        await tester.pump();

        // InSessionView renders a TextButton with the abandon label
        expect(find.text('Abbandona'), findsOneWidget);
      },
    );

    testWidgets(
      '20.4-WIDGET-007: follower promoted to host (isHost flips) → host '
      'InSessionView spins up (no blank screen)',
      (tester) async {
        final stateController =
            StreamController<SharedSessionState>.broadcast();
        addTearDown(stateController.close);

        const followerState = SharedSessionState.inSession(
          stepIndex: 0,
          elapsedSeconds: 0,
          isHost: false,
          steps: _kSteps,
          participants: _kParticipants,
        );
        const promotedState = SharedSessionState.inSession(
          stepIndex: 0,
          elapsedSeconds: 0,
          isHost: true,
          steps: _kSteps,
          participants: _kParticipants,
        );

        final mockBloc = MockSharedSessionBloc();
        when(mockBloc.state).thenReturn(followerState);
        when(mockBloc.stream).thenAnswer((_) => stateController.stream);
        when(mockBloc.close()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('it'),
            theme: AppTheme.darkTheme,
            home: BlocProvider<SharedSessionBloc>.value(
              value: mockBloc,
              child: const SharedSessionLobbyPage(),
            ),
          ),
        );
        await tester.pump();
        // Follower path: no host InSessionView yet.
        expect(find.byType(InSessionView), findsNothing);

        // Host drops → bloc promotes this follower to host.
        when(mockBloc.state).thenReturn(promotedState);
        stateController.add(promotedState);
        await tester.pump(); // BlocBuilder rebuild → didUpdateWidget promotes
        await tester.pump(); // setState rebuild → _buildHostView

        // Host cubit spun up: InSessionView now renders (not a blank screen).
        expect(find.byType(InSessionView), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '20.4-WIDGET-005: 360×640 viewport, follower path renders without overflow (E18R-1)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 0,
              isHost: false,
              steps: _kSteps,
              participants: _kParticipants,
            ),
            viewportSize: const Size(360, 640),
            locale: const Locale('it'),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('2 partecipanti'), findsOneWidget);
      },
    );

    testWidgets(
      '20.4-WIDGET-006: 360×640 viewport, host path renders without overflow (E18R-1)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestWidget(
            const SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 0,
              isHost: true,
              steps: _kSteps,
              participants: _kParticipants,
            ),
            viewportSize: const Size(360, 640),
            locale: const Locale('it'),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(InSessionView), findsOneWidget);
      },
    );
  });
}
