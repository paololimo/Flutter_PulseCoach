---
baseline_commit: 19193ee
---

# Story 20.5: Per-Participant RPE and Protective-State Social Suppression

Status: done

## Story

As a shared session participant,
I want to submit my own RPE after the session and have the social layer respect my recovery state,
So that social pressure never overrides the v1 recovery-empathy promise.

## Context

**Epic 20 — Co-Located Shared Sessions (v2.4b).** Stories 20.1–20.4 built the full join pipeline, group constraint resolver, co-location check, and synchronized in-session view. Story 20.5 closes the epic by:

1. **Wiring the group plan so steps are never empty** — currently `steps: const []` flows from `social_page.dart` through `SharedSessionJoined` → `SharedSessionState.lobby.steps` and into `SharedSessionState.inSession.steps`. The `_SharedInSessionViewState._initHostCubit` guard (`if (widget.steps.isEmpty) return;`) silently no-ops the host path today. This story generates the group plan in `SharedSessionBloc._onStartTapped`, includes plan params in the `session_started` broadcast, and lets each device generate `ExerciseStep`s locally (in the `BlocBuilder`) so the in-session experience actually works.

2. **Wiring bandit reward for shared sessions** — `armKey: 'shared_session'` (Story 20.4 placeholder) is not in `banditArmKeys` (`lib/ai/bandit/bandit_state.dart:27`), so `RewardCalculator` treats it as a no-op and the per-user bandit never adapts. This story derives a proper arm key (`'{sessionType}_{intensityName}'`) from the generated group plan and passes it through the broadcast → `SharedSessionState.sessionEnded.armKey` → `RpeSubmitArgs.armKey` so `PostRpeAdaptationCubit.triggerUpdate` hits a real arm and the bandit updates.

3. **Protective-State Social Suppression guards** — The Today screen does not yet have a shared-session CTA (AC2 is trivially satisfied), but adding one without a behavioral-state gate would violate UX-DR31. This story adds a static `_suppressSharedSessionCta(BehavioralState)` helper to `today_page.dart` and a matching test to lock the contract in before Epic 21 (leaderboard) adds rank-movement to Today.

**What is already built (DO NOT REBUILD):**
- `GroupConstraintResolver` at `lib/ai/safety/group_constraint_resolver.dart` — pure Dart, tested (Story 20.2)
- `ParticipantProfile` and `GroupConstraint` domain entities (Story 20.2)
- `_SharedInSessionViewState` — host and follower paths with `initState`/`didUpdateWidget` (Story 20.4)
- `_SharedSessionLobbyPageState._lastSteps` — captures steps on `inSession` render (Story 20.4)
- `BlocListener` for `sessionEnded` → RPE navigation with `armKey: 'shared_session'` placeholder (Story 20.4)
- `PostRpeAdaptationCubit` skips bandit update when `armKey == null || armKey.isEmpty`, and would update with `'shared_session'` but that arm doesn't exist in `banditArmKeys` (no-op, not a crash)

**What Story 20.5 builds:**
1. Extend `BroadcastEvent.sessionStarted` with `sessionType`, `intensity`, `durationMinutes`, `armKey` (primitives → no serialization complexity)
2. Wire `RealtimeGateway.parseBroadcast` to read those fields from the `session_started` payload
3. Add `sessionType`, `intensity`, `durationMinutes` to `SharedSessionState.inSession`; add `armKey` to `SharedSessionState.sessionEnded`
4. Inject `AppDatabase` into `SharedSessionBloc`; in `_onStartTapped`, read behavioral state, build `ParticipantProfile`, run `GroupConstraintResolver`, derive plan params + `armKey`, store `_armKey` instance var, send broadcast with params
5. In `SharedSessionLobbyPage.BlocBuilder`, generate `ExerciseStep`s from `inSession` plan params when they are needed
6. In `BlocListener.sessionEnded`, replace `armKey: 'shared_session'` with `state.armKey`
7. Add `_suppressSharedSessionCta(BehavioralState)` helper and tests in `today_page.dart`

