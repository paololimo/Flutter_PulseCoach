---
baseline_commit: cb04242
---

# Story 19.3: Drop-Out Tolerance and Reconnect

Status: done

## Story

As a shared session participant,
I want the session to continue uninterrupted if another participant drops out or loses connectivity,
So that a network issue for one person does not ruin the session for everyone else.

## Context

Stories 19.0–19.2 (`done`) delivered the full shared-session Realtime infrastructure:
- `RealtimeGateway` (19.1) — typed Dart stream wrapper over Supabase Realtime Broadcast + Presence
- `SharedSessionBloc` + `SharedSessionLobbyPage` (19.2) — host-authority step advancement, presence lobby, `session_started` synchronization

Story 19.3 closes the final Epic 19 deliverable: **drop-out tolerance**. Specifically:

1. **AC1** — When a participant's Presence entry disappears mid-session, all remaining participants' blocs emit `inSession` with a `droppedHandle` note (inline "[handle] si è disconnesso"), and the session continues uninterrupted.
2. **AC2** — A dropped participant who regains connectivity re-joins Presence and snaps to the current step via the host's next `step_advanced` broadcast. Also closes Story 19.2 deferred item: "follower stuck in lobby forever on missed `session_started`" — handled by the same code path.
3. **AC3** — If the **host** drops, leadership transfers to the alphabetically-first remaining userId; that participant's bloc sets `_isHost = true` (and `inSession.isHost = true`) so Story 20.4's wiring starts dispatching `HostStepAdvanced` from their `InSessionCubit`.
4. **AC4** — When `session_ended` broadcast fires, `RealtimeGateway.leaveChannel()` is called and `SharedSessionBloc` emits `SharedSessionState.sessionEnded()` (a terminal state the page can use to trigger RPE navigation). Also closes 19.2 deferred item: "`SessionEnded` emitting `initial()` with no navigation pop".

