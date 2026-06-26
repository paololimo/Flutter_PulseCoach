---
baseline_commit: ae99baf
---

# Story 20.4: Synchronized Session Start and Shared InSessionView

Status: done

## Story

As a shared session participant,
I want all devices to show the same step and timer in real time when the session starts,
So that the experience of exercising together is synchronized regardless of device.

## Context

**Epic 20 — Co-Located Shared Sessions (v2.4b).** Stories 20.1–20.3 built the complete join pipeline: `shared_sessions` table + `JoinCodeCard` (20.1), `GroupConstraintResolver` (20.2), follower join flow + co-location check (20.3). Story 20.4 wires the **synchronized execution layer**: the host's local timer, the broadcast-driven follower display, haptic feedback on step transitions, a participant-count badge, and the `sessionEnded → RPE` navigation handoff.

**What is already built (DO NOT REBUILD):**
- `SharedSessionBloc._onStartTapped` — sends `session_started` broadcast when host taps "Inizia" (guard: `participants.length >= 2`)
- `SharedSessionBloc._onBroadcastReceived` — handles `SessionStarted` (→ `inSession`), `StepAdvanced` (→ follower state update), `SessionEnded` (→ `sessionEnded` state)
- `SharedSessionBloc._onHostStepAdvanced` — sends `step_advanced` broadcast with `stepIndex` + `elapsedSeconds`
- `SharedSessionBloc._onSessionEndRequested` — sends `session_ended` broadcast
- `SharedSessionState.inSession` — holds `stepIndex`, `elapsedSeconds`, `isHost`, `steps`, `participants`, `droppedHandle`
- `SharedSessionState.sessionEnded` — terminal state after session completes
- `_SharedInSessionView` (in `shared_session_lobby_page.dart`) — a `StatelessWidget` that renders step title, elapsed timer, progress bar, and dropped-participant notice; does NOT have a timer loop, participant count, or haptic

**What Story 20.4 builds:**
1. Convert `_SharedInSessionView` to a `StatefulWidget` with two paths:
   - **Host path**: creates `InSessionCubit` (persistence disabled); stream-driven dispatch of `HostStepAdvanced` + `SessionEndRequested` to `SharedSessionBloc`; renders `InSessionView` (v1 widget, countdown display) + `_ParticipantBadge`
   - **Follower path**: local `Timer.periodic(1s)` for display clock; `didUpdateWidget` for haptic on step change; same layout + `_ParticipantBadge`
2. Pass `isHost` and `participantCount` into `_SharedInSessionView` from `SharedSessionLobbyPage`
3. `BlocListener` in `SharedSessionLobbyPage` handles `sessionEnded` → navigate to `AppRouter.sessionRpe` with a `planId: null` placeholder (Story 20.5 wires the real arm key and bandit reward)
4. ARB key `sharedSessionParticipantCount` for participant badge

**What this story does NOT include:**
- CountdownOverlay before shared in-session (no synchronized countdown; direct start)
- Per-participant RPE bandit reward wiring (Story 20.5)
- Abandon flow confirmation sheet for shared sessions (out of scope; abandon = host ends for all, follower just pops)
- WearOS shared-session mirroring (architecture decision: mirror; FR71 `[ASSUMPTION]`, deferred)

**E9-K1 fire-check:**

| Active item | Fires? | Required action |
|---|---|---|
| `E18R-1` small-viewport shimmer test | ✅ YES — new `_SharedInSessionView` (StatefulWidget) and host `InSessionView` are new screen areas with visible content | Add 360×640 widget tests for in-session view (follower + host) (Task 6.3) |
| `E18R-2` backend-failure localization | ❌ No — no new `Failure` surfaces to user in in-session display | Not applicable |
| `E18R-CB2` localized-IT review check | ❌ No — no raw `failure.message` in the new code paths | Not applicable |
| `E18R-4` social `ProUpsellSheet` copy | ❌ No — story does not touch `ProUpsellSheet` | Not applicable |
| `E10R-2` non-UTC week-bucketing | ❌ No — no Progress/week-bucketing code touched | Not applicable |
| `E6-P1` patch-validation gate | Fires at code-review time if DI/lifecycle changes | Reviewer re-runs `flutter analyze` after any review patches |

**Category A snapshot entering sprint (Story 20.4): 4 / 5.** Active: `E18R-1`, `E18R-2`, `E10R-2`, `E18R-4`. Under cap. Story 20.4 cleared to enter sprint.

## Acceptance Criteria

**AC1 — Simultaneous inSession transition on `session_started` (FR71, UX-DR29):**
Given all expected participants are in the lobby (Presence) and the host taps "Inizia"
When the `session_started` broadcast fires
Then all participants' `SharedSessionBloc` instances simultaneously transition to `inSession` state; all clients render `_SharedInSessionView` at `stepIndex: 0` with the elapsed timer at 0:00

**AC2 — Follower step sync from broadcast (NFR31):**
Given the host's `InSessionCubit` advances to the next step
When the host dispatches `HostStepAdvanced(stepIndex: newIdx, elapsedSeconds: totalElapsed)` to `SharedSessionBloc` and the bloc sends the `step_advanced` broadcast
Then follower clients receive the event and their `SharedSessionState.inSession` updates to `stepIndex: newIdx, elapsedSeconds: totalElapsed`; the follower UI renders the new step immediately

