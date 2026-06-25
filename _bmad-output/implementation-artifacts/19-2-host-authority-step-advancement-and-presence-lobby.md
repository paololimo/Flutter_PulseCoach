---
baseline_commit: ccfa946
---

# Story 19.2: Host-Authority Step Advancement and Presence Lobby

Status: done

## Story

As the host of a shared session,
I want to be the sole authority that advances steps, with all followers rendering my broadcast,
So that all participants see a synchronized session state without divergence.

## Context

Story 19.1 (`done`) delivered `RealtimeGateway` — the typed Dart stream wrapper over Supabase Realtime. This story builds the next layer: `SharedSessionBloc`, which consumes the gateway streams and implements:

1. **Host-authority enforcement** — only the host emits `step_advanced` broadcast; followers never emit independently (ARCH21).
2. **Presence lobby** — `SharedSessionLobbyPage` lists participants from the `PresenceState` stream; Start button gates on ≥2 participants.
3. **Synchronized start** — host taps Start → `session_started` broadcast → all `SharedSessionBloc` instances emit `inSession` state simultaneously.
4. **Follower step rendering** — follower's bloc receives `step_advanced`, updates `inSession` state (stepIndex + elapsedSeconds); UI re-renders the new step via `Semantics(liveRegion: true)` (UX-DR32).

Story 20.1 (creates the `shared_sessions` DB row, join code, QR) builds on top of this story. Story 19.2 does NOT touch the `shared_sessions` table — all channel logic is purely ephemeral Realtime (no migration needed).

**E9-K1 fire-check for Story 19.2:**

| Item | Fires? | Required action |
|---|---|---|
| `E18R-1` small-viewport shimmer | ✅ **YES** — `SharedSessionLobbyPage` has a `loading` shimmer state | Add a `testWidgets` at 360×640 viewport for the lobby shimmer |
| `E18R-2` Amici backend-failure localization | ✅ **YES** — `SharedSessionBloc` error state is surfaced in the lobby page | Map `RealtimeFailure` to a localized IT string in the UI; no raw `failure.message` passthrough |
| `E18R-CB2` review check: localized-IT on all Failure paths | ✅ **YES** — same as E18R-2 | Review-layer check: verify lobby error widget shows IT text, not failure code |
| `E10R-2` non-UTC week-bucketing | ❌ | Not triggered |
| `E18R-4` social ProUpsellSheet copy | ❌ | Not triggered |

**Category A snapshot entering sprint (Story 19.2): 4 / 5.** Active: `E18R-1`, `E18R-2`, `E10R-2`, `E18R-4`. Cap satisfied.

## Acceptance Criteria

**AC1 — Host authority enforced at bloc level:**
Given the session is in progress and the current user is the host (`isHost = true`)
When the host's `SharedSessionBloc` receives a `StepAdvanced` internal event (from the host's InSessionCubit or a host-side timer)
Then it calls `RealtimeGateway.sendBroadcast(event: 'step_advanced', payload: {'step_index': stepIndex, 'elapsed_seconds': elapsedSeconds})`; followers' blocs never call `sendBroadcast` for `step_advanced` independently (ARCH21)

**AC2 — Follower renders received step:**
Given the current user is a follower (`isHost = false`) and the bloc is in `inSession` state
When the `RealtimeGateway.broadcastEvents` stream emits a `BroadcastEvent.stepAdvanced(stepIndex, elapsedSeconds)`
Then `SharedSessionBloc` emits a new `inSession` state with the updated `stepIndex` and `elapsedSeconds`; the UI re-renders the new step immediately; local timer drift is corrected by the received `elapsedSeconds`

**AC3 — Presence lobby lists participants with Start gating:**
Given a `PresenceState` event fires
When `SharedSessionLobbyPage` renders in `lobby` state
Then all joined participants are listed with their `displayHandle`; the Start button (`Avvia`) is enabled only when `participants.length >= 2 AND isHost = true`; followers see a waiting indicator, not a Start button (UX-DR29)

**AC4 — Session start broadcast triggers inSession on all clients:**
Given the host taps `Avvia` and the bloc is in `lobby` state with ≥2 participants
When `SharedSessionBloc` receives a `SessionStartTapped` event
Then it calls `RealtimeGateway.sendBroadcast(event: 'session_started', payload: {})` via the host's path; on receiving the `BroadcastEvent.sessionStarted()` from the gateway, all participants' `SharedSessionBloc` instances (host and followers) emit `SharedSessionState.inSession(stepIndex: 0, elapsedSeconds: 0, isHost: ..., steps: ...)` (UX-DR29)

**AC5 — Semantics liveRegion with label on step name:**
Given `SharedSessionBloc` emits a new `inSession` state with an updated `stepIndex`
When `SharedSessionLobbyPage` renders the step name widget
Then the step name `Text` is wrapped in `Semantics(liveRegion: true, label: step.title)` so screen readers announce the new step to AT users silently advanced by the group (UX-DR32, ARCH21 accessibility requirement)

**AC6 — Zero regressions:**
Given the new files and build_runner run are added
When `flutter test` and `flutter analyze lib/ test/` are run from `pulse_coach/`
Then all existing tests pass plus all new tests pass; analyzer reports 0 issues

## Tasks / Subtasks

- [x] **Task 1 — `SharedSessionStartArgs` navigation contract (AC3, AC4)**

  - [x] 1.1 Create `pulse_coach/lib/features/social/shared_session/domain/entities/shared_session_start_args.dart`:

    ```dart
    import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';

    /// Navigation contract for /social/shared-session/lobby.
    ///
    /// Passed via GoRouter `extra` from Story 20.1 (SharedSession creation/join).
    /// Story 19.2 adds the route; Story 20.1 wires navigation to it.
    class SharedSessionStartArgs {
      final String sessionId;
      final bool isHost;
      final String userId;
      final String? displayHandle;
      final List<ExerciseStep> steps;

      const SharedSessionStartArgs({
        required this.sessionId,
        required this.isHost,
        required this.userId,
        this.displayHandle,
        required this.steps,
      });
    }
    ```

    **Rationale:** This class is the routing contract between Story 20.1 (which knows the sessionId and isHost role) and Story 19.2 (which uses those values to join the channel). Keeping it in `domain/entities/` rather than `presentation/` avoids circular imports and makes it testable from pure Dart.

- [x] **Task 2 — `SharedSessionState` (freezed sealed union) (AC1–AC5)**

  - [x] 2.1 Create `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.dart`:

    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';

    part 'shared_session_state.freezed.dart';

    @freezed
    sealed class SharedSessionState with _$SharedSessionState {
      const factory SharedSessionState.initial() = _Initial;

      const factory SharedSessionState.loading() = _Loading;

      const factory SharedSessionState.lobby({
        required List<ParticipantPresence> participants,
        required bool isHost,
        required List<ExerciseStep> steps,
      }) = _Lobby;

      const factory SharedSessionState.inSession({
        required int stepIndex,
        required int elapsedSeconds,
        required bool isHost,
        required List<ExerciseStep> steps,
      }) = _InSession;

      const factory SharedSessionState.error({
        required Failure failure,
      }) = _Error;
    }
    ```

    **Critical — sealed class:** Use `sealed class` so the compiler enforces exhaustive switch in `SharedSessionLobbyPage`. Same pattern as `BroadcastEvent` from Story 19.1.

    **Critical — `steps` in both `lobby` and `inSession`:** Steps are carried through so the lobby page can display the exercise plan during the lobby and drive the in-session view. They are passed in via `SharedSessionJoined` event and never re-fetched.

    **Critical — `canStart` is NOT a state field:** Derived at the widget level as `participants.length >= 2 && isHost`. Deriving it at the bloc level would force a new state emission on every presence update even if the start eligibility didn't change — unnecessary UI rebuilds.

    **Critical — `inSession.elapsedSeconds` is host-reported, not local:** For followers, this value comes directly from the `step_advanced` payload. For the host, it is passed in via the `HostStepAdvanced` event carrying the cubit's elapsed value. This is the drift-correction mechanism.

  - [x] 2.2 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`. Verify `shared_session_state.freezed.dart` is generated in the same directory as the source file.