**This story does NOT include:**
- RPE input wiring — this is Story 20.4 + 20.5.
- The `session_ended` broadcast initiation — the host emitting it when all steps complete is Story 20.4 (though the `SessionEndRequested` event and the host's send path ARE implemented here so Story 20.4 only needs to dispatch the event).
- Joining a session already in progress (late join via join code) — Story 20.3 / 20.4 concern.

**19.2 deferred items explicitly closed by this story:**
- `[Review][Defer]` Follower that misses `session_started` is stuck in lobby forever → closed by AC2 (`StepAdvanced` while in `lobby` transitions follower to `inSession`).
- `[Review][Defer]` `SessionEnded` emits `initial()` with no navigation pop → closed by AC4 (`sessionEnded()` state).
- `[Review][Defer]` Presence drops during `inSession` ignored → closed by AC1/AC3.
- `[Review][Defer]` `_onHostStepAdvanced` swallows broadcast failure silently → **not a 19.3 target** (observability; no logging infrastructure for this scope).

**E9-K1 fire-check for Story 19.3:**

| Item | Fires? | Required action |
|---|---|---|
| `E18R-1` small-viewport shimmer (360×640) | ❌ | No new shimmer/loading screen added; `_LobbyShimmer` 360×640 test already exists from 19.2. |
| `E18R-2` backend-failure localized IT | ✅ **YES** — `_SessionEndedView` is a new UI surface; `droppedHandle` note must be localized | Use `l10n.sharedSessionParticipantDropped(handle)` and `l10n.sharedSessionEnded`; no raw Dart string to user. |
| `E18R-CB2` localized-IT review check | ✅ **YES** — same surface | Review-layer: verify no raw `failure.message` in new UI paths. |
| `E10R-2` non-UTC week-bucketing | ❌ | No Progress/chart code. |
| `E18R-4` social ProUpsellSheet copy | ❌ | No ProUpsellSheet touch. |
| `E6-P1` cross-cutting DI/lifecycle patches | Partial | `RealtimeGateway.trackPresence` signature change (adds `isHost: bool`). Only one caller (`SharedSessionBloc._onJoined`). Not broadly cross-cutting but note the API change in dev notes so code review scrutinizes it. |

**Category A snapshot entering sprint (Story 19.3): 4 / 5.** Active: `E18R-1`, `E18R-2`, `E10R-2`, `E18R-4`. Cap satisfied.

## Acceptance Criteria

**AC1 — Drop-out detected and session continues (NFR31):**
Given a follower's Presence entry disappears from the channel mid-session
When `SharedSessionBloc._onPresenceReceived` processes the presence update during `inSession` state
Then the bloc emits `SharedSessionState.inSession` with `droppedHandle` set to the dropped participant's `displayHandle` (or `userId` if no handle); the session for remaining participants is uninterrupted; an inline note "[handle] si è disconnesso" is rendered in `_SharedInSessionView`; the note clears on the next `step_advanced` broadcast (i.e. next `copyWith(droppedHandle: null)`)

**AC2 — Dropped participant reconnects and snaps to current position:**
Given a participant drops out (their Presence entry disappears) and then regains connectivity (re-joins Presence)
When their `SharedSessionBloc` receives the next `step_advanced` broadcast while in either `lobby` or `inSession` state
Then if in `lobby`, they transition directly to `inSession` with the received `stepIndex` and `elapsedSeconds`, snapping to the group's current position; if already in `inSession`, the existing 19.2 `copyWith(stepIndex: idx, elapsedSeconds: elapsed)` path handles it unchanged

**AC3 — Host drop-out triggers leadership transfer:**
Given the host's Presence entry disappears from the channel mid-session
When `SharedSessionBloc._onPresenceReceived` fires during `inSession` state
Then the bloc computes the new host as the lexicographically-first remaining `userId` from the presence participants; if `_myUserId == newHostUserId`, the bloc sets its `_isHost = true` instance variable AND emits `inSession.copyWith(isHost: true, ...)`; subsequent `HostStepAdvanced` events now pass the `if (inSessionState == null || !inSessionState.isHost) return` guard and call `sendBroadcast`; if `_myUserId != newHostUserId`, the bloc updates participants and emits the drop note but does NOT change `isHost`

**AC4 — Session ended: proper cleanup and terminal state:**
Given the host dispatches `SessionEndRequested` (or any participant receives `BroadcastEvent.sessionEnded()`)
When `SharedSessionBloc` handles the event or the broadcast
Then it calls `_gateway.leaveChannel()` (guarded by `_joined` flag), cancels stream subscriptions, and emits `SharedSessionState.sessionEnded()`; `SharedSessionLobbyPage` renders `_SessionEndedView` showing a localized "Sessione terminata" message (E18R-2); this is the terminal state from which Story 20.4 will wire RPE navigation

**AC5 — Zero regressions:**
Given all new files and `build_runner` outputs are in place
When `flutter test` and `flutter analyze lib/ test/` are run from `pulse_coach/`
Then all existing 1123 tests pass plus all new 14 tests pass; analyzer reports 0 issues

## Tasks / Subtasks

---

### Task 1 — `ParticipantPresence` entity: add `isHost` field (AC1, AC3)

**Why:** The bloc needs to know which presence entry belongs to the host in order to detect host drop-out and trigger leadership transfer (AC3). Encoding it in the presence payload (vs. a separate tracking variable) keeps all participant metadata in one place and makes it queryable from the presence stream.

- [x] **1.1** Edit `pulse_coach/lib/features/social/shared_session/domain/entities/presence_state.dart`:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'presence_state.freezed.dart';

  @freezed
  abstract class PresenceState with _$PresenceState {
    const factory PresenceState({
      required List<ParticipantPresence> participants,
    }) = _PresenceState;
  }

  @freezed
  abstract class ParticipantPresence with _$ParticipantPresence {
    const factory ParticipantPresence({
      required String userId,
      String? displayHandle,
      @Default(false) bool isHost,    // NEW — true for the session host
    }) = _ParticipantPresence;
  }
  ```

  **Critical — `@Default(false)`:** All existing test fixtures and production code that create `ParticipantPresence(userId: ..., displayHandle: ...)` without `isHost` continue to compile unchanged because `@Default(false)` provides the missing positional-free value.

  **Critical — `is_host` in presence payload:** The `isHost` field here is populated by `RealtimeGateway._emitPresenceState` from the `is_host` key in the Supabase presence payload. It is NOT inferred from position or alphabetical order — it comes directly from what each participant tracked when they joined.

- [x] **1.2** Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`. Verify `presence_state.freezed.dart` regenerates with `isHost` in the `copyWith` method.

---

### Task 2 — `RealtimeGateway`: propagate `isHost` through presence (AC3)

- [x] **2.1** Edit `pulse_coach/lib/core/cloud/realtime_gateway.dart` — update `trackPresence` and `_emitPresenceState`:

  ```dart
  Future<void> trackPresence({
    required String userId,
    String? displayHandle,
    bool isHost = false,             // NEW parameter
  }) async {
    final channel = _channel;
    if (channel == null) {
      throw StateError('trackPresence called before joinChannel');
    }
    await channel.track({
      'user_id': userId,
      'display_handle': displayHandle,
      'is_host': isHost,             // NEW field in presence payload
    });
  }
  ```

  ```dart
  void _emitPresenceState() {
    final rawState = _channel?.presenceState() ?? [];
    final participants = rawState.expand((s) => s.presences).map((p) {
      final userId = p.payload['user_id'];
      final displayHandle = p.payload['display_handle'];
      final isHost = p.payload['is_host'];            // NEW
      return ParticipantPresence(
        userId: userId is String ? userId : '',
        displayHandle: displayHandle is String ? displayHandle : null,
        isHost: isHost is bool && isHost,              // NEW — safe parse; default false
      );
    }).toList();
    _presenceController?.add(PresenceState(participants: participants));
  }
  ```

  **Critical — `trackPresence` signature change:** The only caller is `SharedSessionBloc._onJoined` (Task 5.2). Update it to pass `isHost: event.isHost`. No other callers exist in the codebase.

  **Critical — safe bool parse:** `isHost is bool && isHost` guards against a non-bool payload value (e.g. a null or string from a future protocol version) defaulting to `false` rather than throwing.

  **No changes to `untrackPresence`, `sendBroadcast`, `joinChannel`, `leaveChannel`.** The `parseBroadcast` method is also unchanged.

---

### Task 3 — `SharedSessionState`: add `participants` + `droppedHandle` to `inSession`; add `sessionEnded` (AC1, AC3, AC4)

- [x] **3.1** Edit `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.dart`:

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
      @Default([]) List<ParticipantPresence> participants,   // NEW — needed for drop detection + host transfer
      String? droppedHandle,                                  // NEW — non-null shows "[handle] si è disconnesso"
    }) = _InSession;

    const factory SharedSessionState.error({
      required Failure failure,
    }) = _Error;

    const factory SharedSessionState.sessionEnded() = _SessionEnded;  // NEW (AC4)
  }
  ```

  **Critical — `@Default([])` for `participants`:** All existing callers of `SharedSessionState.inSession(stepIndex: ..., elapsedSeconds: ..., isHost: ..., steps: ...)` continue to compile unchanged. Do NOT add `required` to these fields.

  **Critical — `droppedHandle: String?`:** Nullable with no default. When null, no drop-out note is shown. When non-null, the handle is displayed inline. Cleared by passing `droppedHandle: null` in `copyWith` — this works in freezed 3.x because the generated `copyWith` distinguishes `null` (explicit clear) from the `freezed` sentinel (preserve existing) via the parameter default.

  **Critical — `_SessionEnded` is now a case in `SharedSessionLobbyPage`'s exhaustive switch.** The switch will fail to compile until Task 6.1 adds the `_SessionEnded()` arm.

  **Critical — WHY `participants` in `inSession` and not a separate bloc field:** The bloc could maintain `_currentParticipants` as an instance variable. However, embedding it in the state means the UI always has a consistent snapshot (useful for Story 20.4's "show other participants' names during session"), and bloc tests can assert the full state including participants without accessing private instance vars.

- [x] **3.2** Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`. Verify `shared_session_state.freezed.dart` regenerates with `participants` and `droppedHandle` in `_InSession.copyWith`.

---

### Task 4 — `SharedSessionEvent`: add `SessionEndRequested` (AC4)

- [x] **4.1** Edit `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_event.dart`. Add after `HostStepAdvanced`:

  ```dart
  /// Host signals that the session is complete (all steps done or manual end).
  /// Only the host dispatches this; the bloc guards against non-host dispatch.
  /// Story 20.4 wires the InSessionCubit's completion callback to dispatch this.
  final class SessionEndRequested extends SharedSessionEvent {
    const SessionEndRequested();
  }
  ```

  No other changes to the event file.

---

### Task 5 — `SharedSessionBloc`: drop-out, reconnect, host transfer, session-ended (AC1–AC4)

This is the core logic task. All changes are in `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`.