**What this story does NOT include:**
- Per-participant profile sharing over the channel (followers' fitness levels/exclusions are NOT collected; host profile is used as the sole `GroupConstraintResolver` input — a known MVP limitation documented in dev notes)
- Writing a `session_logs` row for the shared session (RPE writes `sessionId: 0` per Story 20.4's deliberate decision; plan ID remains `null`)
- Leaderboard point award logic (Epic 21, still `backlog`)
- Session abandon flow for shared sessions (already deferred in Story 20.4 review)

**E9-K1 fire-check:**

| Active item | Fires? | Required action |
|---|---|---|
| `E18R-1` small-viewport shimmer test | ✅ YES — `shared_session_lobby_page.dart` BlocBuilder changes touch `inSession` arm | Add 360×640 widget test for `inSession` → steps generated correctly (Task 7.3) |
| `E18R-2` backend-failure localization | ❌ No — DB read error in `_onStartTapped` is non-fatal (broadcast falls back to defaults) | Not applicable |
| `E18R-CB2` localized-IT review | ❌ No — no raw `failure.message` in new code paths | Not applicable |
| `E18R-4` social `ProUpsellSheet` copy | ❌ No | Not applicable |
| `E10R-2` non-UTC week-bucketing | ❌ No | Not applicable |
| `E6-P1` patch-validation gate | Fires at code-review time if DI/lifecycle changes | Reviewer re-runs `flutter analyze` after any review patches |

## Acceptance Criteria

**AC1 — RPE flows to per-user bandit with a valid arm key (FR72):**
Given the shared session has ended and the RPE screen is presented
When the user submits their RPE rating
Then `PostRpeAdaptationCubit.triggerUpdate(rpeValue)` calls `UpdateBanditReward.call(armKey: '<sessionType>_<intensity>', rpeValue: ...)` where `armKey` is one of the 9 values in `banditArmKeys`; the bandit state in the DB is updated; each participant's bandit is updated independently on their own device with no cross-participant visibility

**AC2 — AtRisk/Recovering: no shared-session CTA on Today screen (UX-DR31):**
Given the `DailyPlanLoaded.behavioralState` is `BehavioralState.atRisk` or `BehavioralState.recovering`
When `today_page.dart`'s `_suppressSharedSessionCta(behavioralState)` is called
Then it returns `true`; a widget test asserts that no button with text matching `sharedSession*` ARB key appears in the Today page when behavioral state is AtRisk or Recovering

**AC3 — AtRisk/Recovering: leaderboard rank change suppressed from Today screen (UX-DR31, Epic 21 guard):**
Given `_suppressSharedSessionCta` is defined and tested
When a future Epic 21 CTA or rank badge is added to `today_page.dart`
Then the developer MUST gate it behind `_suppressSharedSessionCta(loaded.behavioralState)` being false; the guard is documented with a code comment explaining UX-DR31

**AC4 — GroupConstraintResolver AtRisk cap applied to group plan (FR70):**
Given the host's `BehavioralState` is `atRisk` when they tap "Inizia"
When `SharedSessionBloc._onStartTapped` runs
Then `GroupConstraintResolver.resolve([hostProfile])` is called with `hostProfile.safetyCapIntensity == SessionIntensity.low`; the resulting `GroupConstraint.intensityCeiling == SessionIntensity.low`; the broadcast payload carries `intensity <= 3` (i.e., in the low range); all participant devices render the session with low intensity steps

**AC5 — Group plan params distributed via broadcast (FR71):**
Given the host taps "Inizia"
When `SharedSessionBloc._onStartTapped` fires
Then `_gateway.sendBroadcast(event: 'session_started', payload: {'session_type': sessionType, 'intensity': intensity, 'duration_minutes': durationMinutes, 'arm_key': armKey})` is called; follower devices receive these params in the `BroadcastEvent.sessionStarted` event; their `SharedSessionState.inSession` updates with the correct `sessionType`, `intensity`, `durationMinutes`

**AC6 — Steps generated from plan params, never empty in in-session view (UX-DR29):**
Given `SharedSessionState.inSession` has `sessionType`, `intensity`, `durationMinutes` (from broadcast)
When `SharedSessionLobbyPage.BlocBuilder` renders the `inSession` arm
Then `SessionStepGenerator.generate(PlannedSession(sessionType: s.sessionType, intensity: s.intensity, durationMinutes: s.durationMinutes), l10n)` is called; the result (3 steps: warm-up, main, cool-down) is passed to `_SharedInSessionView`; `_SharedInSessionViewState._initHostCubit` no longer hits the `isEmpty` guard

**AC7 — Proper armKey flows through to RPE navigation (FR72):**
Given `SharedSessionBloc` emits `SharedSessionState.sessionEnded(armKey: 'mobility_low')` (for example)
When `SharedSessionLobbyPage`'s `BlocListener.sessionEnded` fires
Then `context.go(AppRouter.sessionRpe, extra: RpeSubmitArgs(..., armKey: state.armKey, ...))` uses the state's `armKey` instead of the hardcoded `'shared_session'` placeholder

**AC8 — Zero regressions:**
Given all new and modified files are in place and `build_runner` has been run
When `flutter test` and `flutter analyze lib/ test/` run from `pulse_coach/`
Then all 1210 existing tests pass plus all new tests pass; analyzer reports 0 issues

## Tasks / Subtasks

---

### Task 1 — Extend `BroadcastEvent.sessionStarted` with plan params (AC5)

**Why:** The broadcast currently carries no data for `session_started`. Followers and the host (via echo) need `sessionType`, `intensity`, `durationMinutes`, `armKey` to initialize the in-session state correctly.

- [x] **1.1** Edit `pulse_coach/lib/features/social/shared_session/domain/entities/broadcast_event.dart`.

  Replace:
  ```dart
  const factory BroadcastEvent.sessionStarted() = SessionStarted;
  ```
  With:
  ```dart
  const factory BroadcastEvent.sessionStarted({
    @Default('mobility') String sessionType,
    @Default(5) int intensity,
    @Default(20) int durationMinutes,
    @Default('mobility_medium') String armKey,
  }) = SessionStarted;
  ```

  **Critical — `@Default` on all fields:** Existing callers (e.g., test mocks) that call `BroadcastEvent.sessionStarted()` with no args must compile. The defaults represent a safe fallback (medium-intensity mobility session).

  **Critical — Must run `build_runner` after this change.** The `@freezed` class requires codegen. Do it in Task 5.

---

### Task 2 — Parse plan params in `RealtimeGateway` (AC5)

**Why:** `realtime_gateway.dart` currently ignores the `session_started` callback payload (`callback: (_) => ...`). We need to parse the plan params.

- [x] **2.1** Edit `pulse_coach/lib/core/cloud/realtime_gateway.dart`.

  Replace the existing `session_started` callback:
  ```dart
  .onBroadcast(
    event: 'session_started',
    callback: (_) =>
        _broadcastController?.add(const BroadcastEvent.sessionStarted()),
  )
  ```
  With:
  ```dart
  .onBroadcast(
    event: 'session_started',
    callback: (payload) {
      final event = _parseBroadcast('session_started', payload);
      if (event != null) _broadcastController?.add(event);
    },
  )
  ```

- [x] **2.2** Update `parseBroadcast` (the `@visibleForTesting` static method at line ~159) to handle the `session_started` case with plan params:

  Replace:
  ```dart
  case 'session_started':
    return const BroadcastEvent.sessionStarted();
  ```
  With:
  ```dart
  case 'session_started':
    final sessionType = payload['session_type'] as String? ?? 'mobility';
    final intensity = (payload['intensity'] as num?)?.toInt() ?? 5;
    final durationMinutes = (payload['duration_minutes'] as num?)?.toInt() ?? 20;
    final armKey = payload['arm_key'] as String? ?? '${sessionType}_medium';
    return BroadcastEvent.sessionStarted(
      sessionType: sessionType,
      intensity: intensity,
      durationMinutes: durationMinutes,
      armKey: armKey,
    );
  ```

  **Critical — Defensive parsing with defaults:** The payload may be empty (e.g., older clients, test doubles, or the host's own echo from Story 20.4's hardcoded `payload: {}`). The `??` fallbacks ensure we always emit a valid `BroadcastEvent` even if fields are missing.

  **Note on the private `_parseBroadcast` wrapper at line ~181:** It simply calls `parseBroadcast(event, payload)`. No change needed there.

---

### Task 3 — Extend `SharedSessionState` with plan params and armKey (AC5, AC7)

**Why:** `inSession` needs to carry `sessionType/intensity/durationMinutes` so the page can generate steps without storing presentation data in the bloc. `sessionEnded` needs `armKey` so the listener can use it in RPE navigation.

- [x] **3.1** Edit `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.dart`.

  Add `sessionType`, `intensity`, `durationMinutes` to `inSession` (with `@Default` so existing callers compile):
  ```dart
  const factory SharedSessionState.inSession({
    required int stepIndex,
    required int elapsedSeconds,
    required bool isHost,
    required List<ExerciseStep> steps,
    @Default([]) List<ParticipantPresence> participants,
    String? droppedHandle,
    @Default('mobility') String sessionType,       // NEW — from broadcast
    @Default(5) int intensity,                     // NEW — from broadcast
    @Default(20) int durationMinutes,              // NEW — from broadcast
  }) = _InSession;
  ```

  Add `armKey` to `sessionEnded`:
  ```dart
  const factory SharedSessionState.sessionEnded({
    @Default('mobility_medium') String armKey,     // NEW — from _armKey instance var
  }) = _SessionEnded;
  ```

  **Critical — `@Default` on all new fields:** All existing callers of `SharedSessionState.inSession(...)` — bloc handlers, test mocks — that don't pass these new fields must continue to compile. The new fields are additive.

  **Critical — Must run `build_runner` after this change** (Task 5).

  **Note on `steps` field:** The `steps` field remains in `inSession`. It will be `const []` in all cases from the bloc (bloc never generates steps). The page's `BlocBuilder` generates steps from `sessionType/intensity/durationMinutes` and passes them to `_SharedInSessionView`. The `steps` field is now effectively unused from the bloc's perspective — but removing it would require changes to `_SharedInSessionView` constructor (Story 20.4, already reviewed) and is out of scope.

---

### Task 4 — Wire group plan generation in `SharedSessionBloc` (AC4, AC5, AC7)

**Why:** The bloc is the right place for plan generation (it's injectable, can access DB, and fires the broadcast). It does NOT generate `ExerciseStep`s (needs l10n) — it only computes `{sessionType, intensity, durationMinutes, armKey}`.

- [x] **4.1** Add `AppDatabase` to `SharedSessionBloc` constructor.

  In `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`:

  **Add import:**
  ```dart
  import 'package:pulse_coach/core/database/app_database.dart';
  import 'package:pulse_coach/ai/safety/group_constraint.dart';
  import 'package:pulse_coach/ai/safety/group_constraint_resolver.dart';
  import 'package:pulse_coach/ai/safety/participant_profile.dart';
  import 'package:pulse_coach/ai/safety/safety_constraints.dart';
  import 'package:pulse_coach/ai/state_machine/behavioral_state.dart' as ai_state;
  ```

  **Add field and extend constructor:**
  ```dart
  final AppDatabase _db;
  String? _armKey;   // set in _onStartTapped; used in _onBroadcastReceived for SessionEnded

  SharedSessionBloc(
    this._gateway,
    this._deleteUseCase,
    this._refreshUseCase,
    this._locationService,
    this._db,          // NEW
  ) : super(const SharedSessionState.initial()) {
    // ... same event registrations as before ...
  }
  ```

  **Critical — `injection.config.dart` regenerates automatically** after adding `AppDatabase _db` to the constructor and running `build_runner` (Task 5). Do NOT manually edit `injection.config.dart`.

- [x] **4.2** Implement group plan computation helpers at the bottom of the file (before `close()`):

  ```dart
  // Maps behavioral state to the per-user safety intensity cap per FR24.
  SessionIntensity? _safetyCapFrom(ai_state.BehavioralState state) => switch (state) {
    ai_state.BehavioralState.atRisk => SessionIntensity.low,
    ai_state.BehavioralState.recovering => SessionIntensity.medium,
    ai_state.BehavioralState.fatigued => SessionIntensity.medium,
    ai_state.BehavioralState.active => null,
  };

  ai_state.BehavioralState _parseBehavioralState(String? raw) =>
      switch (raw?.toLowerCase()) {
        'atrisk' => ai_state.BehavioralState.atRisk,
        'recovering' => ai_state.BehavioralState.recovering,
        'fatigued' => ai_state.BehavioralState.fatigued,
        _ => ai_state.BehavioralState.active,
      };

  // Maps SessionIntensity ceiling to a concrete intensity int value.
  // null = no cap → medium (5). Ranges: low 1–3, medium 4–7, high 8–10.
  int _intensityFromCeiling(SessionIntensity? ceiling) => switch (ceiling) {
    SessionIntensity.low => 3,
    SessionIntensity.medium => 5,
    SessionIntensity.high => 7,
    null => 5,
  };

  String _intensityName(int intensity) {
    if (intensity <= 3) return 'low';
    if (intensity <= 7) return 'medium';
    return 'high';
  }
  ```

  **Critical — exhaustive switch:** The `_safetyCapFrom` switch over `BehavioralState` must cover all enum values with no `default:` arm so the compiler catches new state values.

- [x] **4.3** Replace `_onStartTapped` with the group-plan-aware implementation:

  ```dart
  Future<void> _onStartTapped(
      SessionStartTapped event, Emitter<SharedSessionState> emit) async {
    final lobbyState = state.mapOrNull(lobby: (s) => s);
    if (lobbyState == null || !lobbyState.isHost) return;
    if (lobbyState.participants.length < 2) return;

    // Derive group plan from host's behavioral state via GroupConstraintResolver.
    // Only the host's profile is used (followers' profiles are not available
    // over the wire in v2.4b; this is a documented MVP limitation).
    const sessionType = 'mobility'; // default group session type
    int intensity;
    int durationMinutes;
    try {
      final stateRow = await _db.behavioralStateDao.getLatestState();
      final behavioralState = _parseBehavioralState(stateRow?.currentState);
      final safetyCapIntensity = _safetyCapFrom(behavioralState);

      final hostProfile = ParticipantProfile(
        safetyCapIntensity: safetyCapIntensity,
        fitnessLevel: 'medium',
        movementExclusions: const {},
        availableTimeMinutes: 20,
      );

      final constraint = const GroupConstraintResolver().resolve([hostProfile]);
      intensity = _intensityFromCeiling(constraint.intensityCeiling);
      durationMinutes = constraint.durationMinutes;
    } catch (_) {
      // Non-fatal: fall back to safe defaults if DB read fails.
      intensity = 5;
      durationMinutes = 20;
    }

    final armKey = '${sessionType}_${_intensityName(intensity)}';
    _armKey = armKey;

    try {
      await _gateway.sendBroadcast(
        event: 'session_started',
        payload: {
          'session_type': sessionType,
          'intensity': intensity,
          'duration_minutes': durationMinutes,
          'arm_key': armKey,
        },
      );
    } catch (e) {
      emit(SharedSessionState.error(
        failure: RealtimeFailure('session_start_broadcast_failed: $e'),
      ));
    }
  }
  ```

  **Critical — catch around DB read is non-fatal:** If `behavioralStateDao.getLatestState()` throws, we fall back to medium intensity. A DB error here must NOT prevent the host from starting the session.

  **Critical — `_armKey` is an instance var:** It must be set BEFORE the broadcast is sent (in case the echo arrives before the next event loop tick). Set it synchronously from `armKey`.

- [x] **4.4** Update `_onBroadcastReceived` to wire plan params into `inSession` and `armKey` into `sessionEnded`:

  In the `SessionStarted()` case, replace:
  ```dart
  case SessionStarted():
    state.mapOrNull(
      lobby: (s) => emit(SharedSessionState.inSession(
        stepIndex: 0,
        elapsedSeconds: 0,
        isHost: s.isHost,
        steps: s.steps,
        participants: s.participants,
      )),
    );
  ```
  With:
  ```dart
  case SessionStarted(
    sessionType: final sessionType,
    intensity: final intensity,
    durationMinutes: final durationMinutes,
    armKey: final broadcastArmKey,
  ):
    _armKey ??= broadcastArmKey; // Follower path: armKey comes from broadcast, not from _onStartTapped
    state.mapOrNull(
      lobby: (s) => emit(SharedSessionState.inSession(
        stepIndex: 0,
        elapsedSeconds: 0,
        isHost: s.isHost,
        steps: const [],       // Page generates steps from plan params below
        participants: s.participants,
        sessionType: sessionType,
        intensity: intensity,
        durationMinutes: durationMinutes,
      )),
    );
  ```

  In the `SessionEnded()` case, replace:
  ```dart
  case SessionEnded():
    if (_joined) {
      _joined = false;
      unawaited(_gateway.leaveChannel());
    }
    emit(const SharedSessionState.sessionEnded());
  ```
  With:
  ```dart
  case SessionEnded():
    if (_joined) {
      _joined = false;
      unawaited(_gateway.leaveChannel());
    }
    emit(SharedSessionState.sessionEnded(
      armKey: _armKey ?? 'mobility_medium', // safe fallback if somehow unset
    ));
  ```

  **Critical — `_armKey ??= broadcastArmKey` on follower path:** The host sets `_armKey` in `_onStartTapped` before the broadcast. The follower never runs `_onStartTapped`, so their `_armKey` is `null` until the broadcast arrives. The `??=` sets it only if not already set (guards the host echo path too, since the host's `_armKey` is already set from `_onStartTapped`).

  **Critical — `steps: const []` in the new emission:** The page (not the bloc) generates steps. The bloc stores plan params in the state so the page can call `SessionStepGenerator`. The `steps` field in `SharedSessionState.inSession` remains for compatibility with `_SharedInSessionView`'s constructor, but is populated at the page level.

---

### Task 5 — Run `build_runner` (Tasks 1, 3, 4.1 all require codegen)

- [x] **5.1** From `pulse_coach/`, run:
  ```bash
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  ```

  **Expected regenerated files:**
  - `lib/features/social/shared_session/domain/entities/broadcast_event.freezed.dart` — new `sessionType/intensity/durationMinutes/armKey` fields in `SessionStarted`
  - `lib/features/social/shared_session/presentation/bloc/shared_session_state.freezed.dart` — new `sessionType/intensity/durationMinutes` in `_InSession`, `armKey` in `_SessionEnded`
  - `lib/core/di/injection.config.dart` — `SharedSessionBloc` factory gains `gh<AppDatabase>()` as the 5th arg
  - `lib/l10n/app_localizations*.dart` — no change (no new ARB keys)

  **Verify `injection.config.dart` update:**
  ```dart
  // Expected pattern after build_runner:
  gh.factory<_i596.SharedSessionBloc>(
    () => _i596.SharedSessionBloc(
      gh<_i281.RealtimeGateway>(),
      gh<_i102.DeleteSharedSessionUseCase>(),
      gh<_i1039.RefreshJoinCodeUseCase>(),
      gh<_i160.LocationService>(),
      gh<_i14.AppDatabase>(),   // NEW 5th parameter
    ),
  );
  ```

  If `build_runner` does NOT add `AppDatabase`, verify that `@injectable` is still on the class and that the import of `app_database.dart` is in scope.

---

### Task 6 — Update `SharedSessionLobbyPage` — step generation and RPE armKey (AC6, AC7)

**Why:** The page is the only place with access to `AppLocalizations` (needed for `SessionStepGenerator`). Steps are generated here from `inSession` plan params. The `sessionEnded` listener now uses `state.armKey` instead of the hardcoded placeholder.

- [x] **6.1** Add missing imports to `shared_session_lobby_page.dart` (check which are already present):

  ```dart
  import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
  import 'package:pulse_coach/features/session/presentation/utils/session_step_generator.dart';
  ```

  Both may already be imported or may need to be added. Check before adding.

- [x] **6.2** Update the `inSession` arm in `BlocBuilder` (`_SharedSessionLobbyPageState.build`) to generate steps from plan params:

  Find the current `inSession` arm:
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

  Replace with:
  ```dart
  inSession: (s) {
    // Generate steps from plan params (broadcast-derived). The bloc stores only
    // the primitive plan params; ExerciseStep generation requires l10n, which is
    // only available in the widget tree (UX-DR29, AC6).
    final l10n = AppLocalizations.of(context)!;
    final steps = SessionStepGenerator.generate(
      PlannedSession(
        sessionType: s.sessionType,
        intensity: s.intensity,
        durationMinutes: s.durationMinutes,
      ),
      l10n,
    );
    _lastSteps = steps;   // cache for sessionEnded navigation (no setState needed)
    return _SharedInSessionView(
      stepIndex: s.stepIndex,
      elapsedSeconds: s.elapsedSeconds,
      isHost: s.isHost,
      steps: steps,
      participantCount: s.participants.length,
      droppedHandle: s.droppedHandle,
    );
  },
  ```

  **Critical — `AppLocalizations.of(context)!` in `BlocBuilder.builder`:** This is safe because `BlocBuilder.builder` receives a `BuildContext` that is always inside the `MaterialApp` + `Localizations` widget tree. It will not be null.

  **Critical — `SessionStepGenerator.generate` is called on EVERY rebuild** of the `inSession` arm. This is acceptable: `generate` is a pure function with minimal computation (3-step list). If profiling reveals a concern, memoize with `_lastSteps` — but that optimization is NOT part of this story.

  **Critical — `PlannedSession` constructor:** Use the positional/named form matching the freezed factory:
  ```dart
  PlannedSession(
    sessionType: s.sessionType,
    intensity: s.intensity,
    durationMinutes: s.durationMinutes,
  )
  ```
  Check `planned_session.dart` for the exact factory name (the `@freezed` factory may be `.create` or just the default constructor).

- [x] **6.3** Add `_lastArmKey` field to `_SharedSessionLobbyPageState` to complement `_lastSteps`:

  ```dart
  String _lastArmKey = 'mobility_medium';   // safe default; set from sessionEnded state
  ```

  This is only used in the listener to avoid a null race. The authoritative value comes from `state.armKey` in the listener, not from this field — but having a field lets us set it one place.

  Actually: since `SharedSessionState.sessionEnded.armKey` is available directly in the listener, we don't need `_lastArmKey` at all. The listener receives the `state` with `armKey`. Use it directly:

  In the `sessionEnded` listener (Task 6.4), access `state.armKey`.

- [x] **6.4** Update `BlocListener.sessionEnded` handler to use `state.armKey` instead of hardcoded `'shared_session'`:

  Find:
  ```dart
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
  ```

  Replace with:
  ```dart
  sessionEnded: (s) {
    final totalDurationMinutes =
        _lastSteps.fold(0, (sum, step) => sum + step.durationSeconds) ~/ 60;
    context.go(
      AppRouter.sessionRpe,
      extra: RpeSubmitArgs(
        planId: null,
        sessionIndex: 0,
        abandoned: false,
        armKey: s.armKey,   // real arm key from group plan (AC7)
        durationMinutes: totalDurationMinutes,
        sessionLogId: null,
      ),
    );
  },
  ```

  **Critical — `sessionEnded: (s)` not `sessionEnded: (_)`:** The pattern match must bind the `_SessionEnded` pattern to a variable `s` (or any identifier) to access `s.armKey`. Verify the freezed-generated `mapOrNull` signature for `sessionEnded` — it receives a `_SessionEnded Function(_SessionEnded)` callback in the new pattern.

---

### Task 7 — Add social suppression guard to `today_page.dart` (AC2, AC3)

**Why:** The Today screen currently has no shared-session CTA (AC2 is satisfied by absence), but locking the contract in code with a static helper and a test prevents a future developer from inadvertently adding an unsuppressed CTA.

- [x] **7.1** Add `_suppressSharedSessionCta` static method to `today_page.dart`.

  **Placement:** At the bottom of the file, after the `_SessionEntry` class:

  ```dart
  // [Protective-State Social Suppression — UX-DR31, Story 20.5]
  // Returns true when the user is in a protective behavioral state (AtRisk or
  // Recovering). Any shared-session CTA on the Today screen — present or future
  // — MUST be hidden when this returns true. Rank-movement badges added by
  // Epic 21 follow the same rule.
  bool _suppressSharedSessionCta(BehavioralState state) =>
      state == BehavioralState.atRisk || state == BehavioralState.recovering;
  ```

  Add the required import to the top of the file:
  ```dart
  import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
  ```

  **Note:** This function is free-standing (not inside any class) like `_SessionEntry`. It is `bool` not `static` since it's at file scope. The comment is kept because the WHY is non-obvious and the consequence of violating the rule is product-level (recovery empathy promise).

---

### Task 8 — Tests (AC1, AC2, AC4, AC5, AC6, AC7, AC8, E18R-1)

- [x] **8.1** Add to `pulse_coach/test/bloc/shared_session/shared_session_bloc_test.dart` (new describe group `'group plan generation and arm key wiring'`):

  ```
  [20.5-BLOC-001] SessionStartTapped, host AtRisk → broadcast payload has intensity <= 3 and arm_key ending in '_low'
  [20.5-BLOC-002] SessionStartTapped, host Active → broadcast payload has intensity 4-7 and arm_key ending in '_medium'
  [20.5-BLOC-003] BroadcastEvent.sessionStarted({sessionType: 'mobility', intensity: 3, durationMinutes: 20, armKey: 'mobility_low'}) → SharedSessionState.inSession with sessionType: 'mobility', intensity: 3, durationMinutes: 20
  [20.5-BLOC-004] BroadcastEvent.sessionEnded() received after SessionStarted with armKey 'mobility_low' → SharedSessionState.sessionEnded(armKey: 'mobility_low') emitted
  ```

  For BLOC-001 and BLOC-002: mock `BehavioralStateDao.getLatestState()` to return the relevant state. The bloc test setup already uses `@GenerateMocks`; add `BehavioralStateDao` if not already mocked. Verify `mockGateway.sendBroadcast(event: 'session_started', payload: argThat(...))` is called with the expected payload.

  **Note on mocking `AppDatabase` in bloc tests:** `SharedSessionBloc` now takes `AppDatabase _db`. In tests, inject a mock `AppDatabase` and stub `db.behavioralStateDao.getLatestState()`. If the test file already mocks `AppDatabase` for other tests, reuse the existing mock setup.

  **Example pattern for BLOC-001:**
  ```dart
  test('[20.5-BLOC-001] AtRisk host generates low-intensity plan', () async {
    when(mockDb.behavioralStateDao.getLatestState()).thenAnswer(
      (_) async => BehavioralStateData(
        id: 1,
        currentState: 'atRisk',
        recordedAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    // Arrange bloc in lobby state with 2 participants, isHost: true
    // Act: add(const SessionStartTapped())
    // Assert: verify(mockGateway.sendBroadcast(...)) called with payload
    //         where payload['intensity'] <= 3 && payload['arm_key'].endsWith('_low')
  });
  ```

- [x] **8.2** Add to `pulse_coach/test/widget/shared_session/shared_session_lobby_page_test.dart` (or `shared_in_session_view_test.dart` if more appropriate):

  ```
  [20.5-WIDGET-001] inSession state (sessionType: 'mobility', intensity: 3, durationMinutes: 20) → _SharedInSessionView receives non-empty steps (3 steps: warm-up, main, cool-down)
  [20.5-WIDGET-002] BlocListener sessionEnded(armKey: 'mobility_low') → RPE navigation called with armKey: 'mobility_low'
  ```

  For WIDGET-001: seed `MockSharedSessionBloc` with `SharedSessionState.inSession(stepIndex: 0, elapsedSeconds: 0, isHost: false, steps: const [], participants: [p1, p2], sessionType: 'mobility', intensity: 3, durationMinutes: 20)`. Mount `SharedSessionLobbyPage` with `BlocProvider.value`. Pump with IT locale. Assert that the `_SharedInSessionView` children include text matching at least one of `l10n.inSessionWarmupTitle` values.

  For WIDGET-002: use `go_router` navigation capture (same pattern as existing lobby tests). Seed `MockSharedSessionBloc` emitting `SharedSessionState.sessionEnded(armKey: 'mobility_low')`. Assert that `context.go` was called with `extra` containing `RpeSubmitArgs.armKey == 'mobility_low'`.

- [x] **8.3** E18R-1 — Add to the test file:

  ```
  [20.5-WIDGET-003] 360×640 viewport, inSession (plan params), follower path → _SharedInSessionView renders without overflow
  ```

  Use the same `tester.view.physicalSize` / `tester.view.devicePixelRatio` / `tearDown(resetPhysicalSize)` pattern established in Story 20.4 tests.

- [x] **8.4** Add suppression guard test to `pulse_coach/test/widget/today/today_page_test.dart` (or create if absent):

  ```
  [20.5-TODAY-001] _suppressSharedSessionCta(BehavioralState.atRisk) == true
  [20.5-TODAY-002] _suppressSharedSessionCta(BehavioralState.recovering) == true
  [20.5-TODAY-003] _suppressSharedSessionCta(BehavioralState.active) == false
  [20.5-TODAY-004] _suppressSharedSessionCta(BehavioralState.fatigued) == false
  ```

  These are pure function tests — no widget pump needed. If `_suppressSharedSessionCta` is file-private (starts with `_`), test it via the widget behavior: mount `TodayPage` with `DailyPlanLoaded(behavioralState: BehavioralState.atRisk, ...)` and assert that `find.bySemanticsLabel(matches: RegExp(r'shared.*session', caseSensitive: false))` finds nothing.

  **Prefer testing via the public function if accessible:** If `today_page.dart` is in the same `pulse_coach` package (it is), use `import 'package:pulse_coach/features/today/presentation/pages/today_page.dart'` and call `_suppressSharedSessionCta(...)` directly. The `_` prefix is file-private in Dart, NOT class-private — so it IS accessible from the test file in the same package as long as it is imported.

  Wait — actually Dart `_` prefix means library-private, not file-private. A test file importing `today_page.dart` CANNOT directly call `_suppressSharedSessionCta` (it's library-private to the `today_page.dart` file). Use the widget pump approach instead:
  
  ```dart
  // Mount DailyPlanLoaded with AtRisk state and verify no 'shared session' button appears
  ```

  OR: Make `_suppressSharedSessionCta` accessible by defining it as a top-level function WITHOUT the `_` prefix and marking it `@visibleForTesting`. Recommended approach:

  ```dart
  @visibleForTesting
  bool suppressSharedSessionCta(BehavioralState state) =>
      state == BehavioralState.atRisk || state == BehavioralState.recovering;
  ```

  Then test directly:
  ```dart
  import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';
  
  test('[20.5-TODAY-001]', () {
    expect(suppressSharedSessionCta(BehavioralState.atRisk), isTrue);
  });
  ```

  The comment documenting UX-DR31 is kept on the function regardless of the underscore choice.

---

### Task 9 — `flutter analyze` and `flutter test` (AC8)

- [x] **9.1** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  ```
  Expected: 0 issues. If `@visibleForTesting` import is missing, add `import 'package:flutter/foundation.dart';` to `today_page.dart`.

- [x] **9.2** From `pulse_coach/`, run:
  ```bash
  flutter test
  ```
  Expected: all 1210 existing tests pass plus all new tests pass (target ≥ +8: 4 bloc + 3 widget + 1 today = 8 minimum; AC4 may add a GroupConstraintResolver test if AtRisk variant is missing from 20.2 suite). Zero regressions.

---

## Dev Notes

### Why Steps Are Always Empty (Pre-Story 20.5 State)

`social_page.dart` passes `steps: const []` in `SharedSessionStartArgs` at lines 143 and 180. The bloc stores this in `SharedSessionState.lobby.steps`, which flows into `SharedSessionState.inSession.steps` when `session_started` fires. `_SharedInSessionViewState._initHostCubit` silently no-ops the host path (`if (widget.steps.isEmpty) return;`). This is the root cause of the broken shared in-session experience that Story 20.5 fixes.

### Why Steps Are Generated at the Page Level, Not the Bloc Level

`SessionStepGenerator.generate(PlannedSession, AppLocalizations)` requires `AppLocalizations` — a Flutter dependency. Blocs must NOT import Flutter (they live in `presentation/bloc/`, not in `domain/`, but the key constraint is testability: bloc tests don't pump widgets and don't have l10n). Generating steps in the `BlocBuilder` (which has access to `context` and therefore `AppLocalizations`) is the correct separation.

### MVP Limitation: Only Host's Profile in GroupConstraintResolver

`GroupConstraintResolver.resolve([hostProfile])` is called with a single-participant list. This means the group plan is derived from the host's behavioral state and defaults (`fitnessLevel: 'medium', movementExclusions: const {}, availableTimeMinutes: 20`). Followers' fitness levels, exclusions, and AtRisk states are NOT reflected in the group plan.

**Why this is acceptable for v2.4b:**
- The primary AC4 concern ("AtRisk safety cap lowers intensity for the entire group") is satisfied for the HOST's AtRisk state
- Followers' safety is enforced PER-DEVICE: their `RpeFeedbackCubit` adapts their individual bandit arm independently (AC1)
- Cross-participant profile sharing would require either a new broadcast event type or Supabase profile reads, both of which are out of scope for this story

**Future improvement path:** Add a `participant_constraint` broadcast event that each device sends on join, carrying their own `safetyCapIntensity`; the host collects these and uses the full participant list in `GroupConstraintResolver`.

### RPE Write: `sessionId: 0` Remains

`RpeFeedbackCubit._persist` writes RPE with `sessionId: 0` when `planId == null`. Story 20.5 does NOT write a `session_logs` row for shared sessions. The constraint is deliberate per Story 20.4 design:
> "Story 20.5 introduces proper arm key derivation for shared sessions."

With Story 20.5's arm key fix, `PostRpeAdaptationCubit.triggerUpdate(rpeValue)` WILL call `UpdateBanditReward.call(armKey: 'mobility_low', ...)` (for example), and `RewardCalculator` will update the bandit because `'mobility_low'` IS in `banditArmKeys`. The bandit adaptation works correctly even without a `session_logs` row.

### `_armKey` Initialization Order (Host vs Follower)

- **Host path:** `_armKey` is set in `_onStartTapped` BEFORE `sendBroadcast` is called. When the host's own echo arrives as `SessionStarted(armKey: ...)`, the `_armKey ??= broadcastArmKey` guard is a no-op (already set).
- **Follower path:** `_armKey` is `null` until `BroadcastEvent.sessionStarted` arrives. The `_armKey ??= broadcastArmKey` in `_onBroadcastReceived` sets it from the broadcast payload.
- **Both paths:** `_armKey` is available when `SessionEnded()` arrives, so `SharedSessionState.sessionEnded(armKey: _armKey ?? 'mobility_medium')` always has the correct value.

### BroadcastEvent.sessionStarted Default Values Backward Compatibility

Story 20.4 bloc tests mock `BroadcastEvent.sessionStarted()` with no args. After Task 1's change, this compiles correctly because all new fields have `@Default` values. The tests will continue to test the existing behavior (no plan params → defaults apply).

The `RealtimeGateway.parseBroadcast` test for `session_started` also currently expects `const BroadcastEvent.sessionStarted()`. Update it to expect `BroadcastEvent.sessionStarted(sessionType: 'mobility', intensity: 5, ...)` with the defaults, or just verify the type with `isA<SessionStarted>()`.

### Freezed Pattern Matching on `sessionEnded(s)` in `mapOrNull`

After adding `armKey` to `sessionEnded`, the generated `mapOrNull` signature changes. The current `sessionEnded: (_)` in `SharedSessionLobbyPage`'s `listenWhen` and `listener` must become `sessionEnded: (s)` so `s.armKey` is accessible. The `listenWhen` callback doesn't need the value (it just checks if `sessionEnded` was emitted), so it stays as `sessionEnded: (_)`. Only the `listener` callback needs `(s)`.

### ExerciseStep Fields Used by `_SharedInSessionView`

`_SharedInSessionView` passes `steps` to its follower render path which renders `step.title`, `step.instruction`, `step.durationSeconds`. These are all generated correctly by `SessionStepGenerator.generate`. The host path passes these same steps to `InSessionCubit` which uses `step.durationSeconds` for countdown. Story 20.4's existing test `[20.4-WIDGET-001]` expected `'2 partecipanti'` from the IT locale; that test remains valid since it seeds a mock bloc already in `inSession` state with explicit steps.

### `PlannedSession` Freezed Constructor

`PlannedSession` is defined in `planned_session.dart`. Verify the exact constructor signature (it may be `PlannedSession(sessionType: ..., intensity: ..., durationMinutes: ...)` with the default `const factory` form or have a named factory like `PlannedSession.create`). If using a named freezed factory, adjust Task 6.2 accordingly.

### File Size Check

`shared_session_lobby_page.dart` was ~600 lines after Story 20.4. Task 6 adds ~15 lines to the `BlocBuilder` and modifies ~5 lines in the listener. Net result: ~620 lines, well under the 800-line hard limit.

`today_page.dart` was ~546 lines. Task 7 adds ~8 lines (function + imports). Net: ~554 lines.

### Project Structure Notes

**Modified files:**
- `lib/features/social/shared_session/domain/entities/broadcast_event.dart`
- `lib/core/cloud/realtime_gateway.dart`
- `lib/features/social/shared_session/presentation/bloc/shared_session_state.dart`
- `lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`
- `lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart`
- `lib/features/today/presentation/pages/today_page.dart`

**Auto-regenerated files (do not edit manually):**
- `lib/features/social/shared_session/domain/entities/broadcast_event.freezed.dart`
- `lib/features/social/shared_session/presentation/bloc/shared_session_state.freezed.dart`
- `lib/core/di/injection.config.dart`

**Modified test files:**
- `test/bloc/shared_session/shared_session_bloc_test.dart`
- `test/widget/shared_session/shared_session_lobby_page_test.dart` (or `shared_in_session_view_test.dart`)
- `test/widget/today/today_page_test.dart` (new group, or new file if it doesn't exist)

### References

- [Source: epics.md#Story 20.5 lines ~2712–2738]
- [Source: epics.md#FR72, UX-DR31, FR70, NFR31]
- [Source: lib/ai/safety/group_constraint_resolver.dart — GroupConstraintResolver.resolve()]
- [Source: lib/ai/safety/participant_profile.dart — ParticipantProfile inputs]
- [Source: lib/ai/bandit/bandit_state.dart:27 — banditArmKeys (9 arms, 'shared_session' NOT included)]
- [Source: lib/ai/bandit/reward_calculator.dart:47 — 'shared_session' is a no-op in bandit update]
- [Source: lib/features/session/presentation/bloc/post_rpe_adaptation_cubit.dart — skips bandit if armKey is null/empty; runs for non-empty armKey regardless of planId]
- [Source: lib/features/session/presentation/bloc/rpe_feedback_cubit.dart — writes RPE with sessionId: 0 when planId == null]
- [Source: lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart — _onStartTapped, _onBroadcastReceived, _onSessionEndRequested]
- [Source: lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart — _SharedSessionLobbyPageState._lastSteps, BlocListener.sessionEnded, BlocBuilder.inSession]
- [Source: lib/core/cloud/realtime_gateway.dart:62-65 — session_started callback currently ignores payload]
- [Source: lib/features/session/presentation/utils/session_step_generator.dart — SessionStepGenerator.generate(PlannedSession, AppLocalizations)]
- [Source: lib/features/today/presentation/pages/today_page.dart — DailyPlanLoaded.behavioralState available in _buildLoaded]
- [Source: test/bloc/shared_session/shared_session_bloc_test.dart — 373 lines, existing 19.2-BLOC-xxx + 20.4-BLOC-xxx patterns]
- [Source: _bmad-output/implementation-artifacts/20-4-synchronized-session-start-and-shared-in-session-view.md — dev notes on steps: const [], armKey placeholder, _endDispatched pattern]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Fixed `BehavioralStateCompanion.insert` type error: `recordedAt`/`updatedAt` are plain `DateTime` columns (no `Value()` wrapper needed).
- `SharedSessionBloc` constructor arity mismatch after adding `AppDatabase` 5th arg: updated all 4 existing shared-session bloc test files to pass `AppDatabase.forTesting(NativeDatabase.memory())`.
- Fixed `steps: const []` inside `const SharedSessionState.inSession(...)` causing `unnecessary_const` analyzer infos across bloc test files — replaced all occurrences with `steps: []`.
- `_arrangeHostLobbyWith2Participants` (leading underscore on local function) caused `no_leading_underscores_for_local_identifiers` lint — renamed to `arrangeHostLobbyWith2Participants`.
- Unused import `package:flutter/foundation.dart` in `today_page.dart` after adding `@visibleForTesting` — removed (it was redundant; `foundation.dart` exports are already covered by `material.dart`).
- Widget tests `19.2-WIDGET-005`, `20.4-WIDGET-001`, `19.3-WIDGET-001` expected step titles from `_kSteps` (`'Warm Up'`); after Task 6 the page generates steps from plan params via `SessionStepGenerator` — updated tests to use generated titles (`'Warm-up'` EN, `'Riscaldamento'` IT).
- `PlannedSession` freezed constructor requires `isIndoor: bool` — added `isIndoor: true` in `shared_session_lobby_page.dart`.

### Completion Notes List

- All 9 tasks completed in ATDD order (red-green-refactor for each).
- Final test count: 1222 tests passed (started at 1210; added 12 new: 4 today suppression + 4 bloc 20.5 + 3 lobby widget + 1 updated existing).
- `flutter analyze lib/ test/` → 0 issues.
- `GroupConstraint` import was unused after implementation settled — removed.
- `isIndoor: true` hardcoded for shared sessions (group sessions are treated as indoor for step generation purposes; out-of-scope to expose this param).
- Story closes Epic 20.

### File List

**Modified production files:**
- `lib/features/social/shared_session/domain/entities/broadcast_event.dart`
- `lib/features/social/shared_session/domain/entities/broadcast_event.freezed.dart` (auto-generated)
- `lib/core/cloud/realtime_gateway.dart`
- `lib/features/social/shared_session/presentation/bloc/shared_session_state.dart`
- `lib/features/social/shared_session/presentation/bloc/shared_session_state.freezed.dart` (auto-generated)
- `lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`
- `lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart`
- `lib/features/today/presentation/pages/today_page.dart`
- `lib/core/di/injection.config.dart` (auto-generated)

**New test files:**
- `test/bloc/shared_session/shared_session_20_5_bloc_test.dart`
- `test/widget/today/today_page_suppression_test.dart`

**Modified test files:**
- `test/bloc/shared_session/shared_session_bloc_test.dart`
- `test/bloc/shared_session/shared_session_cancel_refresh_bloc_test.dart`
- `test/bloc/shared_session/shared_session_bloc_co_location_test.dart`
- `test/bloc/shared_session/drop_out_tolerance_bloc_test.dart`
- `test/widget/shared_session/shared_session_lobby_page_test.dart`
- `test/widget/shared_session/shared_in_session_view_test.dart`
- `test/widget/shared_session/drop_out_tolerance_widget_test.dart`

## Review Findings

### Review Findings (code-review 2026-06-27)

Adversarial review — 3 layers (Blind Hunter, Edge Case Hunter, Acceptance Auditor) on Opus 4.8. `flutter test` → 1222 passed. `flutter analyze lib/ test/` → 1 issue (see P2).

**Decision needed (resolved → fail-safe to LOW, patched):**

- [x] [Review][Decision] DB-read-failure / unknown-state fallback downgraded an AtRisk host's safety cap. **Resolved:** chose fail-safe to LOW. `_onStartTapped` `catch` now sets `intensity = 3`; `_parseBehavioralState` now returns `null` for an unrecognized non-null state string and the caller caps to `SessionIntensity.low` (a `null` input = no state yet stays `active`, the legitimate first-run default). [shared_session_bloc.dart `_onStartTapped`/`_parseBehavioralState`]

**Patches (all applied):**

- [x] [Review][Patch] `RealtimeGateway.parseBroadcast` `session_started` crashed on wrong-type payload fields. **Fixed:** replaced `as` casts with `is num`/`is String` guards (mirrors `step_advanced`); a wrong-type field now falls back to its default instead of throwing in the uncaught stream callback. `arm_key` default now derives from the parsed `intensity`. [pulse_coach/lib/core/cloud/realtime_gateway.dart]
- [x] [Review][Patch] Unused `_kSteps` const broke AC8. **Fixed:** removed `_kSteps` + the now-unused `exercise_step.dart` import; `flutter analyze lib/ test/` → 0 issues. [pulse_coach/test/widget/shared_session/drop_out_tolerance_widget_test.dart]
- [x] [Review][Patch] `_intensityFromCeiling(high)` collapsed to a `*_medium` arm key. **Fixed:** `high => 8` so `_intensityName(8) == 'high'`, consistent with the documented 8–10 range. [pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart]
- [x] [Review][Patch] `[20.5-WIDGET-002]` was vacuous. **Fixed:** rewritten with a real `GoRouter` harness + controllable bloc stream; drives an `inSession → sessionEnded` transition and asserts the captured `RpeSubmitArgs.armKey == 'mobility_low'`. [pulse_coach/test/widget/shared_session/shared_session_lobby_page_test.dart]

**Deferred:**

- [x] [Review][Defer] Reconnect/late-join via `StepAdvanced` snap renders a default `mobility/medium/20` session (plan params are not carried in that event) and leaves `_lastSteps` stale → wrong RPE duration. — deferred, reconnect flow out of scope since Story 20.4. [shared_session_bloc.dart `_onBroadcastReceived` + shared_session_lobby_page.dart]
- [x] [Review][Defer] `inSession.steps` field is now vestigial — the page always regenerates steps and never reads `s.steps`. — deferred, removal touches `_SharedInSessionView` ctor (out of scope per Task 3.1 note). [shared_session_state.dart]
- [x] [Review][Defer] `_armKey` is never reset on `SessionEnded`; correctness relies on a fresh factory bloc instance per session. — deferred, bloc is `@injectable` factory-scoped per route. [shared_session_bloc.dart]
- [x] [Review][Defer] Only the host's profile (with hardcoded `fitnessLevel`/`movementExclusions`/`availableTimeMinutes`) feeds `GroupConstraintResolver`. — deferred, documented MVP limitation (dev notes). [shared_session_bloc.dart `_onStartTapped`]

**Dismissed as noise (7):** `suppressSharedSessionCta` "dead code" (forward guard by design, AC3); per-rebuild step regeneration (explicitly out of scope per Task 6.2); `AppLocalizations.of(context)!` (documented safe — always inside MaterialApp); `_armKey` set before broadcast (spec-required echo-race ordering); unknown-state fail-open as a standalone item (near-impossible via `enum.name` round-trip; folded into the Decision item); AC2 widget-assertion substituted with a pure-function test (per spec Task 8.4's own final recommendation, since no CTA exists yet); `today_page_suppression_test` categorized under `test/widget/` (harmless).