- [x] **Task 3 — `SharedSessionEvent` (AC1–AC4)**

  - [x] 3.1 Create `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_event.dart`:

    ```dart
    import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';

    sealed class SharedSessionEvent {
      const SharedSessionEvent();
    }

    /// User has been placed into a shared session channel.
    /// Host: isHost = true. Follower: isHost = false.
    final class SharedSessionJoined extends SharedSessionEvent {
      final String sessionId;
      final bool isHost;
      final String userId;
      final String? displayHandle;
      final List<ExerciseStep> steps;

      const SharedSessionJoined({
        required this.sessionId,
        required this.isHost,
        required this.userId,
        this.displayHandle,
        required this.steps,
      });
    }

    /// Host taps the Start button in the lobby.
    final class SessionStartTapped extends SharedSessionEvent {
      const SessionStartTapped();
    }

    /// Host's local timer advanced a step — only the host emits this.
    /// Carries current elapsed seconds for the drift-correction payload.
    final class HostStepAdvanced extends SharedSessionEvent {
      final int stepIndex;
      final int elapsedSeconds;
      const HostStepAdvanced({required this.stepIndex, required this.elapsedSeconds});
    }

    // --- Internal events (from stream subscriptions) ---

    final class _PresenceStateReceived extends SharedSessionEvent {
      final PresenceState presenceState;
      const _PresenceStateReceived(this.presenceState);
    }

    final class _BroadcastEventReceived extends SharedSessionEvent {
      final BroadcastEvent broadcastEvent;
      const _BroadcastEventReceived(this.broadcastEvent);
    }
    ```

    **Critical — `HostStepAdvanced` event:** This is dispatched by the host's `InSessionCubit` (or a wiring widget in Story 20.4) when it advances a step locally. The bloc then calls `sendBroadcast` to fan out to followers. Followers never dispatch this event — the symmetry of host vs. follower is enforced at the dispatch site (the widget/cubit that calls `add(HostStepAdvanced(...))`), not inside the bloc.

    **Critical — internal events with underscore prefix:** `_PresenceStateReceived` and `_BroadcastEventReceived` use underscore prefix as a naming signal that they are for bloc-internal use only (dispatched from stream subscriptions inside the bloc). They are Dart `final class`es, not private — they are private-by-convention only. In a production app, they would be package-private; in this project, the convention is sufficient.

    **Critical — `SessionStartTapped` vs `SessionStarted`:** `SessionStartTapped` is the user-initiated event (host presses the button). `BroadcastEvent.sessionStarted()` is what arrives from the Realtime channel. The distinction is important: both the host AND followers receive `BroadcastEvent.sessionStarted()` from the channel (even the host receives their own broadcast back), which is what triggers the `inSession` state emission for all participants.