**AC3 — Participant count badge (UX-DR29):**
Given the shared session is in `inSession` state with N participants in the Presence channel
When `_SharedInSessionView` renders
Then a subtle text label showing `l10n.sharedSessionParticipantCount(N)` is visible in the header area; the rest of the layout is identical to the v1 solo `InSessionView`

**AC4 — Host drives timer and broadcasts step advances (FR71):**
Given the session is in `inSession` state and `isHost == true`
When `_SharedInSessionViewState.initState` runs
Then an `InSessionCubit` is created with `sessionLogsDao: null`, `planId: null` (persistence disabled), and `hapticService: VibrationHapticService()`; `cubit.start()` is called; a `StreamSubscription` listens to the cubit stream and dispatches `HostStepAdvanced(stepIndex: newIdx, elapsedSeconds: sumOfPreviousStepDurations)` to `SharedSessionBloc` whenever `currentStepIndex` increments; when `isComplete == true`, dispatches `SessionEndRequested()` exactly once

**AC5 — Host render path reuses InSessionView (UX-DR29):**
Given the shared session is in `inSession` state and `isHost == true`
When `_SharedInSessionView` renders
Then the widget tree contains an `InSessionView` built from the `InSessionCubit` state (countdown display per step) with a `_ParticipantBadge` overlay; the abandon button dispatches `SessionEndRequested()` to `SharedSessionBloc` and is available to the host

**AC6 — Follower haptic on step transition (NFR4):**
Given a follower's `_SharedInSessionView` receives a state update where `widget.stepIndex != old.widget.stepIndex`
When `didUpdateWidget` runs
Then `HapticFeedback.mediumImpact()` fires within 200ms; the follower's display elapsed timer resets to `widget.elapsedSeconds` from the new state

**AC7 — Follower local clock ticks between broadcasts (UX-DR29):**
Given the follower is in `inSession` and no new `step_advanced` broadcast has arrived
When 1 second elapses on device
Then the displayed elapsed time increments by 1 second; this is driven by a local `Timer.periodic(1s)` in `_SharedInSessionViewState`

**AC8 — `sessionEnded` → RPE navigation (FR72):**
Given `SharedSessionBloc` emits `SharedSessionState.sessionEnded()`
When `SharedSessionLobbyPage`'s `BlocListener` fires
Then the page navigates to `AppRouter.sessionRpe` using `context.go(...)` with `RpeSubmitArgs(planId: null, sessionIndex: 0, abandoned: false, armKey: 'shared_session', durationMinutes: totalDurationMinutes, sessionLogId: null)`; `totalDurationMinutes` is derived from `steps.fold(0, (s, e) => s + e.durationSeconds) ~/ 60` from the last `inSession` state snapshot

**AC9 — Dropped-participant notice remains (NFR31, Epic 19 drop-out tolerance):**
Given a participant leaves during the session
When `SharedSessionState.inSession.droppedHandle` is non-null
Then `_SharedInSessionView` shows `l10n.sharedSessionParticipantDropped(droppedHandle)` in the layout — this string and key already exist; no new key needed

**AC10 — Zero regressions:**
Given all new and modified files are in place and `build_runner` has been run
When `flutter test` and `flutter analyze lib/ test/` run from `pulse_coach/`
Then all 1200 existing tests pass plus all new tests pass; analyzer reports 0 issues

## Tasks / Subtasks

---

### Task 1 — Add `isHost` and `participantCount` to `_SharedInSessionView` (AC1, AC3, AC4, AC5)

**Why:** The current `_SharedInSessionView` receives only `stepIndex`, `elapsedSeconds`, `steps`, `droppedHandle`. It cannot distinguish host vs follower paths and cannot show participant count without this data.

- [x] **1.1** In `pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart`, update the `inSession` arm of `SharedSessionLobbyPage.build` to pass the new fields:

  ```dart
  inSession: (s) => _SharedInSessionView(
    stepIndex: s.stepIndex,
    elapsedSeconds: s.elapsedSeconds,
    isHost: s.isHost,                          // NEW
    steps: s.steps,
    participantCount: s.participants.length,   // NEW
    droppedHandle: s.droppedHandle,
  ),
  ```

---

### Task 2 — Convert `_SharedInSessionView` to `StatefulWidget` (AC4, AC5, AC6, AC7)

- [x] **2.1** Convert `_SharedInSessionView` from `StatelessWidget` to `StatefulWidget` + `_SharedInSessionViewState`.

  Add new constructor parameters:
  ```dart
  class _SharedInSessionView extends StatefulWidget {
    final int stepIndex;
    final int elapsedSeconds;
    final bool isHost;               // NEW
    final List<ExerciseStep> steps;
    final int participantCount;      // NEW
    final String? droppedHandle;

    const _SharedInSessionView({
      required this.stepIndex,
      required this.elapsedSeconds,
      required this.isHost,
      required this.steps,
      required this.participantCount,
      this.droppedHandle,
    });

    @override
    State<_SharedInSessionView> createState() => _SharedInSessionViewState();
  }
  ```