- [x] **5.1** Add instance variable declarations (after `bool _joined = false;`):

  ```dart
  String? _myUserId;      // Set on SharedSessionJoined; used for host transfer comparison
  bool _isHost = false;   // Mirrors event.isHost; updated on leadership transfer (AC3)
  ```

  **Critical:** `_isHost` is the mutable bloc-level authority flag. `SharedSessionState.inSession.isHost` reflects it in the emitted state. Story 20.4 reads `state.isHost` to decide whether to dispatch `HostStepAdvanced`, so both must stay in sync.

- [x] **5.2** Update `_onJoined` — set instance vars, pass `isHost` to `trackPresence`, initialize `participants` in lobby:

  ```dart
  Future<void> _onJoined(
      SharedSessionJoined event, Emitter<SharedSessionState> emit) async {
    emit(const SharedSessionState.loading());
    _myUserId = event.userId;     // NEW
    _isHost = event.isHost;       // NEW
    try {
      await _gateway.joinChannel(event.sessionId);
      _joined = true;
      await _gateway.trackPresence(
        userId: event.userId,
        displayHandle: event.displayHandle,
        isHost: event.isHost,     // NEW — encodes host role in presence payload
      );
      _broadcastSub = _gateway.broadcastEvents.listen(
        (e) => add(BroadcastEventReceived(e)),
      );
      _presenceSub = _gateway.presenceUpdates.listen(
        (s) => add(PresenceStateReceived(s)),
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
  ```