- [x] **Task 4 — `SharedSessionBloc` (AC1–AC4)**

  - [x] 4.1 Create `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`:

    ```dart
    import 'dart:async';

    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/cloud/realtime_gateway.dart';
    import 'package:pulse_coach/core/error/failures.dart';

    import 'shared_session_event.dart';
    import 'shared_session_state.dart';

    @injectable
    class SharedSessionBloc extends Bloc<SharedSessionEvent, SharedSessionState> {
      final RealtimeGateway _gateway;

      StreamSubscription<dynamic>? _broadcastSub;
      StreamSubscription<dynamic>? _presenceSub;

      SharedSessionBloc(this._gateway) : super(const SharedSessionState.initial()) {
        on<SharedSessionJoined>(_onJoined);
        on<SessionStartTapped>(_onStartTapped);
        on<HostStepAdvanced>(_onHostStepAdvanced);
        on<_PresenceStateReceived>(_onPresenceReceived);
        on<_BroadcastEventReceived>(_onBroadcastReceived);
      }

      Future<void> _onJoined(
          SharedSessionJoined event, Emitter<SharedSessionState> emit) async {
        emit(const SharedSessionState.loading());
        try {
          await _gateway.joinChannel(event.sessionId);
          await _gateway.trackPresence(
            userId: event.userId,
            displayHandle: event.displayHandle,
          );
          _broadcastSub = _gateway.broadcastEvents.listen(
            (e) => add(_BroadcastEventReceived(e)),
          );
          _presenceSub = _gateway.presenceUpdates.listen(
            (s) => add(_PresenceStateReceived(s)),
          );
          emit(SharedSessionState.lobby(
            participants: const [],
            isHost: event.isHost,
            steps: event.steps,
          ));
        } catch (e) {
          emit(SharedSessionState.error(
            failure: RealtimeFailure('channel_join_failed: $e'),
          ));
        }
      }

      Future<void> _onStartTapped(
          SessionStartTapped event, Emitter<SharedSessionState> emit) async {
        final lobbyState = state.mapOrNull(lobby: (s) => s);
        if (lobbyState == null || !lobbyState.isHost) return;
        if (lobbyState.participants.length < 2) return;
        try {
          await _gateway.sendBroadcast(event: 'session_started', payload: {});
        } catch (e) {
          emit(SharedSessionState.error(
            failure: RealtimeFailure('session_start_broadcast_failed: $e'),
          ));
        }
      }

      Future<void> _onHostStepAdvanced(
          HostStepAdvanced event, Emitter<SharedSessionState> emit) async {
        final inSessionState = state.mapOrNull(inSession: (s) => s);
        if (inSessionState == null || !inSessionState.isHost) return;
        try {
          await _gateway.sendBroadcast(
            event: 'step_advanced',
            payload: {
              'step_index': event.stepIndex,
              'elapsed_seconds': event.elapsedSeconds,
            },
          );
        } catch (e) {
          // Non-fatal: broadcast failure for step doesn't end the session.
          // The host's local session continues; followers experience a sync gap
          // that will be corrected on the next step_advanced broadcast.
          // Story 19.3 (drop-out tolerance) handles persistent broadcast failure.
        }
      }

      void _onPresenceReceived(
          _PresenceStateReceived event, Emitter<SharedSessionState> emit) {
        state.mapOrNull(
          lobby: (s) => emit(s.copyWith(participants: event.presenceState.participants)),
          inSession: (s) => null, // Presence changes during session are informational only
        );
      }

      void _onBroadcastReceived(
          _BroadcastEventReceived event, Emitter<SharedSessionState> emit) {
        final broadcast = event.broadcastEvent;
        switch (broadcast) {
          case SessionStarted():
            // Fires for ALL participants (including the host who sent it).
            // This is the authoritative signal to transition from lobby to session.
            state.mapOrNull(
              lobby: (s) => emit(SharedSessionState.inSession(
                stepIndex: 0,
                elapsedSeconds: 0,
                isHost: s.isHost,
                steps: s.steps,
              )),
            );
          case StepAdvanced(stepIndex: final idx, elapsedSeconds: final elapsed):
            // Followers (isHost=false): update step from broadcast.
            // Host (isHost=true): the host's local InSessionCubit drives step
            // display; the echo of the host's own broadcast is ignored here
            // to avoid a double-advance.
            state.mapOrNull(
              inSession: (s) {
                if (s.isHost) return; // Host ignores its own echo
                emit(s.copyWith(stepIndex: idx, elapsedSeconds: elapsed));
              },
            );
          case SessionEnded():
            // Clean up channel — Story 19.3 handles the full teardown flow.
            // Transition to a terminal state; RPE routing is Story 20.4.
            // For now, go back to initial so the lobby page knows the session ended.
            unawaited(_gateway.leaveChannel());
            emit(const SharedSessionState.initial());
          case UnknownBroadcast():
            // Silently drop unknown events (e.g. system pings from Supabase).
            break;
        }
      }

      @override
      Future<void> close() async {
        await _broadcastSub?.cancel();
        await _presenceSub?.cancel();
        await _gateway.leaveChannel();
        return super.close();
      }
    }
    ```

    **Critical — `@injectable` not `@singleton`:** `SharedSessionBloc` has a page lifecycle. A new instance must be created for each shared session (via `BlocProvider(create: (_) => getIt<SharedSessionBloc>())`). Marking it `@singleton` would prevent concurrent or sequential sessions from using independent bloc instances.

    **Critical — ARCH25 boundary:** `SharedSessionBloc` is in `lib/features/social/shared_session/presentation/bloc/` and imports only `RealtimeGateway` from `lib/core/cloud/`. It does NOT import `supabase_flutter` directly. No Supabase types leak into the bloc.

    **Critical — host echo handling:** When the host calls `sendBroadcast(event: 'step_advanced', ...)`, Supabase Realtime echoes the event back to the sender's channel subscription. The host's `_onBroadcastReceived` for `StepAdvanced` must check `s.isHost` and return early to avoid double-advancing the host's step display.

    **Critical — `SessionStarted` handled by ALL participants:** Unlike `StepAdvanced` (where the host ignores its echo), `SessionStarted` must transition BOTH host and followers from `lobby` to `inSession`. The host dispatched the broadcast; the host also receives it back and uses it as the authoritative signal to transition. This ensures all participants' blocs enter `inSession` from the same event.

    **Critical — `SessionStartTapped` guard:** `_onStartTapped` checks `lobbyState.participants.length < 2` and returns early to prevent a start broadcast with only 1 participant. The UI also disables the button, but the bloc guard is the authoritative safety check.

    **Critical — `close()` calls `leaveChannel()`:** The bloc's `close()` must await both stream subscription cancellations AND `_gateway.leaveChannel()`. If the page is popped without an explicit leave action, the bloc `close()` ensures the Supabase channel is cleaned up and stream controllers closed. This prevents dangling subscriptions even on unexpected navigation.

    **Critical — non-fatal `HostStepAdvanced` broadcast failure:** A broadcast failure for `step_advanced` is non-fatal (the host's local session continues). Story 19.3 handles the persistent failure / drop-out scenario. A silent swallow is intentional here; the comment in code explains why.

    **Critical — `_PresenceStateReceived` only updates `lobby` state:** Once in `inSession`, presence changes (participants dropping out) are handled by Story 19.3 (`participantDropped` state). In Story 19.2, presence during `inSession` is ignored at the bloc level.

  - [x] 4.2 Run `dart run build_runner build --delete-conflicting-outputs` to register `SharedSessionBloc` in `injection.config.dart`. Verify a new `gh.factory<SharedSessionBloc>(...)` entry appears.

- [x] **Task 5 — `SharedSessionLobbyPage` (AC3–AC5, E18R-1, E18R-2)**

  - [x] 5.1 Create `pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart`:

    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/core/theme/app_text_styles.dart';
    import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
    import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
    import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
    import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
    import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';
    import 'package:pulse_coach/l10n/app_localizations.dart';

    class SharedSessionLobbyPage extends StatelessWidget {
      const SharedSessionLobbyPage({super.key});

      @override
      Widget build(BuildContext context) {
        return BlocBuilder<SharedSessionBloc, SharedSessionState>(
          builder: (context, state) {
            return switch (state) {
              _Initial() => const SizedBox.shrink(),
              _Loading() => const _LobbyShimmer(),
              _Lobby(
                :final participants,
                :final isHost,
                :final steps,
              ) =>
                _LobbyView(
                  participants: participants,
                  isHost: isHost,
                  steps: steps,
                  onStart: () =>
                      context.read<SharedSessionBloc>().add(const SessionStartTapped()),
                ),
              _InSession(
                :final stepIndex,
                :final elapsedSeconds,
                :final steps,
              ) =>
                _SharedInSessionView(
                  stepIndex: stepIndex,
                  elapsedSeconds: elapsedSeconds,
                  steps: steps,
                ),
              _Error(:final failure) => _ErrorView(failure: failure),
            };
          },
        );
      }
    }

    class _LobbyShimmer extends StatelessWidget {
      const _LobbyShimmer();

      @override
      Widget build(BuildContext context) {
        final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
        // Scrollable so the shimmer behaves like its loaded counterpart on
        // small-viewport devices (E18R-CB1 review rule).
        return Scaffold(
          backgroundColor: pulseTheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _shimmerBox(height: 28, width: 200),
                    const SizedBox(height: 24),
                    for (int i = 0; i < 3; i++) ...[
                      _shimmerBox(height: 48),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 24),
                    _shimmerBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      Widget _shimmerBox({required double height, double? width}) {
        return Builder(
          builder: (context) {
            final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
            return Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                color: pulseTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          },
        );
      }
    }

    class _LobbyView extends StatelessWidget {
      final List<ParticipantPresence> participants;
      final bool isHost;
      final List<ExerciseStep> steps;
      final VoidCallback onStart;

      const _LobbyView({
        required this.participants,
        required this.isHost,
        required this.steps,
        required this.onStart,
      });

      @override
      Widget build(BuildContext context) {
        final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
        final l10n = AppLocalizations.of(context)!;
        final canStart = isHost && participants.length >= 2;

        return Scaffold(
          backgroundColor: pulseTheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.sharedSessionLobbyTitle,
                    style: AppTextStyles.h2.copyWith(color: pulseTheme.onSurface),
                  ),
                  const SizedBox(height: 24),
                  ...participants.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ParticipantRow(participant: p),
                    ),
                  ),
                  if (participants.isEmpty)
                    Text(
                      l10n.sharedSessionLobbyWaiting,
                      style: AppTextStyles.body.copyWith(
                        color: pulseTheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 32),
                  if (isHost)
                    FilledButton(
                      onPressed: canStart ? onStart : null,
                      child: Text(l10n.sharedSessionStartButton),
                    )
                  else
                    Text(
                      l10n.sharedSessionWaitingForHost,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: pulseTheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    class _ParticipantRow extends StatelessWidget {
      final ParticipantPresence participant;

      const _ParticipantRow({required this.participant});

      @override
      Widget build(BuildContext context) {
        final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
        return Row(
          children: [
            const Icon(Icons.person_outline, size: 20),
            const SizedBox(width: 8),
            Text(
              participant.displayHandle ?? participant.userId,
              style: AppTextStyles.body.copyWith(color: pulseTheme.onSurface),
            ),
          ],
        );
      }
    }

    // AC5: Semantics(liveRegion: true, label: step.title) on the step name
    // widget so AT users receive announcements when the group advances silently.
    class _SharedInSessionView extends StatelessWidget {
      final int stepIndex;
      final int elapsedSeconds;
      final List<ExerciseStep> steps;

      const _SharedInSessionView({
        required this.stepIndex,
        required this.elapsedSeconds,
        required this.steps,
      });

      @override
      Widget build(BuildContext context) {
        final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
        final l10n = AppLocalizations.of(context)!;
        final step = steps[stepIndex.clamp(0, steps.length - 1)];
        final totalSteps = steps.length;
        final minutesDisplay = _formatTime(elapsedSeconds);

        return Scaffold(
          backgroundColor: pulseTheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // AC5 — liveRegion + explicit label for AT announcements.
                  Semantics(
                    liveRegion: true,
                    label: step.title,
                    child: Text(
                      step.title,
                      style: AppTextStyles.h2.copyWith(color: pulseTheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.inSessionStepLabel(
                      (stepIndex + 1).toString(),
                      totalSteps.toString(),
                    ),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    minutesDisplay,
                    style: AppTextStyles.timerDisplay.copyWith(
                      color: pulseTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: (stepIndex + 1) / totalSteps,
                    backgroundColor: pulseTheme.surfaceContainerHigh,
                    color: pulseTheme.primaryColor,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    step.instruction,
                    style: AppTextStyles.body.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      static String _formatTime(int seconds) {
        final m = seconds ~/ 60;
        final s = seconds % 60;
        return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }
    }

    class _ErrorView extends StatelessWidget {
      final Failure failure;

      const _ErrorView({required this.failure});

      @override
      Widget build(BuildContext context) {
        final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: pulseTheme.surface,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              // E18R-2 + E18R-CB2: NO raw failure.message passthrough.
              // Use a localized IT string for all Failure types.
              child: Text(
                l10n.sharedSessionErrorGeneric,
                style: AppTextStyles.body.copyWith(
                  color: pulseTheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
    }
    ```

    **Critical — E18R-2 + E18R-CB2 compliance:** The `_ErrorView` does NOT pass `failure.message` to the user. It uses `l10n.sharedSessionErrorGeneric` — a localized Italian string. This closes the E18R-2 fire for this story. No raw Dart exception string is ever shown.

    **Critical — E18R-1 + E18R-CB1 compliance:** `_LobbyShimmer` uses `SingleChildScrollView` so the shimmer layout is scrollable on small devices, matching the scrollable loaded state (`_LobbyView` and `_SharedInSessionView`). The 360×640 widget test in Task 6 validates this.

    **Critical — `steps.clamp(0, steps.length - 1)`:** Guards against a race where a `step_advanced` broadcast for an out-of-bounds stepIndex arrives (e.g. a follower reconnects mid-session). Displays the last valid step without crashing.

    **Note — `SharedSessionLobbyPage` does NOT use `InSessionView` directly:** `InSessionView` is tightly coupled to `InSessionState` (from `InSessionCubit`). Creating a new `_SharedInSessionView` avoids coupling and keeps `InSessionView` unchanged (zero regression risk for solo sessions).

  - [x] 5.2 Add four ARB keys to `pulse_coach/lib/l10n/app/app_en.arb` and `app_it.arb`:

    English (`app_en.arb`):
    ```json
    "sharedSessionLobbyTitle": "Waiting Room",
    "sharedSessionLobbyWaiting": "Waiting for participants...",
    "sharedSessionStartButton": "Start",
    "sharedSessionWaitingForHost": "Waiting for host to start...",
    "sharedSessionErrorGeneric": "Connection error. Please try again."
    ```

    Italian (`app_it.arb`):
    ```json
    "sharedSessionLobbyTitle": "Sala d'attesa",
    "sharedSessionLobbyWaiting": "In attesa dei partecipanti...",
    "sharedSessionStartButton": "Avvia",
    "sharedSessionWaitingForHost": "In attesa che l'host avvii la sessione...",
    "sharedSessionErrorGeneric": "Errore di connessione. Riprova."
    ```

    **Critical — 5 new keys (not 4):** Count above is 5 keys (`sharedSessionLobbyTitle`, `sharedSessionLobbyWaiting`, `sharedSessionStartButton`, `sharedSessionWaitingForHost`, `sharedSessionErrorGeneric`). Add all 5 to both ARB files. After adding, run `flutter pub get` (or `flutter gen-l10n`) to regenerate `AppLocalizations`. The generated files are gitignored; verify `AppLocalizations.of(context)!.sharedSessionLobbyTitle` compiles.

    **Note on `sharedSessionErrorGeneric`:** This is the localized error message required by E18R-2. It replaces the raw `failure.message` passthrough.

- [x] **Task 6 — Route addition (AC3)**

  - [x] 6.1 Add the `sharedSessionLobby` route constant and GoRoute to `pulse_coach/lib/core/routing/app_router.dart`:

    At the constants block, add:
    ```dart
    static const String sharedSessionLobby = '/social/shared-session/lobby';
    ```

    Inside the `router` routes list (after the `socialQr` route):
    ```dart
    GoRoute(
      path: sharedSessionLobby,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! SharedSessionStartArgs) {
          return const SizedBox.shrink();
        }
        return BlocProvider(
          create: (_) => getIt<SharedSessionBloc>()
            ..add(SharedSessionJoined(
              sessionId: extra.sessionId,
              isHost: extra.isHost,
              userId: extra.userId,
              displayHandle: extra.displayHandle,
              steps: extra.steps,
            )),
          child: const SharedSessionLobbyPage(),
        );
      },
    ),
    ```

    Add imports for `SharedSessionBloc`, `SharedSessionStartArgs`, `SharedSessionJoined`, and `SharedSessionLobbyPage` at the top of `app_router.dart`.

    **Critical — `..add(SharedSessionJoined(...))` cascade:** The bloc is created via `getIt<SharedSessionBloc>()` (which injects `RealtimeGateway`) and immediately receives the `SharedSessionJoined` event. This triggers `joinChannel`, `trackPresence`, and stream subscriptions in the bloc before the first frame renders.

    **Critical — `extra is! SharedSessionStartArgs` guard:** If the route is navigated to without the correct `extra` type (e.g. deep link with no args), show an empty screen rather than crash. Story 20.1 will always supply the correct `SharedSessionStartArgs` via `context.push(AppRouter.sharedSessionLobby, extra: args)`.

- [x] **Task 7 — Tests (AC1–AC5, E18R-1)**

  - [x] 7.1 Create `pulse_coach/test/bloc/shared_session/shared_session_bloc_test.dart`:

    ```dart
    // [19.2-BLOC-001..012] SharedSessionBloc unit tests
    import 'dart:async';

    import 'package:bloc_test/bloc_test.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:mockito/annotations.dart';
    import 'package:mockito/mockito.dart';
    import 'package:pulse_coach/core/cloud/realtime_gateway.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
    import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
    import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
    import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';

    @GenerateNiceMocks([MockSpec<RealtimeGateway>()])
    import 'shared_session_bloc_test.mocks.dart';

    const _kSteps = [
      ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 60),
      ExerciseStep(title: 'Cardio', instruction: 'Run', durationSeconds: 120),
    ];

    SharedSessionJoined _hostJoin({String sessionId = 'sess-1'}) =>
        SharedSessionJoined(
          sessionId: sessionId,
          isHost: true,
          userId: 'host-uid',
          displayHandle: 'alice',
          steps: _kSteps,
        );

    SharedSessionJoined _followerJoin({String sessionId = 'sess-1'}) =>
        SharedSessionJoined(
          sessionId: sessionId,
          isHost: false,
          userId: 'follower-uid',
          displayHandle: 'bob',
          steps: _kSteps,
        );

    void main() {
      late MockRealtimeGateway mockGateway;
      late StreamController<BroadcastEvent> broadcastController;
      late StreamController<PresenceState> presenceController;

      setUp(() {
        mockGateway = MockRealtimeGateway();
        broadcastController = StreamController<BroadcastEvent>.broadcast();
        presenceController = StreamController<PresenceState>.broadcast();
        when(mockGateway.broadcastEvents).thenAnswer((_) => broadcastController.stream);
        when(mockGateway.presenceUpdates).thenAnswer((_) => presenceController.stream);
        when(mockGateway.joinChannel(any)).thenAnswer((_) async {});
        when(mockGateway.trackPresence(userId: anyNamed('userId'), displayHandle: anyNamed('displayHandle'))).thenAnswer((_) async {});
        when(mockGateway.leaveChannel()).thenAnswer((_) async {});
        when(mockGateway.sendBroadcast(event: anyNamed('event'), payload: anyNamed('payload'))).thenAnswer((_) async {});
        when(mockGateway.untrackPresence()).thenAnswer((_) async {});
      });

      tearDown(() {
        broadcastController.close();
        presenceController.close();
      });

      group('SharedSessionBloc (19.2)', () {
        test('19.2-BLOC-001: initial state is SharedSessionState.initial', () {
          final bloc = SharedSessionBloc(mockGateway);
          expect(bloc.state, const SharedSessionState.initial());
          bloc.close();
        });

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-002: SharedSessionJoined → loading → lobby',
          build: () => SharedSessionBloc(mockGateway),
          act: (bloc) => bloc.add(_hostJoin()),
          expect: () => [
            const SharedSessionState.loading(),
            SharedSessionState.lobby(
              participants: const [],
              isHost: true,
              steps: _kSteps,
            ),
          ],
        );

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-003: joinChannel failure → error state',
          build: () {
            when(mockGateway.joinChannel(any)).thenThrow(Exception('ws failure'));
            return SharedSessionBloc(mockGateway);
          },
          act: (bloc) => bloc.add(_hostJoin()),
          expect: () => [
            const SharedSessionState.loading(),
            isA<_Error>().having(
              (s) => s.failure,
              'failure',
              isA<RealtimeFailure>(),
            ),
          ],
        );

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-004: PresenceState update → lobby.participants updated',
          build: () => SharedSessionBloc(mockGateway),
          act: (bloc) async {
            bloc.add(_hostJoin());
            await Future<void>.delayed(Duration.zero);
            presenceController.add(const PresenceState(participants: [
              ParticipantPresence(userId: 'host-uid', displayHandle: 'alice'),
              ParticipantPresence(userId: 'follower-uid', displayHandle: 'bob'),
            ]));
          },
          expect: () => [
            const SharedSessionState.loading(),
            SharedSessionState.lobby(participants: const [], isHost: true, steps: _kSteps),
            SharedSessionState.lobby(
              participants: const [
                ParticipantPresence(userId: 'host-uid', displayHandle: 'alice'),
                ParticipantPresence(userId: 'follower-uid', displayHandle: 'bob'),
              ],
              isHost: true,
              steps: _kSteps,
            ),
          ],
        );

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-005: SessionStartTapped with <2 participants → no broadcast',
          build: () => SharedSessionBloc(mockGateway),
          act: (bloc) async {
            bloc.add(_hostJoin());
            await Future<void>.delayed(Duration.zero);
            bloc.add(const SessionStartTapped());
          },
          verify: (_) {
            verifyNever(mockGateway.sendBroadcast(
              event: 'session_started',
              payload: anyNamed('payload'),
            ));
          },
        );

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-006: follower cannot dispatch session_started (AC1)',
          build: () => SharedSessionBloc(mockGateway),
          act: (bloc) async {
            bloc.add(_followerJoin());
            await Future<void>.delayed(Duration.zero);
            // Even if a follower somehow dispatches SessionStartTapped, nothing is broadcast
            bloc.add(const SessionStartTapped());
          },
          verify: (_) {
            verifyNever(mockGateway.sendBroadcast(
              event: 'session_started',
              payload: anyNamed('payload'),
            ));
          },
        );

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-007: BroadcastEvent.sessionStarted → all move to inSession (AC4)',
          build: () => SharedSessionBloc(mockGateway),
          act: (bloc) async {
            bloc.add(_hostJoin());
            await Future<void>.delayed(Duration.zero);
            broadcastController.add(const BroadcastEvent.sessionStarted());
          },
          expect: () => [
            const SharedSessionState.loading(),
            SharedSessionState.lobby(participants: const [], isHost: true, steps: _kSteps),
            SharedSessionState.inSession(
              stepIndex: 0,
              elapsedSeconds: 0,
              isHost: true,
              steps: _kSteps,
            ),
          ],
        );

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-008: follower receives stepAdvanced → inSession state updated (AC2)',
          build: () => SharedSessionBloc(mockGateway),
          act: (bloc) async {
            bloc.add(_followerJoin());
            await Future<void>.delayed(Duration.zero);
            broadcastController.add(const BroadcastEvent.sessionStarted());
            await Future<void>.delayed(Duration.zero);
            broadcastController.add(const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 62));
          },
          expect: () => [
            const SharedSessionState.loading(),
            SharedSessionState.lobby(participants: const [], isHost: false, steps: _kSteps),
            SharedSessionState.inSession(stepIndex: 0, elapsedSeconds: 0, isHost: false, steps: _kSteps),
            SharedSessionState.inSession(stepIndex: 1, elapsedSeconds: 62, isHost: false, steps: _kSteps),
          ],
        );

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-009: host ignores echo of own step_advanced broadcast (AC1)',
          build: () => SharedSessionBloc(mockGateway),
          act: (bloc) async {
            bloc.add(_hostJoin());
            await Future<void>.delayed(Duration.zero);
            broadcastController.add(const BroadcastEvent.sessionStarted());
            await Future<void>.delayed(Duration.zero);
            // Simulate the echo of host's own broadcast
            broadcastController.add(const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 65));
          },
          expect: () => [
            const SharedSessionState.loading(),
            SharedSessionState.lobby(participants: const [], isHost: true, steps: _kSteps),
            // Only inSession(0,0) from sessionStarted — the echo of stepAdvanced is ignored
            SharedSessionState.inSession(stepIndex: 0, elapsedSeconds: 0, isHost: true, steps: _kSteps),
          ],
        );

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-010: HostStepAdvanced → sendBroadcast called with correct payload (AC1)',
          build: () => SharedSessionBloc(mockGateway),
          act: (bloc) async {
            bloc.add(_hostJoin());
            await Future<void>.delayed(Duration.zero);
            broadcastController.add(const BroadcastEvent.sessionStarted());
            await Future<void>.delayed(Duration.zero);
            bloc.add(const HostStepAdvanced(stepIndex: 1, elapsedSeconds: 63));
          },
          verify: (_) {
            verify(mockGateway.sendBroadcast(
              event: 'step_advanced',
              payload: {'step_index': 1, 'elapsed_seconds': 63},
            )).called(1);
          },
        );

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-011: follower cannot call sendBroadcast for step_advanced (AC1)',
          build: () => SharedSessionBloc(mockGateway),
          act: (bloc) async {
            bloc.add(_followerJoin());
            await Future<void>.delayed(Duration.zero);
            broadcastController.add(const BroadcastEvent.sessionStarted());
            await Future<void>.delayed(Duration.zero);
            // Follower dispatches HostStepAdvanced — guard must block sendBroadcast
            bloc.add(const HostStepAdvanced(stepIndex: 1, elapsedSeconds: 63));
          },
          verify: (_) {
            verifyNever(mockGateway.sendBroadcast(
              event: 'step_advanced',
              payload: anyNamed('payload'),
            ));
          },
        );

        blocTest<SharedSessionBloc, SharedSessionState>(
          '19.2-BLOC-012: close() calls leaveChannel() (AC6)',
          build: () => SharedSessionBloc(mockGateway),
          act: (bloc) async {
            bloc.add(_hostJoin());
            await Future<void>.delayed(Duration.zero);
            await bloc.close();
          },
          verify: (_) {
            verify(mockGateway.leaveChannel()).called(greaterThanOrEqualTo(1));
          },
        );
      });
    }
    ```

    **Why mock-based bloc tests:** `SharedSessionBloc` depends on `RealtimeGateway`. Unlike `parseBroadcast` (pure function tested in Story 19.1), the bloc's stream subscription behavior requires injecting a controllable stream. `@GenerateNiceMocks([MockSpec<RealtimeGateway>()])` produces a mock that stubs all methods with no-op implementations by default, so each test only configures the stubs it needs.

    **Test `19.2-BLOC-009` (host echo):** Validates AC1 — the host's `inSession` state does NOT change when it receives back the `step_advanced` broadcast it emitted. The expected sequence has only one `inSession(0, 0)` emission, not a second `inSession(1, 65)`.

    **Test `19.2-BLOC-011` (follower guard):** Validates AC1 — even if a follower dispatches `HostStepAdvanced` (which should not happen in production UI, but could happen in a bug), the bloc guard `if (s.isHost) return` prevents the broadcast call.

  - [x] 7.2 Create `pulse_coach/test/widget/shared_session/shared_session_lobby_page_test.dart`:

    ```dart
    // [19.2-WIDGET-001..004] SharedSessionLobbyPage widget tests
    import 'package:bloc_test/bloc_test.dart';
    import 'package:flutter/material.dart';
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:mockito/annotations.dart';
    import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
    import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
    import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
    import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';
    import 'package:pulse_coach/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart';

    @GenerateNiceMocks([MockSpec<SharedSessionBloc>()])
    import 'shared_session_lobby_page_test.mocks.dart';

    const _kSteps = [
      ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 60),
    ];

    Widget _buildTestWidget(
      SharedSessionState state, {
      Size viewportSize = const Size(390, 844),
    }) {
      final mockBloc = MockSharedSessionBloc();
      whenListen(
        mockBloc,
        Stream<SharedSessionState>.value(state),
        initialState: state,
      );
      return MaterialApp(
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
      group('SharedSessionLobbyPage (19.2)', () {
        testWidgets(
          '19.2-WIDGET-001: loading state renders _LobbyShimmer at 390×844',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(390, 844));
            await tester.pumpWidget(
              _buildTestWidget(const SharedSessionState.loading()),
            );
            // Shimmer renders containers (no text participant rows)
            expect(find.byType(Container), findsWidgets);
            expect(find.byType(Text), findsNothing);
          },
        );

        testWidgets(
          '19.2-WIDGET-002: lobby with 1 participant (host) — Start button disabled',
          (tester) async {
            await tester.pumpWidget(
              _buildTestWidget(
                SharedSessionState.lobby(
                  participants: const [
                    ParticipantPresence(userId: 'host', displayHandle: 'alice'),
                  ],
                  isHost: true,
                  steps: _kSteps,
                ),
              ),
            );
            final button = tester.widget<FilledButton>(find.byType(FilledButton));
            expect(button.onPressed, isNull); // disabled when < 2 participants
          },
        );

        testWidgets(
          '19.2-WIDGET-003: lobby with 2 participants (host) — Start button enabled',
          (tester) async {
            await tester.pumpWidget(
              _buildTestWidget(
                SharedSessionState.lobby(
                  participants: const [
                    ParticipantPresence(userId: 'h', displayHandle: 'alice'),
                    ParticipantPresence(userId: 'f', displayHandle: 'bob'),
                  ],
                  isHost: true,
                  steps: _kSteps,
                ),
              ),
            );
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
            // Scrollable must exist so shimmer degrades gracefully on small screens
            expect(find.byType(SingleChildScrollView), findsOneWidget);
            // Should render without overflow
            expect(tester.takeException(), isNull);
          },
        );
      });
    }
    ```

  - [x] 7.3 Run `dart run build_runner build --delete-conflicting-outputs` to generate:
    - `shared_session_state.freezed.dart`
    - `shared_session_bloc_test.mocks.dart` (from `@GenerateNiceMocks` in test file)
    - `shared_session_lobby_page_test.mocks.dart` (from `@GenerateNiceMocks` in widget test)
    - Updated `injection.config.dart`

  - [x] 7.4 Run `flutter test` from `pulse_coach/` — all existing tests plus 12 new tests (12 bloc + 4 widget = 16 total) green.

  - [x] 7.5 Run `flutter analyze lib/ test/` from `pulse_coach/` — 0 issues.

## Dev Notes

### ARCH25 boundary — SharedSessionBloc import restriction

`SharedSessionBloc` is in `lib/features/social/shared_session/presentation/bloc/` and imports ONLY:
- `RealtimeGateway` (from `lib/core/cloud/`) — the typed stream gateway
- `BroadcastEvent`, `PresenceState`, `ParticipantPresence` (from `lib/features/social/shared_session/domain/entities/`)
- `Failure`, `RealtimeFailure` (from `lib/core/error/`)
- Standard Bloc/Dart imports

It does NOT import `supabase_flutter`, `realtime_client`, or any Supabase type. This is the ARCH25 boundary: all Supabase-specific code is isolated in `lib/core/cloud/`.

### Host-authority design rationale (ARCH21)

The host-authority pattern prevents session divergence:
- The host's `InSessionCubit` runs locally (same as a solo session timer).
- When the cubit advances a step, the wiring widget (in Story 20.4) dispatches `HostStepAdvanced(stepIndex, elapsedSeconds)` to `SharedSessionBloc`.
- `SharedSessionBloc` calls `sendBroadcast('step_advanced', ...)`.
- All followers (including the host, which receives its own echo) get the broadcast.
- The host ignores its own echo (`if (s.isHost) return` in `_onBroadcastReceived`).
- Followers update their `inSession` state from the broadcast, correcting timer drift.

This means the host's session display is driven by `InSessionCubit` (the local timer), while followers' displays are driven by `SharedSessionBloc` (the received broadcast state). Story 20.4 ("Synchronized In-Session View") will wire them together in the UI.

### State machine for `SharedSessionBloc`

```
initial → [SharedSessionJoined] → loading → [joinChannel success] → lobby
lobby → [PresenceUpdated] → lobby (participants updated)
lobby → [BroadcastEvent.sessionStarted] → inSession
lobby → [SessionStartTapped, isHost=true, ≥2 participants] → (sends broadcast, stays in lobby until echo fires)
inSession → [BroadcastEvent.stepAdvanced, isHost=false] → inSession (updated step)
inSession → [HostStepAdvanced, isHost=true] → (sends broadcast, state unchanged locally)
inSession → [BroadcastEvent.sessionEnded] → initial (+ leaveChannel)
any → [joinChannel failure] → error
```

**Note — `SessionStartTapped` does NOT immediately transition to `inSession`:** The host stays in `lobby` state after tapping Start. The transition to `inSession` happens only when `BroadcastEvent.sessionStarted()` is received — which fires for the host too (Supabase echoes the broadcast). This ensures all participants (host + followers) enter `inSession` from the same signal.

### Why `@injectable` and not `@singleton` for SharedSessionBloc

`RealtimeGateway` is `@singleton` (one gateway for the app lifetime). `SharedSessionBloc` is `@injectable` (one bloc per session page). The bloc subscribes to `RealtimeGateway` streams and closes them on `close()`. If it were a singleton, the stream subscriptions would leak across sessions. Creating a fresh `SharedSessionBloc` instance per lobby page navigation ensures clean lifecycle management.

### Follower step drift correction

The `elapsedSeconds` in `BroadcastEvent.stepAdvanced` is the host's elapsed time for the session (total seconds since start). When the follower's `inSession` state is updated, the display shows the host's elapsed time. If the follower's local page has been rendering for a different duration (network delay), this snap-correction normalizes the display. This is not a perfect sync (there is inherent network RTT), but it satisfies NFR31 (~1s sync).

### `leaveChannel()` double-call safety

`SharedSessionBloc.close()` calls `_gateway.leaveChannel()`. The route builder also does NOT explicitly call `leaveChannel()` — the bloc `close()` is the authoritative teardown. `RealtimeGateway.leaveChannel()` is safe to call multiple times: the `_channel == null` guard after the first call means subsequent calls are no-ops.

### E9-K1 fire-check: Category A deliverable `E18R-1` — shimmer test action

The `19.2-WIDGET-004` test at `360×640` fulfills the E18R-1 requirement for this story: the `_LobbyShimmer` widget is verified to render without overflow at the small-device viewport size. `SingleChildScrollView` is verified to be present, satisfying the E18R-CB1 "scrollable shimmer" review rule.

### supabase_flutter version note

`supabase_flutter: ^2.9.0` (same as Story 19.1). No version changes in this story. The `RealtimeGateway` API table from Story 19.1 dev notes applies without change.

### New ARB keys: `app_localizations.dart` compilation check

After adding the 5 new ARB keys, run `flutter pub get` to regenerate the `AppLocalizations` class. Verify:
1. `l10n.sharedSessionLobbyTitle` — compiles
2. `l10n.sharedSessionLobbyWaiting` — compiles
3. `l10n.sharedSessionStartButton` — compiles
4. `l10n.sharedSessionWaitingForHost` — compiles
5. `l10n.sharedSessionErrorGeneric` — compiles

If `flutter analyze` reports `undefined getter` for any of these, the ARB key name does not match the Dart identifier (usually camelCase mismatch). Fix the ARB key name.

### Directory structure created by this story

```
pulse_coach/
  lib/core/routing/
    app_router.dart                                                    # MODIFIED (+sharedSessionLobby route)

  lib/features/social/shared_session/
    domain/entities/
      shared_session_start_args.dart                                   # NEW
    presentation/bloc/
      shared_session_bloc.dart                                         # NEW (@injectable)
      shared_session_event.dart                                        # NEW
      shared_session_state.dart                                        # NEW (freezed sealed)
      shared_session_state.freezed.dart                                # GENERATED
    presentation/pages/
      shared_session_lobby_page.dart                                   # NEW

  lib/l10n/app/
    app_en.arb                                                         # MODIFIED (+5 keys)
    app_it.arb                                                         # MODIFIED (+5 keys)

  lib/core/di/
    injection.config.dart                                              # REGENERATED (build_runner)

  test/bloc/shared_session/
    shared_session_bloc_test.dart                                      # NEW (12 bloc tests)
    shared_session_bloc_test.mocks.dart                                # GENERATED

  test/widget/shared_session/
    shared_session_lobby_page_test.dart                                # NEW (4 widget tests, incl. E18R-1)
    shared_session_lobby_page_test.mocks.dart                          # GENERATED