- [x] **2.2** Implement `_SharedInSessionViewState` with the HOST path:

  ```dart
  class _SharedInSessionViewState extends State<_SharedInSessionView> {
    // HOST-ONLY fields
    InSessionCubit? _hostCubit;
    StreamSubscription<InSessionState>? _hostSub;
    int _prevHostStepIndex = 0;
    bool _endDispatched = false;

    // FOLLOWER-ONLY fields
    Timer? _tickTimer;
    int _displayedElapsed = 0;

    // Captured in initState — safe to call from async stream callback.
    // context.read<>() works in initState (no subscription; BlocProvider is
    // already above this widget when initState fires). Capturing here avoids
    // calling context.read in a detached async callback after widget disposal.
    late SharedSessionBloc _sharedBloc;

    @override
    void initState() {
      super.initState();
      _sharedBloc = context.read<SharedSessionBloc>();
      if (widget.isHost) {
        _initHostCubit();
      } else {
        _displayedElapsed = widget.elapsedSeconds;
        _startFollowerTick();
      }
    }

    void _initHostCubit() {
      final cubit = InSessionCubit(
        steps: widget.steps,
        sessionLogsDao: null,   // persistence disabled for shared session
        planId: null,
        hapticService: VibrationHapticService(),
      )..start();
      _hostCubit = cubit;
      _hostSub = cubit.stream.listen(_onHostCubitState);
    }

    void _onHostCubitState(InSessionState cubitState) {
      if (!mounted) return;
      // Dispatch HostStepAdvanced on each new step index
      if (cubitState.currentStepIndex != _prevHostStepIndex) {
        final elapsed = _elapsedAtStepStart(cubitState.currentStepIndex);
        _prevHostStepIndex = cubitState.currentStepIndex;
        _sharedBloc.add(
          HostStepAdvanced(
            stepIndex: cubitState.currentStepIndex,
            elapsedSeconds: elapsed,
          ),
        );
      }
      // Dispatch SessionEndRequested exactly once when host cubit completes
      if (cubitState.isComplete && !_endDispatched) {
        _endDispatched = true;
        _sharedBloc.add(const SessionEndRequested());
      }
    }

    // Total elapsed at the START of [stepIdx] = sum of all prior step durations.
    int _elapsedAtStepStart(int stepIdx) =>
        widget.steps.take(stepIdx).fold(0, (sum, s) => sum + s.durationSeconds);

    void _startFollowerTick() {
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _displayedElapsed++);
      });
    }

    @override
    void didUpdateWidget(_SharedInSessionView old) {
      super.didUpdateWidget(old);
      if (!widget.isHost && widget.stepIndex != old.stepIndex) {
        // Snap the displayed elapsed to the authoritative value from the broadcast,
        // and fire haptic for the step transition (NFR4).
        setState(() => _displayedElapsed = widget.elapsedSeconds);
        HapticFeedback.mediumImpact();
      }
    }

    @override
    void dispose() {
      _hostSub?.cancel();
      _hostCubit?.close();
      _tickTimer?.cancel();
      super.dispose();
    }
    ...
  }
  ```

  **Critical — `HapticFeedback.mediumImpact()` is a static call:** It does NOT go through `HapticService`. This is the established pattern in v1 `VibrationHapticService.stepTransition()` which also calls `HapticFeedback.mediumImpact()`. No Bloc event, no `await`. Must fire in `didUpdateWidget` — i.e., synchronously on state delivery — to meet the 200ms NFR4 target.

  **Critical — `InSessionCubit` with `planId: null` and `sessionLogsDao: null`:** This disables `_persistCompletion` and `_persistAbandon`. The cubit calls `_persistCompletion` on `isComplete = true`, but since both DAO and planId are null, `_persistCompletion` returns without writing. This is intentional: shared session completion is not written to the local `session_logs` table by the in-session cubit; Story 20.5 owns the per-participant SessionLog write if needed.

  **Critical — `_endDispatched` guard:** Without this, every tick after `isComplete` would re-dispatch `SessionEndRequested`. Since `InSessionCubit.isComplete` is a permanent terminal state, the stream continues emitting it. The flag must be checked before dispatching.

  **Critical — import for `flutter/services.dart`:** `HapticFeedback` is in `package:flutter/services.dart`. Check if `shared_session_lobby_page.dart` already imports it; if not, add `import 'package:flutter/services.dart';`.

  **Critical — imports for host path:** Need to import `InSessionCubit`, `InSessionState`, `VibrationHapticService`, and `dart:async`. Check existing imports in the file; add only missing ones.

---

### Task 3 — Implement `_SharedInSessionViewState.build` (AC1, AC3, AC5, AC7, AC9)

- [x] **3.1** Implement the `build` method:

  ```dart
  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      return Scaffold(
        backgroundColor: pulseTheme.surface,
        body: const SizedBox.shrink(),
      );
    }

    if (widget.isHost) {
      return _buildHostView(context);
    } else {
      return _buildFollowerView(context);
    }
  }
  ```