- [x] **5.3** Update `_onPresenceReceived` — add drop detection, leadership transfer (AC1, AC3):

  Replace the current `_onPresenceReceived` entirely:

  ```dart
  void _onPresenceReceived(
      PresenceStateReceived event, Emitter<SharedSessionState> emit) {
    state.mapOrNull(
      lobby: (s) =>
          emit(s.copyWith(participants: event.presenceState.participants)),
      inSession: (s) {
        final prev = s.participants;
        final next = event.presenceState.participants;

        // AC1: detect dropped participants for the inline note
        final dropped = prev
            .where((p) => !next.any((n) => n.userId == p.userId))
            .toList();
        final droppedHandle = dropped.isNotEmpty
            ? (dropped.first.displayHandle ?? dropped.first.userId)
            : null;

        // AC3: host leadership transfer
        // If the dropped participant was the host AND we are not already host,
        // elect the lexicographically-first remaining userId as the new host.
        if (!_isHost && dropped.any((p) => p.isHost)) {
          final sortedIds = next.map((p) => p.userId).toList()..sort();
          if (sortedIds.isNotEmpty && sortedIds.first == _myUserId) {
            _isHost = true; // This bloc instance is now the host authority
          }
        }

        emit(s.copyWith(
          participants: next,
          isHost: _isHost,         // may have flipped due to transfer
          droppedHandle: droppedHandle, // null clears the note
        ));
      },
    );
  }
  ```

  **Critical — `droppedHandle: null` when no drops:** When the next presence update fires with no new drops (e.g. a participant re-joins or status changes without a leave), `droppedHandle` is null, clearing the note from the UI. This avoids the note persisting indefinitely.

  **Critical — host election is one-way:** Once `_isHost = true` is set, it is never reverted back to `false` within the same session. If the promoted host also drops, the next participant in alphabetical order would be elected in their own bloc. (In reality, the promoted host's own bloc is gone when they drop, so this is a non-issue.)

  **Critical — leadership transfer in a two-participant session:** If only the host and one follower are in the session, and the host drops, `sortedIds` has one entry (the follower), so the follower becomes the new host immediately. This is correct.

- [x] **5.4** Update `_onBroadcastReceived` — reconnect path for `StepAdvanced`, `sessionEnded` for `SessionEnded` (AC2, AC4):

  Replace the current `_onBroadcastReceived` entirely:

  ```dart
  void _onBroadcastReceived(
      BroadcastEventReceived event, Emitter<SharedSessionState> emit) {
    final broadcast = event.broadcastEvent;
    switch (broadcast) {
      case SessionStarted():
        // Fires for ALL participants (including host). Authoritative lobby→inSession signal.
        state.mapOrNull(
          lobby: (s) => emit(SharedSessionState.inSession(
            stepIndex: 0,
            elapsedSeconds: 0,
            isHost: s.isHost,
            steps: s.steps,
            participants: s.participants,
          )),
        );
      case StepAdvanced(stepIndex: final idx, elapsedSeconds: final elapsed):
        state.mapOrNull(
          inSession: (s) {
            if (s.isHost) return; // Host ignores its own echo
            // Clear droppedHandle on step advance (AC1: note is transient)
            emit(s.copyWith(stepIndex: idx, elapsedSeconds: elapsed, droppedHandle: null));
          },
          // AC2: reconnect path — follower missed session_started (or re-joined mid-session)
          // Snap directly from lobby → inSession at the received position.
          // The follower's bloc is in lobby because: (a) they dropped before session_started
          // and re-joined Presence; or (b) they joined late; or (c) session_started was lost.
          lobby: (s) {
            if (!s.isHost) {
              emit(SharedSessionState.inSession(
                stepIndex: idx,
                elapsedSeconds: elapsed,
                isHost: false,
                steps: s.steps,
                participants: s.participants,
              ));
            }
          },
        );
      case SessionEnded():
        // AC4: terminal state — leaves channel and emits sessionEnded() for RPE navigation
        if (_joined) {
          _joined = false;
          unawaited(_gateway.leaveChannel());
        }
        emit(const SharedSessionState.sessionEnded());
      case UnknownBroadcast():
        break;
    }
  }
  ```

  **Critical — `StepAdvanced` in `lobby` state (AC2):** This closes the 19.2 deferred item "follower stuck in lobby forever on missed `session_started`". A follower who drops+reconnects (or whose initial `session_started` was lost) will snap to the current position when the next `step_advanced` arrives, without requiring a re-send of `session_started`.

  **Critical — `SessionEnded` now emits `sessionEnded()`:** Previously emitted `initial()` (19.2 implementation). Changed to `sessionEnded()` so the page can detect it and navigate to RPE. The `_joined` guard prevents double-`leaveChannel()` calls.

  **Critical — host ignores `StepAdvanced` echo:** Unchanged from 19.2. The host's step display is driven by `InSessionCubit` (solo timer), not by the broadcast echo.

- [x] **5.5** Add `_onSessionEndRequested` handler and register in constructor (AC4):

  In constructor, add:
  ```dart
  on<SessionEndRequested>(_onSessionEndRequested);
  ```

  New handler:
  ```dart
  Future<void> _onSessionEndRequested(
      SessionEndRequested event, Emitter<SharedSessionState> emit) async {
    final inSessionState = state.mapOrNull(inSession: (s) => s);
    if (inSessionState == null || !inSessionState.isHost) return;
    try {
      await _gateway.sendBroadcast(event: 'session_ended', payload: {});
    } catch (e) {
      // Non-fatal: if broadcast fails, the host's own session ends via the
      // received echo (self: true). Followers detect the host dropped via
      // Presence (AC3 leadership transfer) and continue independently.
    }
  }
  ```

  **Critical — guard on `isHost`:** Only the host can send the `session_ended` broadcast (ARCH21 host authority). Followers dispatching `SessionEndRequested` (which should not happen in Story 20.4 wiring, but could happen in a bug) are silently ignored.

  **Critical — `session_ended` vs `SessionEndRequested`:** `SessionEndRequested` is the user-initiated event (host's story-complete signal from Story 20.4). `BroadcastEvent.sessionEnded()` is what arrives from the channel for all participants (including the host, via the self-echo). The host transitions to `sessionEnded()` via the channel echo — NOT via the event handler directly. This is the same symmetric pattern as `SessionStartTapped` (event) vs `BroadcastEvent.sessionStarted()` (echo).

---

### Task 6 — `SharedSessionLobbyPage`: drop-out note, `_SessionEndedView`, new ARB keys (AC1, AC4, E18R-2)

- [x] **6.1** Edit `pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart`.

  **Update the top-level `switch` in `SharedSessionLobbyPage.build`** to add the `_SessionEnded()` arm:

  ```dart
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
            :final droppedHandle,   // NEW — destructure for drop note
          ) =>
            _SharedInSessionView(
              stepIndex: stepIndex,
              elapsedSeconds: elapsedSeconds,
              steps: steps,
              droppedHandle: droppedHandle,   // NEW
            ),
          _Error(:final failure) => _ErrorView(failure: failure),
          _SessionEnded() => const _SessionEndedView(),   // NEW (AC4)
        };
      },
    );
  }
  ```

  **Update `_SharedInSessionView`** — add `droppedHandle` parameter and inline note (AC1, E18R-2):

  ```dart
  class _SharedInSessionView extends StatelessWidget {
    final int stepIndex;
    final int elapsedSeconds;
    final List<ExerciseStep> steps;
    final String? droppedHandle;   // NEW

    const _SharedInSessionView({
      required this.stepIndex,
      required this.elapsedSeconds,
      required this.steps,
      this.droppedHandle,          // NEW
    });

    @override
    Widget build(BuildContext context) {
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      final l10n = AppLocalizations.of(context)!;

      // Guard: empty steps
      if (steps.isEmpty) {
        return Scaffold(
          backgroundColor: pulseTheme.surface,
          body: const SizedBox.shrink(),
        );
      }

      final clampedIndex = stepIndex.clamp(0, steps.length - 1);
      final step = steps[clampedIndex];
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
                // AC5 from 19.2 — liveRegion + explicit label for AT announcements
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
                    (clampedIndex + 1).toString(),
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
                  value: (clampedIndex + 1) / totalSteps,
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
                // AC1: inline drop-out note (E18R-2: localized IT, no raw string)
                if (droppedHandle != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.sharedSessionParticipantDropped(droppedHandle!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
  ```

  **Add `_SessionEndedView`** at the bottom of the file (AC4, E18R-2):

  ```dart
  class _SessionEndedView extends StatelessWidget {
    const _SessionEndedView();

    @override
    Widget build(BuildContext context) {
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      final l10n = AppLocalizations.of(context)!;
      // Terminal state: session complete. Story 20.4 will wire RPE navigation
      // via a BlocListener on the sessionEnded() state. Until then, display
      // a localized completion message (E18R-2: no raw English strings).
      return Scaffold(
        backgroundColor: pulseTheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.sharedSessionEnded,
              style: AppTextStyles.h2.copyWith(color: pulseTheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }
  ```

  **Critical — E18R-2 compliance:** Both `_SharedInSessionView` (drop-out note) and `_SessionEndedView` use localized ARB keys. No raw Dart string is displayed to the user.

  **Critical — empty-steps guard in `_SharedInSessionView`:** The 19.2 patch introduced a `clamp` but the denominator `totalSteps` was still 0 when `steps` is empty. Adding an explicit `if (steps.isEmpty) return ...` guard prevents both `clamp(0, -1)` throwing and `(clampedIndex + 1) / totalSteps` dividing by zero.

- [x] **6.2** Add 2 new ARB keys to `pulse_coach/lib/l10n/app/app_en.arb`:

  After the existing `sharedSessionErrorGeneric` entry:
  ```json
  "sharedSessionParticipantDropped": "{handle} disconnected",
  "@sharedSessionParticipantDropped": {
    "placeholders": {
      "handle": {
        "type": "String"
      }
    }
  },
  "sharedSessionEnded": "Session complete"
  ```

- [x] **6.3** Add 2 new ARB keys to `pulse_coach/lib/l10n/app/app_it.arb`:

  After the existing `sharedSessionErrorGeneric` entry:
  ```json
  "sharedSessionParticipantDropped": "{handle} si è disconnesso",
  "@sharedSessionParticipantDropped": {
    "placeholders": {
      "handle": {
        "type": "String"
      }
    }
  },
  "sharedSessionEnded": "Sessione terminata"
  ```

  Run `flutter pub get` (or `flutter gen-l10n`) to regenerate `AppLocalizations`. Verify `l10n.sharedSessionParticipantDropped('alice')` compiles and produces the expected string.

---

### Task 7 — Tests (AC1–AC4, E18R-2)

- [x] **7.1** Create `pulse_coach/test/bloc/shared_session/drop_out_tolerance_bloc_test.dart`:

  ```dart
  // [19.3-BLOC-001..012] Drop-out tolerance and reconnect bloc tests
  import 'dart:async';

  import 'package:bloc_test/bloc_test.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mockito/mockito.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
  import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
  import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
  import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
  import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
  import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';

  // Re-use the MockRealtimeGateway from story 19.2 test
  import '../shared_session/shared_session_bloc_test.mocks.dart';

  const _kSteps = [
    ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 60),
    ExerciseStep(title: 'Cardio', instruction: 'Run', durationSeconds: 120),
  ];

  // Participants
  const _alice = ParticipantPresence(userId: 'alice-uid', displayHandle: 'alice', isHost: true);
  const _bob = ParticipantPresence(userId: 'bob-uid', displayHandle: 'bob', isHost: false);
  const _carol = ParticipantPresence(userId: 'carol-uid', displayHandle: 'carol', isHost: false);

  SharedSessionJoined _hostJoin() => const SharedSessionJoined(
    sessionId: 'sess-1', isHost: true, userId: 'alice-uid',
    displayHandle: 'alice', steps: _kSteps,
  );

  SharedSessionJoined _followerJoin({String userId = 'bob-uid', String? handle = 'bob'}) =>
      SharedSessionJoined(
        sessionId: 'sess-1', isHost: false, userId: userId,
        displayHandle: handle, steps: _kSteps,
      );

  // Bring the bloc to inSession state with given participants
  Future<void> _bringToInSession(
    SharedSessionBloc bloc,
    StreamController<BroadcastEvent> bc,
    StreamController<PresenceState> pc, {
    List<ParticipantPresence> participants = const [_alice, _bob],
    bool asHost = true,
  }) async {
    bloc.add(asHost ? _hostJoin() : _followerJoin());
    await Future<void>.delayed(Duration.zero);
    bc.add(const BroadcastEvent.sessionStarted());
    await Future<void>.delayed(Duration.zero);
    if (participants.isNotEmpty) {
      pc.add(PresenceState(participants: participants));
      await Future<void>.delayed(Duration.zero);
    }
  }

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
      when(mockGateway.trackPresence(
        userId: anyNamed('userId'),
        displayHandle: anyNamed('displayHandle'),
        isHost: anyNamed('isHost'),
      )).thenAnswer((_) async {});
      when(mockGateway.leaveChannel()).thenAnswer((_) async {});
      when(mockGateway.sendBroadcast(
        event: anyNamed('event'),
        payload: anyNamed('payload'),
      )).thenAnswer((_) async {});
      when(mockGateway.untrackPresence()).thenAnswer((_) async {});
    });

    tearDown(() {
      broadcastController.close();
      presenceController.close();
    });

    group('SharedSessionBloc — Drop-Out Tolerance (19.3)', () {
      // AC1: follower drops → droppedHandle set in inSession
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-001: follower drop-out → droppedHandle set in inSession state (AC1)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          await _bringToInSession(bloc, broadcastController, presenceController);
          // Bob drops out
          presenceController.add(const PresenceState(participants: [_alice]));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          const SharedSessionState.loading(),
          SharedSessionState.lobby(participants: const [], isHost: true, steps: _kSteps),
          // sessionStarted → inSession(0,0)
          SharedSessionState.inSession(stepIndex: 0, elapsedSeconds: 0, isHost: true, steps: _kSteps, participants: const []),
          // presence update with alice+bob
          SharedSessionState.inSession(stepIndex: 0, elapsedSeconds: 0, isHost: true, steps: _kSteps, participants: const [_alice, _bob]),
          // bob drops → droppedHandle = 'bob'
          SharedSessionState.inSession(
            stepIndex: 0, elapsedSeconds: 0, isHost: true, steps: _kSteps,
            participants: const [_alice],
            droppedHandle: 'bob',
          ),
        ],
      );

      // AC1: droppedHandle clears on next step_advanced
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-002: droppedHandle clears on next step_advanced (AC1)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          await _bringToInSession(bloc, broadcastController, presenceController, asHost: false, participants: const [_alice, _bob]);
          // Alice (host) drops in from follower's perspective — just a presence update
          presenceController.add(const PresenceState(participants: [_bob]));
          await Future<void>.delayed(Duration.zero);
          // Next step_advanced should clear droppedHandle
          broadcastController.add(const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 65));
          await Future<void>.delayed(Duration.zero);
        },
        skip: 5, // Skip states up to after presence drop
        expect: () => [
          // After droppedHandle set, step_advanced clears it
          isA<_InSession>().having((s) => s.droppedHandle, 'droppedHandle', isNull)
              .having((s) => s.stepIndex, 'stepIndex', 1),
        ],
      );

      // AC3: host drops → follower with alphabetically-first userId becomes new host
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-003: host drop → new host elected (alphabetically first userId) (AC3)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          // bob-uid is the follower; alice-uid (host) and carol-uid also present
          bloc.add(_followerJoin(userId: 'bob-uid', handle: 'bob'));
          await Future<void>.delayed(Duration.zero);
          broadcastController.add(const BroadcastEvent.sessionStarted());
          await Future<void>.delayed(Duration.zero);
          presenceController.add(const PresenceState(participants: [_alice, _bob, _carol]));
          await Future<void>.delayed(Duration.zero);
          // Alice (host) drops; remaining: bob-uid, carol-uid → sorted: [alice-uid gone], [bob-uid, carol-uid]
          // alphabetically: bob-uid < carol-uid → bob becomes new host
          presenceController.add(const PresenceState(participants: [_bob, _carol]));
          await Future<void>.delayed(Duration.zero);
        },
        // The last state emission should have isHost: true for bob's bloc
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<_InSession>().having((s) => s.isHost, 'isHost', true));
        },
      );

      // AC3: host drops → non-first follower does NOT become host
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-004: host drops → carol (alphabetically second) does NOT become host (AC3)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          bloc.add(_followerJoin(userId: 'carol-uid', handle: 'carol'));
          await Future<void>.delayed(Duration.zero);
          broadcastController.add(const BroadcastEvent.sessionStarted());
          await Future<void>.delayed(Duration.zero);
          presenceController.add(const PresenceState(participants: [_alice, _bob, _carol]));
          await Future<void>.delayed(Duration.zero);
          // Alice drops; sorted remaining: [bob-uid, carol-uid] → bob-uid is first
          presenceController.add(const PresenceState(participants: [_bob, _carol]));
          await Future<void>.delayed(Duration.zero);
        },
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<_InSession>().having((s) => s.isHost, 'isHost', false));
        },
      );

      // AC3: HostStepAdvanced now works after leadership transfer
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-005: promoted-host can call sendBroadcast after transfer (AC3)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          bloc.add(_followerJoin(userId: 'bob-uid', handle: 'bob'));
          await Future<void>.delayed(Duration.zero);
          broadcastController.add(const BroadcastEvent.sessionStarted());
          await Future<void>.delayed(Duration.zero);
          presenceController.add(const PresenceState(participants: [_alice, _bob]));
          await Future<void>.delayed(Duration.zero);
          // Alice drops → bob becomes new host
          presenceController.add(const PresenceState(participants: [_bob]));
          await Future<void>.delayed(Duration.zero);
          // Bob dispatches HostStepAdvanced as new host
          bloc.add(const HostStepAdvanced(stepIndex: 1, elapsedSeconds: 62));
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(mockGateway.sendBroadcast(
            event: 'step_advanced',
            payload: {'step_index': 1, 'elapsed_seconds': 62},
          )).called(1);
        },
      );

      // AC2: follower reconnect — missed session_started → snaps via step_advanced
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-006: follower missed session_started → StepAdvanced while in lobby snaps to inSession (AC2)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          bloc.add(_followerJoin());
          await Future<void>.delayed(Duration.zero);
          // Follower stays in lobby (session_started was missed)
          // Next step_advanced arrives → should snap to inSession
          broadcastController.add(const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 90));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          const SharedSessionState.loading(),
          SharedSessionState.lobby(participants: const [], isHost: false, steps: _kSteps),
          // Snap to inSession from lobby
          SharedSessionState.inSession(
            stepIndex: 1, elapsedSeconds: 90, isHost: false, steps: _kSteps,
            participants: const [],
          ),
        ],
      );

      // AC2: host does NOT snap to inSession via step_advanced from lobby
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-007: host in lobby does NOT transition via StepAdvanced (AC2 guard)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          bloc.add(_hostJoin());
          await Future<void>.delayed(Duration.zero);
          // Host should never receive step_advanced while in lobby (they drive it),
          // but even if they do, they must NOT transition via the lobby→inSession reconnect path
          broadcastController.add(const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 90));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          const SharedSessionState.loading(),
          SharedSessionState.lobby(participants: const [], isHost: true, steps: _kSteps),
          // No additional state — host stays in lobby
        ],
      );

      // AC4: SessionEnded broadcast → sessionEnded() state + leaveChannel
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-008: BroadcastEvent.sessionEnded → sessionEnded() state (AC4)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          await _bringToInSession(bloc, broadcastController, presenceController);
          broadcastController.add(const BroadcastEvent.sessionEnded());
          await Future<void>.delayed(Duration.zero);
        },
        // Verify final state is sessionEnded
        verify: (bloc) {
          expect(bloc.state, const SharedSessionState.sessionEnded());
          verify(mockGateway.leaveChannel()).called(1);
        },
      );

      // AC4: SessionEndRequested by host → sends session_ended broadcast
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-009: SessionEndRequested by host → sendBroadcast session_ended (AC4)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          await _bringToInSession(bloc, broadcastController, presenceController);
          bloc.add(const SessionEndRequested());
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(mockGateway.sendBroadcast(
            event: 'session_ended',
            payload: {},
          )).called(1);
        },
      );

      // AC4: SessionEndRequested by non-host → no-op
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-010: SessionEndRequested by follower → no sendBroadcast (AC4)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          await _bringToInSession(bloc, broadcastController, presenceController, asHost: false);
          bloc.add(const SessionEndRequested());
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verifyNever(mockGateway.sendBroadcast(
            event: 'session_ended',
            payload: anyNamed('payload'),
          ));
        },
      );

      // AC1: trackPresence called with isHost flag
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-011: trackPresence called with isHost=true for host (AC1/AC3)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          bloc.add(_hostJoin());
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(mockGateway.trackPresence(
            userId: 'alice-uid',
            displayHandle: 'alice',
            isHost: true,
          )).called(1);
        },
      );

      // AC3: presence update during lobby updates participants (unchanged from 19.2)
      blocTest<SharedSessionBloc, SharedSessionState>(
        '19.3-BLOC-012: presence update in lobby still updates lobby.participants (regression)',
        build: () => SharedSessionBloc(mockGateway),
        act: (bloc) async {
          bloc.add(_hostJoin());
          await Future<void>.delayed(Duration.zero);
          presenceController.add(const PresenceState(participants: [_alice]));
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          const SharedSessionState.loading(),
          SharedSessionState.lobby(participants: const [], isHost: true, steps: _kSteps),
          SharedSessionState.lobby(participants: const [_alice], isHost: true, steps: _kSteps),
        ],
      );
    });
  }
  ```

  **Why `skip: 5` in BLOC-002:** The test verifies the state AFTER a sequence of intermediate states (loading → lobby → inSession initial → inSession with participants → inSession with droppedHandle). `skip:` tells `blocTest` to skip the first N states and only match the remaining ones. Adjust the count if intermediate states are added/removed.

  **Why re-use `shared_session_bloc_test.mocks.dart`:** `MockRealtimeGateway` was generated in Story 19.2 tests and covers all gateway methods. 19.3 tests need the same mock with the updated `trackPresence` signature (which now includes `isHost: bool`). Re-run `build_runner` to regenerate the mocks; they will be updated automatically.

- [x] **7.2** Create `pulse_coach/test/widget/shared_session/drop_out_tolerance_widget_test.dart`:

  ```dart
  // [19.3-WIDGET-001..002] Drop-out tolerance widget tests
  import 'package:bloc_test/bloc_test.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mockito/annotations.dart';
  import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
  import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
  import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';
  import 'package:pulse_coach/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';

  @GenerateNiceMocks([MockSpec<SharedSessionBloc>()])
  import 'drop_out_tolerance_widget_test.mocks.dart';

  const _kSteps = [
    ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 60),
  ];

  Widget _buildTestWidget(SharedSessionState state) {
    final mockBloc = MockSharedSessionBloc();
    whenListen(
      mockBloc,
      Stream<SharedSessionState>.value(state),
      initialState: state,
    );
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
      home: BlocProvider<SharedSessionBloc>.value(
        value: mockBloc,
        child: const SharedSessionLobbyPage(),
      ),
    );
  }

  void main() {
    group('Drop-Out Tolerance — Widget (19.3)', () {
      testWidgets(
        '19.3-WIDGET-001: inSession with droppedHandle renders disconnect note (AC1, E18R-2)',
        (tester) async {
          await tester.pumpWidget(
            _buildTestWidget(
              SharedSessionState.inSession(
                stepIndex: 0,
                elapsedSeconds: 30,
                isHost: false,
                steps: _kSteps,
                droppedHandle: 'bob',
              ),
            ),
          );
          await tester.pump();
          // E18R-2: localized IT string; NOT raw 'bob disconnected'
          expect(find.textContaining('bob si è disconnesso'), findsOneWidget);
          // Step content still visible
          expect(find.text('Warm Up'), findsOneWidget);
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
  ```

- [x] **7.3** Run `dart run build_runner build --delete-conflicting-outputs` to regenerate:
  - `presence_state.freezed.dart` (updated with `isHost`)
  - `shared_session_state.freezed.dart` (updated with `participants`, `droppedHandle`, `_SessionEnded`)
  - `shared_session_bloc_test.mocks.dart` (updated `trackPresence` signature)
  - `drop_out_tolerance_widget_test.mocks.dart` (new mock for widget test)
  - `injection.config.dart` (unchanged but re-checked)

- [x] **7.4** Run `flutter test` from `pulse_coach/` — 1138 tests total, all green (12 new bloc + 2 new widget + 1124 existing).

- [x] **7.5** Run `flutter analyze lib/ test/` from `pulse_coach/` — 0 issues.

---

## Review Findings

_Adversarial code review (2026-06-25): Blind Hunter + Edge Case Hunter + Acceptance Auditor (all Opus). Verdict: AC1–AC5 PASS; 1139 tests green (1138 + new BLOC-013 from review hardening); `flutter analyze lib/ test/` 0 issues. Findings below are robustness edges in the new host-transfer protocol, not AC failures._

- [x] [Review][Decision→Patch] Host-transfer single-drop + new host not propagated to Presence — **RESOLVED (full hardening, option 3).** `_onPresenceReceived` election rewritten to trigger on "no host flagged among current participants" instead of diff-based "a host was in `dropped`" (`shared_session_bloc.dart`), which also covers the empty-`prev` reconnect case (C1). The elected host now stores `_myDisplayHandle` (`_onJoined`) and re-tracks presence via `trackPresence(isHost: true)` on promotion (H3), so peers learn the new host and a subsequent host-drop stays detectable (M8/C2). New test BLOC-013 locks in the reconnect-elect + re-track path. [edge C1+C2+H3+M8, blind 1/2]

- [x] [Review][Patch] BLOC-002 asserts only the final state, not the intermediate `droppedHandle == 'carol'` emission [pulse_coach/test/bloc/shared_session/drop_out_tolerance_bloc_test.dart] — **RESOLVED.** Added an `expect:` sequence asserting the intermediate `droppedHandle: 'carol'` emission so a regression that never sets the note cannot pass silently. [blind 7]

- [x] [Review][Defer] `droppedHandle` surfaces only one participant on simultaneous multi-drop [shared_session_bloc.dart:120-122] — deferred, explicitly accepted in "Known Post-19.3 Gaps".
- [x] [Review][Defer] Host's drop note persists across step changes (host ignores its own `step_advanced` echo) [shared_session_bloc.dart:120 vs 158-161] — deferred, minor UX inconsistency vs follower.
- [x] [Review][Defer] `SessionEnded` honored in any state can mask `error` / skip the lobby [shared_session_bloc.dart:176-182] — deferred, semi-per-spec (AC4: "any participant receives sessionEnded → emit").
- [x] [Review][Defer] No dedup of duplicate `user_id` entries in presence mapping [realtime_gateway.dart:137-146] — deferred, pre-existing (gateway from 19.1).
- [x] [Review][Defer] Out-of-range `stepIndex`/`elapsedSeconds` stored unclamped in state (clamp lives only in the view) [shared_session_bloc.dart:155-172] — deferred, pre-existing pattern from 19.2.
- [x] [Review][Defer] Subscriptions not cancelled on `SessionEnded`, only on `close()` [shared_session_bloc.dart:176-182] — deferred, low (streams complete via `leaveChannel`; leak only on same-bloc re-use).

## Dev Notes

### Architecture Boundary (ARCH25) — Unchanged

`SharedSessionBloc` still imports only `RealtimeGateway` from `lib/core/cloud/`. The new `trackPresence(isHost:)` parameter propagates through `RealtimeGateway`'s internal Supabase channel `.track({...})` call. No `supabase_flutter` type leaks into the bloc.

### Why `isHost` in the Presence Payload (not derived)

Alternative: derive the host from who joined first, or from a separate tracker. Both alternatives require either time-based coordination (brittle under network delays) or an external data store. Embedding `isHost: bool` in the presence payload is the simplest authority: the Supabase Presence channel reliably delivers the tracked state to all participants, including late joiners who sync the full presence state on join.

### Leadership Transfer is Alphabetical by `userId` (not `displayHandle`)

`userId` (UUID) is stable and unique. `displayHandle` is user-chosen, may be null, and is not guaranteed unique across participants. Sorting by `userId` produces a deterministic, consistent ordering across all participants' blocs simultaneously.

**Tie-breaking:** UUIDs are never equal (each registered user has a unique UUID), so there are no ties.

### `droppedHandle: null` in freezed `copyWith` — Explicit Clear

In freezed 3.x, the generated `copyWith` for nullable fields uses a `freezed` sentinel as the default parameter value. Passing `null` explicitly sets the field to null (clears it). Passing nothing preserves the existing value. This means `s.copyWith(droppedHandle: null)` reliably clears the note. Do NOT omit the `droppedHandle` argument when you intend to clear it.

### Test Mock: `trackPresence` Named Parameters

The `MockRealtimeGateway` stubs use `anyNamed('isHost')` in `setUp` to match any value for the new `isHost` named parameter. Individual tests that need to verify `isHost: true` or `isHost: false` use `verify(mockGateway.trackPresence(userId: ..., displayHandle: ..., isHost: true))`. Ensure `shared_session_bloc_test.dart` `setUp` also adds `anyNamed('isHost')` to the `trackPresence` stub — it will be regenerated by `build_runner`.

### `_bringToInSession` Test Helper

The helper in the new test file sequences the bloc through: `SharedSessionJoined` → await → `sessionStarted` broadcast → await → optional `presenceController.add`. This reduces boilerplate across the 12 tests. Tests that verify states PRIOR to `inSession` (like BLOC-011/012) do NOT use it.

### Story 20.4 Integration Point

Story 20.4 ("Synchronized Session Start and Shared InSessionView") will wire:
1. `InSessionCubit.onStepComplete` → dispatch `HostStepAdvanced` (host only, guarded by `state.isHost`)
2. `InSessionCubit.onSessionComplete` → dispatch `SessionEndRequested` (host only)
3. A `BlocListener<SharedSessionBloc, SharedSessionState>` on `sessionEnded()` → navigate to RPE input

Story 20.4 does NOT need to modify `SharedSessionBloc` or `RealtimeGateway`. The `isHost` field in `inSession` state is the flag Story 20.4 reads to decide whether to dispatch the host-only events.

### Known Post-19.3 Gaps (not in scope)

- `error` state retry path — `_ErrorView` says "Riprova" but no retry action wired; deferred until the page is fully reachable via Story 20.1 navigation.
- Multiple simultaneous drops show only the first dropped participant's handle — acceptable for MVP; only one presence sync fires per drop event in Supabase Realtime.
- `session_ended` broadcast send failure swallows silently — same as `step_advanced`; observability deferred.
- Late joiner (join code submitted after session started) — Story 20.3 blocks them at the lobby; if they somehow get through, the `lobby → inSession` reconnect path (AC2) would snap them to the current step.

### Directory Structure Changed by This Story

```
pulse_coach/
  lib/features/social/shared_session/
    domain/entities/
      presence_state.dart                                          # MODIFIED (+isHost to ParticipantPresence)
      presence_state.freezed.dart                                  # REGENERATED

    presentation/bloc/
      shared_session_state.dart                                    # MODIFIED (+participants, +droppedHandle, +sessionEnded)
      shared_session_state.freezed.dart                            # REGENERATED
      shared_session_event.dart                                    # MODIFIED (+SessionEndRequested)
      shared_session_bloc.dart                                     # MODIFIED (drop-out, reconnect, host-transfer, sessionEnded)

    presentation/pages/
      shared_session_lobby_page.dart                               # MODIFIED (_SharedInSessionView +droppedHandle, +_SessionEndedView)

  lib/core/cloud/
    realtime_gateway.dart                                          # MODIFIED (+isHost to trackPresence + _emitPresenceState)

  lib/l10n/app/
    app_en.arb                                                     # MODIFIED (+2 keys)
    app_it.arb                                                     # MODIFIED (+2 keys)

  lib/core/di/
    injection.config.dart                                          # REGENERATED (no new registrations)

  test/bloc/shared_session/
    drop_out_tolerance_bloc_test.dart                              # NEW (12 tests)
    shared_session_bloc_test.mocks.dart                            # REGENERATED (trackPresence isHost param)

  test/widget/shared_session/
    drop_out_tolerance_widget_test.dart                            # NEW (2 tests)
    drop_out_tolerance_widget_test.mocks.dart                      # GENERATED

_bmad-output/implementation-artifacts/
  sprint-status.yaml                                               # MODIFIED (19-3 → ready-for-dev)
```

No new Supabase migrations in this story. The `shared_sessions` table and join-code flow are Story 20.1.

### References

- Epic 19 Story 19.3 ACs: `_bmad-output/planning-artifacts/epics.md` line ~2582
- Architecture ARCH21 (host authority, NFR31): `_bmad-output/planning-artifacts/architecture.md` line ~786
- `RealtimeGateway` implementation: `pulse_coach/lib/core/cloud/realtime_gateway.dart`
- `SharedSessionBloc` (19.2 final): `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`
- `SharedSessionState` (19.2): `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.dart`
- `ParticipantPresence` entity: `pulse_coach/lib/features/social/shared_session/domain/entities/presence_state.dart`
- `SharedSessionLobbyPage` (19.2): `pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart`
- Action-item ledger (E9-K1 fire-check): `_bmad-output/implementation-artifacts/action-item-ledger.md`
- Story 19.2 deferred items (closed by this story): `_bmad-output/implementation-artifacts/19-2-host-authority-step-advancement-and-presence-lobby.md` (Review → Deferred section)
- `app_en.arb` / `app_it.arb`: `pulse_coach/lib/l10n/app/`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

- ✅ Task 1: `ParticipantPresence` extended with `@Default(false) bool isHost`; build_runner regenerated `presence_state.freezed.dart`.
- ✅ Task 2: `RealtimeGateway.trackPresence` now accepts `isHost: bool = false`; `_emitPresenceState` reads `is_host` from presence payload with safe bool parse.
- ✅ Task 3: `SharedSessionState.inSession` extended with `@Default([]) participants` and nullable `droppedHandle`; new `sessionEnded()` terminal state added; freezed regenerated.
- ✅ Task 4: `SessionEndRequested` event added to `shared_session_event.dart`.
- ✅ Task 5: `SharedSessionBloc` fully rewritten for drop-out tolerance — `_myUserId`/`_isHost` instance vars, `_onPresenceReceived` with AC1 drop detection + AC3 host-transfer, `_onBroadcastReceived` with AC2 lobby→inSession reconnect + AC4 `sessionEnded()`, `_onSessionEndRequested` host-guarded handler.
- ✅ Task 6: `SharedSessionLobbyPage` updated — drop-out note in `_SharedInSessionView`, new `_SessionEndedView`, `state.map()` switch with `sessionEnded:` arm; 2 ARB keys added to EN+IT.
- ✅ Task 7: 12 bloc tests + 2 widget tests created; `shared_session_bloc_test.dart` setUp updated for `isHost` param; all 1138 tests green; analyzer 0 issues.
- Note: BLOC-002 scenario adjusted vs. story spec — used carol (non-host) drop instead of alice (host) drop to avoid the leadership-transfer side-effect that would suppress the follower's step_advanced processing. Semantics identical; test verifies AC1 droppedHandle clearance on next step broadcast.

### File List

- pulse_coach/lib/features/social/shared_session/domain/entities/presence_state.dart
- pulse_coach/lib/features/social/shared_session/domain/entities/presence_state.freezed.dart
- pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.dart
- pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.freezed.dart
- pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_event.dart
- pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart
- pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart
- pulse_coach/lib/core/cloud/realtime_gateway.dart
- pulse_coach/lib/l10n/app/app_en.arb
- pulse_coach/lib/l10n/app/app_it.arb
- pulse_coach/test/bloc/shared_session/drop_out_tolerance_bloc_test.dart
- pulse_coach/test/bloc/shared_session/shared_session_bloc_test.dart
- pulse_coach/test/bloc/shared_session/shared_session_bloc_test.mocks.dart
- pulse_coach/test/widget/shared_session/drop_out_tolerance_widget_test.dart
- pulse_coach/test/widget/shared_session/drop_out_tolerance_widget_test.mocks.dart
- _bmad-output/implementation-artifacts/sprint-status.yaml

### Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2026-06-25 | 1.0.0 | Story created. | claude-sonnet-4-6 |
| 2026-06-25 | 1.1.0 | Story implemented: drop-out tolerance, host transfer, reconnect, sessionEnded. 1138 tests green, 0 analyzer issues. | claude-sonnet-4-6 |