_bmad-output/implementation-artifacts/
  sprint-status.yaml                                                   # MODIFIED (19-2 → ready-for-dev)
```

No new Supabase migrations in this story. The `shared_sessions` table is Story 20.1.

### References

- Epic 19 Story 19.2 ACs: `_bmad-output/planning-artifacts/epics.md` line ~2554
- Epic 19 Story 19.1 (done): `_bmad-output/implementation-artifacts/19-1-realtime-gateway-and-supabase-broadcast-presence-channel.md`
- Architecture — host authority: `_bmad-output/planning-artifacts/architecture.md` line ~786
- Architecture — realtime data flow: `_bmad-output/planning-artifacts/architecture.md` line ~1396
- Architecture — directory structure: `_bmad-output/planning-artifacts/architecture.md` line ~1328
- ARCH25 boundary comment: `pulse_coach/lib/core/cloud/realtime_gateway.dart:1`
- `RealtimeGateway` implementation: `pulse_coach/lib/core/cloud/realtime_gateway.dart`
- `BroadcastEvent` / `PresenceState` entities: `pulse_coach/lib/features/social/shared_session/domain/entities/`
- `RealtimeFailure`: `pulse_coach/lib/core/error/failures.dart`
- `InSessionView` (reference for _SharedInSessionView layout pattern): `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart`
- `FriendsBloc` (reference for @injectable Bloc pattern): `pulse_coach/lib/features/social/friends/presentation/bloc/friends_bloc.dart`
- Action-item ledger (E9-K1 fire-check + Category A): `_bmad-output/implementation-artifacts/action-item-ledger.md`
- `app_router.dart` (route constants + GoRouter): `pulse_coach/lib/core/routing/app_router.dart`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

- Task 1: `SharedSessionStartArgs` created as plain Dart class in `domain/entities/`.
- Task 2: `SharedSessionState` freezed sealed class created; `build_runner` generated `shared_session_state.freezed.dart`. Note: `state.map(...)` API used in page (not native Dart switch patterns) because freezed generates private concrete types (`_Initial` etc.) that are inaccessible from other files.
- Task 3: `SharedSessionEvent` sealed class created. `PresenceStateReceived` and `BroadcastEventReceived` internal events moved back to the event file (without underscore) because Dart sealed classes require all subtypes to be in the same file as the sealed declaration — underscore-prefixed types would be inaccessible from the bloc file.
- Task 4: `SharedSessionBloc` created with `@injectable`. Host echo guard (`if (s.isHost) return`) confirmed working via test 19.2-BLOC-009. `close()` cancels subscriptions and calls `leaveChannel()`.
- Task 5: `SharedSessionLobbyPage` created. `_LobbyShimmer` uses `SingleChildScrollView` (E18R-1 compliance). `_ErrorView` uses `l10n.sharedSessionErrorGeneric` (E18R-2/E18R-CB2 compliance). `Semantics(liveRegion: true)` on step name widget (AC5). 5 ARB keys added to both `app_en.arb` and `app_it.arb`.
- Task 6: `sharedSessionLobby` route added to `app_router.dart` after `socialQr`. `SharedSessionJoined` dispatched via cascade on bloc creation.
- Task 7: 12 bloc tests + 4 widget tests green. Widget tests use `@GenerateMocks` + `when(mock.state).thenReturn(state)` + `provideDummy<SharedSessionState>(...)` in `setUp` (same pattern as today_page_test). Full suite: 1123/1123. `flutter analyze`: 0 issues.

### File List

- `pulse_coach/lib/features/social/shared_session/domain/entities/shared_session_start_args.dart` — NEW
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.dart` — NEW
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.freezed.dart` — GENERATED
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_event.dart` — NEW
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart` — NEW
- `pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart` — NEW
- `pulse_coach/lib/l10n/app/app_en.arb` — MODIFIED (+5 keys)
- `pulse_coach/lib/l10n/app/app_it.arb` — MODIFIED (+5 keys)
- `pulse_coach/lib/l10n/app_localizations_en.dart` — REGENERATED
- `pulse_coach/lib/l10n/app_localizations_it.dart` — REGENERATED
- `pulse_coach/lib/l10n/app_localizations.dart` — REGENERATED
- `pulse_coach/lib/core/routing/app_router.dart` — MODIFIED (+sharedSessionLobby route)
- `pulse_coach/lib/core/di/injection.config.dart` — REGENERATED (SharedSessionBloc factory added)
- `pulse_coach/test/bloc/shared_session/shared_session_bloc_test.dart` — NEW (12 tests)
- `pulse_coach/test/bloc/shared_session/shared_session_bloc_test.mocks.dart` — GENERATED
- `pulse_coach/test/widget/shared_session/shared_session_lobby_page_test.dart` — NEW (4 tests)
- `pulse_coach/test/widget/shared_session/shared_session_lobby_page_test.mocks.dart` — GENERATED
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED (19-2 → review)

### Review Findings

_Code review 2026-06-25 (Opus 4.8, 3-layer adversarial: Blind Hunter + Edge Case Hunter + Acceptance Auditor). AC6 verified independently: `flutter analyze lib/ test/` → 0 issues; full suite 1123/1123 green. AC1–AC5, E18R-1, E18R-2/CB2 functionally satisfied._

#### Decision-needed (all resolved → patched 2026-06-25)

- [x] [Review][Decision→Patch] **Resolved: patched the 19.1 gateway now.** `RealtimeGateway.joinChannel` now creates the channel with `opts: const RealtimeChannelConfig(self: true)` so the host receives its own broadcast echo [realtime_gateway.dart].
- [x] [Review][Decision→Patch] **Resolved: guard added now.** Gateway enforces the single-active-session invariant (`joinChannel` throws `StateError` on a concurrent *different* session); bloc tracks a `_joined` ownership flag so a bloc that never owned the channel does not `leaveChannel()` on `close()`/`SessionEnded`.
- [x] [Review][Decision→Patch] **Resolved: pinned.** `connectivity_plus_platform_interface` pinned to `^2.0.1` (was `any`) and moved back into the `dev_dependencies` block.

<details><summary>Original decision text</summary>

- [ ] [Review][Decision] Host self-echo dependency is unbacked by the gateway config — `SharedSessionBloc` transitions the host from `lobby`→`inSession` ONLY on receiving its own `session_started` echo (spec dev-note: "Supabase echoes the broadcast"), but `RealtimeGateway.joinChannel` creates the channel via `client.channel('shared-session:$sessionId')` with the default `RealtimeChannelConfig` (`self: false`) [pulse_coach/lib/core/cloud/realtime_gateway.dart:38]. By Supabase default the sender does NOT receive its own broadcast → at runtime the host stays stuck in the lobby while followers enter the session (breaks AC4 host path). Tests pass only because they inject the echo manually via `broadcastController.add(...)`. Fix is a one-liner (`opts: const RealtimeChannelConfig(broadcast: BroadcastConfig(self: true))`) but it edits Story 19.1's already-`done` gateway file. **Decision:** patch the 19.1 gateway now / file as a separate 19.1 defect / change the host transition to not rely on echo.
- [ ] [Review][Decision] Singleton gateway + factory bloc lifecycle coupling — `RealtimeGateway` is `@singleton`, `SharedSessionBloc` is `@factory`. A second `SharedSessionJoined` (re-entrant nav, deep link re-fire) calls `joinChannel`, which `leaveChannel()`s and closes the controllers the first live bloc is still listening to → first bloc goes silently deaf. Symmetrically, `close()` on one bloc unconditionally `leaveChannel()`s the shared channel, killing any concurrent session. No ref-count/ownership guard. **Decision:** accept & document the single-active-session invariant (defer real fix to 19.3) / add a guard now.
- [ ] [Review][Decision] `connectivity_plus_platform_interface: any` added to `pubspec.yaml` dev_dependencies [pulse_coach/pubspec.yaml:102] — untraceable to Story 19.2 (no mention in spec/File List). It IS load-bearing for an unrelated generated mock (`test/core/sync/sync_manager_test.mocks.dart:9` imports it directly, so it satisfies `depend_on_referenced_packages`), but the `any` constraint violates the repo's no-`any` norm. **Decision:** pin to a real version / keep as-is / move to a separate chore commit.

</details>

#### Patch (all applied 2026-06-25)

- [x] [Review][Patch] Empty / out-of-bounds `steps` crashes the in-session view [pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart] — `steps[stepIndex.clamp(0, steps.length - 1)]` throws on empty `steps` (`clamp(0,-1)`), and `LinearProgressIndicator(value: (stepIndex+1)/totalSteps)` divides by zero (Infinity → debug assert). Out-of-range `stepIndex` from a broadcast (only `steps[]` is clamped, not the label/progress) renders garbage / negative progress. `SharedSessionStartArgs.steps` is `required` but never validated non-empty. Add bounds guards (empty-steps fallback + clamp stepIndex for label/progress).
- [x] [Review][Patch] AC5/AC2 in-session render path has zero test coverage [pulse_coach/test/widget/shared_session/shared_session_lobby_page_test.dart] — added `19.2-WIDGET-005` asserting liveRegion Semantics + step render. — Task 7 claims "AC1–AC5" but widget tests cover only `loading`/`lobby`. The `inSession` render (AC5 `Semantics(liveRegion:true, label:step.title)`, the clamp guard, timer format) is never exercised; removing the Semantics wrapper would fail no test. Add an `inSession`-state widget test asserting the liveRegion Semantics + step title (and ideally the Start-tap `SessionStartTapped` dispatch, currently untested due to the empty-stream stub).

#### Deferred (real, out of 19.2 scope — mostly 19.3 robustness)

- [x] [Review][Defer] Follower that misses the `session_started` broadcast is stuck in `lobby` forever [shared_session_bloc.dart:_onBroadcastReceived] — `StepAdvanced` requires `inSession`, so a late/dropped `session_started` has no resync path — deferred, 19.3 drop-out/resync scope.
- [x] [Review][Defer] `SessionEnded` emits `initial()` → `BlocBuilder` renders blank `SizedBox.shrink()` with no navigation pop — deferred, spec assigns full teardown to 19.3.
- [x] [Review][Defer] `error` state is a dead-end: `_ErrorView` copy says "Riprova" but there is no retry event/action; join/start failure leaves subscriptions live until `close()` — deferred, page not user-reachable until 20.1 wires navigation.
- [x] [Review][Defer] Route bad/null `extra` → blank `SizedBox.shrink()` (no Scaffold, no escape) [app_router.dart] — deferred, spec-sanctioned; 20.1 owns the navigation entry.
- [x] [Review][Defer] Presence robustness cluster: presence drops during `inSession` ignored (stale count, solo continuation); unparseable `step_advanced` payloads silently dropped (follower drift); duplicate participant identities can inflate the `>=2` start gate — deferred, 19.3 drop-out tolerance + presence dedup.
- [x] [Review][Defer] `_onHostStepAdvanced` swallows broadcast failure with empty `catch (e)` (no log/telemetry) — deferred, observability; 19.3 handles persistent failure.
- [x] [Review][Defer] `_onJoined` subscribes to streams only after `await joinChannel`/`trackPresence` — narrow window where early events are lost; also partial-setup (trackPresence throws after joinChannel) leaves a subscribed channel until `close()` — deferred, minor; host subscribes well before any start in practice.

#### Dismissed as noise (7)

`_onPresenceReceived` no-op `inSession` arm (style); BLOC-009 weak negative assertion (test still correct); `Future.delayed(Duration.zero)` test-ordering smell (passing); "verify gateway is singleton" (confirmed `@singleton`); and the 3 spec deviations the dev flagged — `state.map` vs `switch`, internal events without `_` prefix, `@GenerateMocks`+`provideDummy` vs `@GenerateNiceMocks`+`whenListen` — all forced by Dart/freezed language constraints and preserve the intended guarantees (exhaustiveness + host-authority guards hold).

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2026-06-25 | 1.0.0 | Story created. | claude-sonnet-4-6 |
| 2026-06-25 | 1.1.0 | Story implemented: SharedSessionBloc + SharedSessionLobbyPage + route + 16 tests. All ACs satisfied. | claude-sonnet-4-6 |