- [x] **3.2** Implement `_buildHostView`:

  ```dart
  Widget _buildHostView(BuildContext context) {
    final cubit = _hostCubit;
    if (cubit == null) return const SizedBox.shrink();
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<InSessionCubit, InSessionState>(
        builder: (ctx, cubitState) => Stack(
          children: [
            InSessionView(
              sessionState: cubitState,
              onAbandon: () => _onHostAbandon(ctx),
            ),
            _ParticipantBadge(count: widget.participantCount),
            if (widget.droppedHandle != null)
              _DroppedHandleNotice(handle: widget.droppedHandle!),
          ],
        ),
      ),
    );
  }

  void _onHostAbandon(BuildContext context) {
    // Host abandoning = end the session for all participants.
    // Use the captured _sharedBloc reference (same instance as context.read would return).
    if (!_endDispatched) {
      _endDispatched = true;
      _sharedBloc.add(const SessionEndRequested());
    }
  }
  ```

  **Note on `_DroppedHandleNotice`:** This widget doesn't exist yet. Extract the existing dropped-participant `Text` from the old `_SharedInSessionView.build` body into a small private widget `_DroppedHandleNotice`. This lets both host and follower paths render it cleanly as an overlay.

- [x] **3.3** Implement `_buildFollowerView`:

  The follower view keeps the existing `_SharedInSessionView` layout, updated to use `_displayedElapsed` for the clock:

  ```dart
  Widget _buildFollowerView(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final safeIndex = widget.stepIndex.clamp(0, widget.steps.length - 1);
    final step = widget.steps[safeIndex];
    final totalSteps = widget.steps.length;
    final displayStep = safeIndex + 1;

    return Scaffold(
      backgroundColor: pulseTheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ParticipantBadge(count: widget.participantCount),
                  const SizedBox(height: 8),
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
                      displayStep.toString(),
                      totalSteps.toString(),
                    ),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _formatTime(_displayedElapsed),
                    style: AppTextStyles.timerDisplay.copyWith(
                      color: pulseTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: displayStep / totalSteps,
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
                  if (widget.droppedHandle != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.sharedSessionParticipantDropped(widget.droppedHandle!),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: pulseTheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  ```

- [x] **3.4** Add `_ParticipantBadge` as a private widget within the file:

  ```dart
  class _ParticipantBadge extends StatelessWidget {
    final int count;
    const _ParticipantBadge({required this.count});

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      return Text(
        l10n.sharedSessionParticipantCount(count.toString()),
        style: AppTextStyles.bodySmall.copyWith(
          color: pulseTheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      );
    }
  }
  ```

  **Note on ARB placeholder:** `sharedSessionParticipantCount` uses a `{count}` string parameter (not `int`) to avoid needing `@sharedSessionParticipantCount` plural metadata in this iteration. Story 20.5 can upgrade to plural if needed.

---

### Task 4 — ARB strings (AC3)

- [x] **4.1** Add to `pulse_coach/lib/l10n/app/app_en.arb` (after `sharedSessionCoLocated`):

  ```json
  "sharedSessionParticipantCount": "{count} participants",
  "@sharedSessionParticipantCount": {
    "description": "Participant count badge shown in shared in-session view",
    "placeholders": {
      "count": {
        "type": "String"
      }
    }
  }
  ```

- [x] **4.2** Add to `pulse_coach/lib/l10n/app/app_it.arb` (matching key):

  ```json
  "sharedSessionParticipantCount": "{count} partecipanti",
  "@sharedSessionParticipantCount": {
    "description": "Contatore partecipanti nella sessione condivisa",
    "placeholders": {
      "count": {
        "type": "String"
      }
    }
  }
  ```

  ARB changes do NOT require `build_runner` — run `flutter pub get` after editing ARB files.

---

### Task 5 — `sessionEnded` → RPE navigation in BlocListener (AC8)

- [x] **5.1** In `SharedSessionLobbyPage`, the `BlocListener` currently handles `cancelled` and `refreshErrorTick`. Extend it to also handle `sessionEnded`.

  **Current `listenWhen`:**
  ```dart
  listenWhen: (prev, curr) {
    final cancelled = curr.mapOrNull(cancelled: (_) => true) ?? false;
    if (cancelled) return true;
    final prevTick = prev.mapOrNull(lobby: (s) => s.refreshErrorTick);
    final currTick = curr.mapOrNull(lobby: (s) => s.refreshErrorTick);
    return prevTick != null && currTick != null && currTick != prevTick;
  },
  ```

  **Updated `listenWhen`** — add `sessionEnded` trigger:
  ```dart
  listenWhen: (prev, curr) {
    final cancelled = curr.mapOrNull(cancelled: (_) => true) ?? false;
    if (cancelled) return true;
    final sessionEnded = curr.mapOrNull(sessionEnded: (_) => true) ?? false;
    if (sessionEnded) return true;
    final prevTick = prev.mapOrNull(lobby: (s) => s.refreshErrorTick);
    final currTick = curr.mapOrNull(lobby: (s) => s.refreshErrorTick);
    return prevTick != null && currTick != null && currTick != prevTick;
  },
  ```

- [x] **5.2** Add `_lastInSessionSteps` field to `SharedSessionLobbyPage` — or, simpler: capture the steps from the `inSession` state via a stateful page. However, `SharedSessionLobbyPage` is currently a `StatelessWidget`. The cleanest approach for Story 20.4 is to make the lobby page capture the last known steps.

  **Option A (minimal change):** Make `SharedSessionLobbyPage` stateful and cache steps on `inSession` state.

  **Option B (simpler, zero-architecture):** In the `listener`, when `sessionEnded` fires, retrieve the last `inSession` state's steps by checking if `prev` was `inSession`. Since the listener receives `(context, state)`, we can look at `context.read<SharedSessionBloc>().state` — but that's already `sessionEnded` at this point. We need the previous state.

  **Recommended approach (Option A):** Convert `SharedSessionLobbyPage` from `StatelessWidget` to `StatefulWidget`; add a `List<ExerciseStep> _lastSteps = const []` field; in `BlocBuilder.builder`, when `state` is `inSession`, update `_lastSteps = s.steps` (call `setState` is unnecessary — we just set the field; it's only read in the listener).

  ```dart
  class SharedSessionLobbyPage extends StatefulWidget {
    const SharedSessionLobbyPage({super.key});

    @override
    State<SharedSessionLobbyPage> createState() =>
        _SharedSessionLobbyPageState();
  }

  class _SharedSessionLobbyPageState extends State<SharedSessionLobbyPage> {
    List<ExerciseStep> _lastSteps = const [];
    ...
  }
  ```

  In `BlocBuilder`:
  ```dart
  inSession: (s) {
    _lastSteps = s.steps;   // cache for sessionEnded navigation (no setState needed)
    return _SharedInSessionView(
      stepIndex: s.stepIndex,
      elapsedSeconds: s.elapsedSeconds,
      isHost: s.isHost,
      steps: s.steps,
      participantCount: s.participants.length,
      droppedHandle: s.droppedHandle,
    );
  },
  ```

- [x] **5.3** In the `listener` callback, add the `sessionEnded` branch:

  ```dart
  listener: (context, state) {
    state.mapOrNull(
      cancelled: (_) {
        if (context.canPop()) context.pop();
      },
      sessionEnded: (_) {
        final totalDurationMinutes =
            _lastSteps.fold(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
        context.go(
          AppRouter.sessionRpe,
          extra: RpeSubmitArgs(
            planId: null,
            sessionIndex: 0,
            abandoned: false,
            armKey: 'shared_session',   // placeholder; Story 20.5 wires the real key
            durationMinutes: totalDurationMinutes,
            sessionLogId: null,
          ),
        );
      },
      lobby: (_) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sharedSessionRefreshError)),
        );
      },
    );
  },
  ```

  **Critical — `context.go` vs `context.push`:** Use `context.go` to clear the lobby route from the stack, consistent with how `InSessionPage` navigates to RPE (`context.go(AppRouter.sessionRpe, ...)`).

  **Critical — `planId: null` in `RpeSubmitArgs`:** The `RpeFeedbackCubit` checks `planId != null` before writing to `SessionLogs` and before crediting the bandit arm. With `planId: null`, the RPE UI is shown and the rating is collected but no persistence or bandit update occurs. Story 20.5 introduces a `sharedPlanId` or per-participant arm key to close this gap. The `armKey: 'shared_session'` is stored in the RPE state but never used when `planId == null`.

  **Critical — `RpeSubmitArgs` import:** Add `import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';` to the lobby page if not already present.

---

### Task 6 — Tests (AC1, AC2, AC4, AC6, AC7, AC8, E18R-1)

- [x] **6.1** Add to `pulse_coach/test/bloc/shared_session/shared_session_bloc_test.dart` (in a new describe group `'session end'`):

  ```
  [20.4-BLOC-001] SessionEndRequested from host → sendBroadcast called with event: 'session_ended'
  [20.4-BLOC-002] SessionEndRequested from follower (non-host) → sendBroadcast NOT called
  [20.4-BLOC-003] BroadcastEvent.sessionEnded received → SharedSessionState.sessionEnded emitted
  [20.4-BLOC-004] session_ended broadcast → leaveChannel() called (AC8 precondition: channel torn down)
  ```

  Use `@GenerateMocks` already at the top of the test file. Add tests alongside existing 19.2-BLOC-xxx entries. Verify `mockGateway.sendBroadcast` is or is not called using `verify(mockGateway.sendBroadcast(event: 'session_ended', payload: {})).called(1)`.

  **Note:** 19.2-BLOC-007 tests `SessionStarted → inSession` already. 19.2-BLOC-010/011 test `HostStepAdvanced`. The missing tests are around `SessionEndRequested` and `SessionEnded`. Add only these 4 — do NOT duplicate existing tests.

- [x] **6.2** Create `pulse_coach/test/widget/shared_session/shared_in_session_view_test.dart` (placed in shared_session dir alongside related lobby tests):

  ```
  [20.4-WIDGET-001] follower path renders step title + participant badge ('2 partecipanti' for IT locale)
  [20.4-WIDGET-002] follower path: didUpdateWidget with new stepIndex → displayedElapsed resets to widget.elapsedSeconds
  [20.4-WIDGET-003] host path renders InSessionView widget and _ParticipantBadge
  [20.4-WIDGET-004] host path abandon button exists (finds TextButton with inSessionAbandonButton label)
  ```

  Mount `_SharedInSessionView` (exposed for test via a named key or test-only export pattern, or by mounting `SharedSessionLobbyPage` with pre-seeded bloc state). Use `tester.pumpWidget(...)` with a minimal `MaterialApp(home: BlocProvider.value(value: mockBloc, child: widget))`.

  **Note on widget accessibility:** `_SharedInSessionView` is a private class. For widget testing, mount `SharedSessionLobbyPage` inside a `BlocProvider.value(value: mockBloc)` where `mockBloc` starts in `SharedSessionState.inSession(...)`. This avoids needing to expose the private widget.

- [x] **6.3** E18R-1 — Added to `shared_in_session_view_test.dart`:

  ```
  [20.4-WIDGET-005] 360×640 viewport, follower: _SharedInSessionView follower path renders without overflow (E18R-1)
  [20.4-WIDGET-006] 360×640 viewport, host: host path renders without overflow (E18R-1)
  ```

  Use `tester.view.physicalSize = const Size(360, 640)` / `tester.view.devicePixelRatio = 1.0` pattern. Provide `LocaleCubit` (required since i18n migration) and wrap in `MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, ...)`.

  **Widget test scope:** Mount `SharedSessionLobbyPage` with a `MockSharedSessionBloc` that returns `SharedSessionState.inSession(stepIndex: 0, elapsedSeconds: 0, isHost: false, steps: [ExerciseStep(title: 'Test', instruction: 'Do it', durationSeconds: 30)], participants: [/* 2 mocked participants */])`. Verify no `RenderBox` overflow and that `'2 partecipanti'` (IT locale) appears.

---

### Task 7 — build_runner + flutter analyze (AC10)

- [x] **7.1** From `pulse_coach/`, run:
  ```bash
  flutter pub get
  ```
  Expected: regenerates `app_localizations*.dart` with new `sharedSessionParticipantCount` key.

- [x] **7.2** From `pulse_coach/`, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Expected regenerated files:
  - `injection.config.dart` — no change unless new `@injectable` class added (none in this story; existing `InSessionCubit` is NOT injectable — it is constructed manually with `new InSessionCubit(...)`)
  
  **Note:** Story 20.4 does NOT add any new `@injectable` classes. No new `@freezed` models. `build_runner` may be a no-op here unless prior changes left unbuilt files. Run it anyway to be safe.

- [x] **7.3** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  ```
  Expected: 0 issues.

- [x] **7.4** From `pulse_coach/`, run:
  ```bash
  flutter test
  ```
  Expected: all 1200 existing tests pass plus all new tests pass. Zero regressions.

---

## Dev Notes

### Architecture Context

**File being modified — `shared_session_lobby_page.dart`:**
This file contains everything: `SharedSessionLobbyPage`, `_LobbyShimmer`, `_LobbyView`, `_LobbyViewState`, `_ParticipantRow`, `_CancelledView`, `_SharedInSessionView`, `_ErrorView`, `_SessionEndedView`. All are private to this file. Story 20.4 extends `_SharedInSessionView` and `SharedSessionLobbyPage` within the same file.

**`InSessionCubit` is NOT `@injectable`:** It is always constructed directly with `new InSessionCubit(steps: ..., ...)`. Do NOT add `@injectable` to it — the solo `InSessionPage` also constructs it directly. No DI registration needed; no `build_runner` impact.

**`InSessionCubit` is in `features/session/`; `_SharedInSessionView` is in `features/social/shared_session/`:** Cross-feature dependency is acceptable here: the shared in-session view IS fundamentally an in-session view for the host. Import: `import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';`.

**`VibrationHapticService` import:** Already used in `InSessionPage` at `lib/features/session/presentation/utils/haptic_service.dart`. Import: `import 'package:pulse_coach/features/session/presentation/utils/haptic_service.dart';`.

**`InSessionView` import:** `lib/features/session/presentation/widgets/in_session_view.dart`. Import: `import 'package:pulse_coach/features/session/presentation/widgets/in_session_view.dart';`.

**`RpeSubmitArgs` import:** `lib/features/session/domain/entities/rpe_submit_args.dart`.

**`AppRouter.sessionRpe` constant:** Already exists at `lib/core/routing/app_router.dart` line 48. Verified safe to use from the lobby page.

### Host Timer Design

The host's `InSessionCubit` uses the COUNTDOWN model (per step `secondsRemaining`). Between step advances, it counts down from `steps[stepIndex].durationSeconds`. When `secondsRemaining` hits 0, `_advanceStep()` increments `currentStepIndex` and emits new state.

**`HostStepAdvanced.elapsedSeconds`** represents total elapsed from session start. At the start of step `idx`:
```
elapsedSeconds = sum(steps[0..idx-1].durationSeconds)
```

This is computed by `_elapsedAtStepStart(idx)` in `_SharedInSessionViewState`.

**Why `elapsedSeconds` in `HostStepAdvanced`?** The follower uses this to snap their display clock to the authoritative value. The followers' local ticks will have accumulated small drift; the snap corrects it.

### Follower Display Clock

The follower has a `Timer.periodic(1s)` that increments `_displayedElapsed`. This gives a continuously ticking clock between broadcasts. On each `step_advanced` broadcast, `didUpdateWidget` fires with new `widget.elapsedSeconds` and `_displayedElapsed` is reset to this value. Net effect: the follower clock ticks freely but re-syncs at each step boundary.

**Why not tick the Bloc state every second for followers?** The `SharedSessionBloc` is authoritative for step index. Ticking elapsed time via bloc events every second would be excessive (60+ events per minute). A local `Timer` in the widget is the right scope for display-only state.

### `sessionEnded` State and Navigation

`SharedSessionState.sessionEnded` is emitted by `_onBroadcastReceived` when `SessionEnded()` broadcast arrives. At this point `leaveChannel()` has already been called (see `shared_session_bloc.dart` line 299–303). The `sessionEnded` state is TERMINAL — no more broadcast updates.

**`context.go(AppRouter.sessionRpe)` in `sessionEnded` listener:** This replaces the entire navigation stack above `/social` with the RPE screen. The user cannot pop back to the (now-invalid) lobby. After RPE, they return to `AppRouter.today` (the existing RPE page behavior when `planId == null`).

**`armKey: 'shared_session'`:** This is a deliberate placeholder. The `RpeFeedbackCubit` calls `_banditUseCase.call(armKey: args.armKey, reward: ...)` only if `args.planId != null`. With `planId: null`, the bandit update is skipped entirely. Story 20.5 introduces proper arm key derivation for shared sessions.

### `SharedSessionLobbyPage` → `StatefulWidget`

Converting from `StatelessWidget` to `StatefulWidget` is the minimal change needed to cache `_lastSteps`. The single field `List<ExerciseStep> _lastSteps = const []` is write-only during the `inSession` render phase and read-only during the `sessionEnded` listener. No `setState` is needed — this is NOT display state.

### Existing Tests That Require Updates

**None expected:** The `SharedSessionBloc` constructor signature did NOT change in Story 20.4. No new constructor params, no new use cases injected. All existing bloc test instantiations remain valid as-is.

**Check widget tests that mount `SharedSessionLobbyPage`:** If any widget test mounts the lobby page in `inSession` state, it will need to supply the new `isHost` and `participantCount` params. Search: `grep -r 'SharedSessionLobbyPage\|inSession(' test/`. Update any affected instantiations to pass `isHost: false, participantCount: 2` (or appropriate values).

### E18R-1 Widget Test Pattern

Use this pattern (from Story 20.3 precedent):
```dart
setUp(() {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
});
tearDown(() {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
});
```

Provide `LocaleCubit` (required since Epic 7.5 i18n migration) and `AppLocalizations` via `MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, ...)`.

### File Sizes

`shared_session_lobby_page.dart` is currently ~485 lines. After Task 2+3, it will grow by ~100–120 lines. This approaches the 400-line soft guideline but stays under the 800-line hard limit. Acceptable for a single cohesive page file.

### Project Structure Notes

- **Modified file:** `lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart` — all changes are additive (new `StatefulWidget` impl, new private widget)
- **No new files** for the main feature code (everything goes into the lobby page file)
- **New test files:**
  - `test/widget/social/shared_in_session_view_test.dart` (new)
  - Additions to `test/bloc/shared_session/shared_session_bloc_test.dart` (new describe group)
- **Modified ARB files:** `lib/l10n/app/app_en.arb`, `lib/l10n/app/app_it.arb`

### References

- [Source: epics.md#Story 20.4 lines ~2668–2700]
- [Source: epics.md#FR71, FR72, NFR31, NFR4, UX-DR29]
- [Source: lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart — existing _onBroadcastReceived, _onHostStepAdvanced, _onSessionEndRequested handlers]
- [Source: lib/features/social/shared_session/presentation/bloc/shared_session_state.dart — inSession + sessionEnded factory constructors]
- [Source: lib/features/social/shared_session/presentation/bloc/shared_session_event.dart — HostStepAdvanced, SessionEndRequested events]
- [Source: lib/features/session/presentation/bloc/in_session_cubit.dart — InSessionCubit reused for host timer (persistence disabled when sessionLogsDao: null)]
- [Source: lib/features/session/presentation/widgets/in_session_view.dart — v1 InSessionView widget reused in host path]
- [Source: lib/features/session/presentation/pages/in_session_page.dart — VibrationHapticService initialization pattern]
- [Source: lib/features/session/domain/entities/rpe_submit_args.dart — RpeSubmitArgs fields]
- [Source: lib/core/routing/app_router.dart line 48 — AppRouter.sessionRpe constant]
- [Source: action-item-ledger.md#Epic 19 kickoff triage — E18R-1/E18R-2/E18R-CB2 firing conditions]
- [Source: test/bloc/shared_session/shared_session_bloc_test.dart — existing bloc test patterns (19.2-BLOC-007, 19.2-BLOC-010)]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Converted `SharedSessionLobbyPage` from `StatelessWidget` to `StatefulWidget` (`_SharedSessionLobbyPageState`) with `_lastSteps` field to cache steps for `sessionEnded` navigation.
- Converted `_SharedInSessionView` from `StatelessWidget` to `StatefulWidget` with two execution paths: host (creates `InSessionCubit` with persistence disabled, streams `HostStepAdvanced` + `SessionEndRequested` to `SharedSessionBloc`) and follower (`Timer.periodic(1s)` + `didUpdateWidget` snap-and-haptic on step change).
- Added `_ParticipantBadge` private widget using `l10n.sharedSessionParticipantCount(count.toString())` — `{count}` as String type to avoid plural metadata in this iteration.
- Added `_DroppedHandleNotice` private widget for host path Stack overlay.
- `BlocListener.listenWhen` extended to include `sessionEnded`; listener navigates with `context.go(AppRouter.sessionRpe, extra: RpeSubmitArgs(planId: null, armKey: 'shared_session', ...))`.
- Added `sharedSessionParticipantCount` ARB key to `app_en.arb` and `app_it.arb` with `{count}` String placeholder.
- WIDGET-002 required two `tester.pump()` calls: first processes BlocBuilder rebuild (which calls `didUpdateWidget` → `setState`); second processes the resulting `setState` rebuild.
- Test placed in `test/widget/shared_session/` (not `test/widget/social/`) to co-locate with related lobby page tests; reuses `shared_session_lobby_page_test.mocks.dart`.
- `flutter test`: 1210 tests pass (10 new: 4 bloc + 6 widget). `flutter analyze lib/ test/`: 0 issues.

### File List

- `pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart` (modified)
- `pulse_coach/lib/l10n/app/app_en.arb` (modified)
- `pulse_coach/lib/l10n/app/app_it.arb` (modified)
- `pulse_coach/test/bloc/shared_session/shared_session_bloc_test.dart` (modified)
- `pulse_coach/test/widget/shared_session/shared_in_session_view_test.dart` (new)

## Review Findings

_Code review 2026-06-26 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). Baseline: `flutter analyze lib/ test/` = 0 issues; `flutter test` = 1210 pass. AC1–AC10 all satisfied in implementation._

- [x] [Review][Patch] (was Decision, patched) Follower→host promotion mid-session strands all participants — On host drop, `SharedSessionBloc._onPresenceReceived` (shared_session_bloc.dart:244-254) promotes the lowest-userId follower and re-emits `inSession(isHost: true)`. `_SharedInSessionViewState` read `isHost` only in `initState`, so on rebuild `_buildHostView` found `_hostCubit == null` and returned `SizedBox.shrink()` permanently. **FIXED:** `didUpdateWidget` now detects the `isHost` flip and calls `_promoteToHost()` (cancels follower tick, spins up the host `InSessionCubit`). Cubit restarts from step 0 (resume-mid-session deferred to 20.5). Locked by test `20.4-WIDGET-007`. [shared_session_lobby_page.dart `_SharedInSessionViewState`]
- [x] [Review][Patch] (patched) Empty `steps` crashes host in `initState` [shared_session_lobby_page.dart:_initHostCubit] — `initState` constructed `InSessionCubit` unconditionally; the constructor calls `steps.first.durationSeconds` (in_session_cubit.dart:52) → `StateError` on an empty list. **FIXED:** `_initHostCubit` now returns early when `widget.steps.isEmpty`; the empty-steps Scaffold in `build()` handles rendering.
- [x] [Review][Defer] Host abandon recorded as `abandoned: false` [shared_session_lobby_page.dart:54-68] — deferred: spec AC8 hardcodes `abandoned: false` and `planId: null` disables persistence/bandit, so the flag has no consumer until Story 20.5 wires per-participant RPE.
- [x] [Review][Defer] `sessionEnded` reached without `inSession` render → RPE with 0 duration [shared_session_lobby_page.dart:54-68] — deferred: low-probability path; `_lastSteps` stays `const []`, spec accepts "from last inSession snapshot".
- [x] [Review][Defer] Host participant badge `Positioned(top:16)` may overlap `InSessionView` top content [shared_session_lobby_page.dart:_buildHostView] — deferred: visual only; 360×640 tests pass without exception; verify on device.
- [x] [Review][Defer] Participant count has no plural form ("1 partecipanti") [app_it.arb/app_en.arb] — deferred: spec explicitly chose `{count}` String over ICU plural; Story 20.5 may upgrade.
- [x] [Review][Defer] AC6 haptic (`HapticFeedback.mediumImpact`) fire not asserted by any test — deferred: coverage gap, not in Task 6 scope; static call is hard to assert.
- [x] [Review][Defer] AC7 follower `Timer.periodic(1s)` tick not asserted by any test — deferred: coverage gap, not in Task 6 scope.
