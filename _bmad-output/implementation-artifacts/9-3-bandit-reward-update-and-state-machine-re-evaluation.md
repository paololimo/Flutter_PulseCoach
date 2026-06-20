# Story 9.3: Bandit Reward Update & State Machine Re-evaluation

Status: done

## Story

As the system,
I want to update the bandit's arm weights and re-evaluate behavioral state after each RPE submission,
So that the next plan generation benefits from the new feedback immediately.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | RPE is submitted and `RpeFeedbackSubmitted` fires | When the `UpdateBanditReward` use case runs | The arm weight for the completed session's (type × intensity) pair is updated via EMA: reward is higher when RPE is near 6.5, lower when RPE deviates significantly (FR22) |
| AC2 | The reward is calculated | When `BanditState` is updated in the database | The update is persisted to `bandit_state` table with a new `updatedAt` timestamp (FR25) |
| AC3 | The RPE history now has a new entry | When the `BehavioralStateMachine` re-evaluates | If the transition conditions are met, the `behavioral_state` table is updated with a new row (FR23) |
| AC4 | The bandit reward update runs | When measured | It executes via `compute()` background Dart Isolate — the UI thread is not blocked (ARCH7, NFR2) |
| AC5 | `PostRpeAdaptationCubit` lifecycle — **E8-P1 Cubit-lifecycle invariants** | When spec is executed | (a) `triggerUpdate()` is idempotent — only the first call executes the use case; subsequent calls are no-ops; (b) no state emitted after `close()`; (c) use-case failures emit an explicit `PostRpeAdaptationError(Failure)` state — NOT `debugPrint`-only; (d) at least one test covers each invariant |
| AC6 | **E7.5-T1 stretch** — `BehavioralStateMachine.evaluate()` is being touched | When spec is drafted | The 7 dead ARB `transition*` keys are folded in: `BehavioralTransition.transitionMessage: String?` → `transitionKey: BehavioralTransitionKey?` (new enum); `BehavioralStateMachine.evaluate()` emits keys; `StateIndicator` resolves keys via `AppLocalizations`. Stretch-allowable only if non-scope-expanding; otherwise defer to Story 9.4 firm |

## Tasks / Subtasks

---

### Task 1: Create `BanditRewardInput` / `BanditRewardOutput` payload classes and top-level `_computeRewardUpdate` isolate function

These classes are the isolate-sendable payload for `compute()`, analogous to `AiEngineInput`/`AiEngineOutput` in `ai_engine.dart`.

- [x] CREATE `lib/features/session/domain/usecases/update_bandit_reward.dart`

  Add at the **top of the file** (before the use-case class), these plain Dart classes and the top-level function (required by `compute()` — must be top-level, not a static method):

  ```dart
  import 'dart:convert';
  import 'dart:developer' as developer;

  import 'package:dartz/dartz.dart';
  import 'package:drift/drift.dart' as drift;
  import 'package:flutter/foundation.dart' show compute;
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/ai/bandit/bandit_state.dart' as ai_bandit;
  import 'package:pulse_coach/ai/bandit/contextual_bandit.dart';
  import 'package:pulse_coach/ai/bandit/state_vector.dart';
  import 'package:pulse_coach/ai/missed_sessions/missed_sessions_calculator.dart';
  import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
  import 'package:pulse_coach/ai/state_machine/behavioral_state_machine.dart';
  import 'package:pulse_coach/core/database/app_database.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';

  // ─── Isolate payload (top-level — required by compute()) ─────────────────────

  class BanditRewardInput {
    final ai_bandit.BanditState currentBanditState;
    final String armKey;
    final int rpeValue;
    final List<int> updatedRpeHistory; // already includes the new rpeValue
    final int missedSessions;
    final int streak;
    final BehavioralState currentBehavioralState;

    const BanditRewardInput({
      required this.currentBanditState,
      required this.armKey,
      required this.rpeValue,
      required this.updatedRpeHistory,
      required this.missedSessions,
      required this.streak,
      required this.currentBehavioralState,
    });
  }

  class BanditRewardOutput {
    final ai_bandit.BanditState newBanditState;
    final BehavioralState newBehavioralState;
    final bool stateChanged;

    const BanditRewardOutput({
      required this.newBanditState,
      required this.newBehavioralState,
      required this.stateChanged,
    });
  }

  // Dummy profile: BehavioralStateMachine.evaluate() only reads
  // currentState / rpeHistory / missedSessions / streak from StateVector.
  const _kDummyProfile = UserProfile(
    fitnessLevel: 'medium',
    goal: 'wellbeing',
    availableTime: 'short',
    physicalConstraints: 'none',
  );

  /// Top-level function — required by compute(). Runs in a separate Dart isolate.
  ///
  /// 1. Updates bandit arm weight via EMA (RewardCalculator inside BanditEngine).
  /// 2. Re-evaluates BehavioralStateMachine with updated RPE history.
  BanditRewardOutput _computeRewardUpdate(BanditRewardInput input) {
    final newBanditState = const BanditEngine().updateReward(
      input.currentBanditState,
      input.armKey,
      input.rpeValue,
    );

    final updatedSv = StateVector(
      restingHR: null,
      stepCount: null,
      activityLevel: null,
      rpeHistory: input.updatedRpeHistory,
      missedSessions: input.missedSessions,
      streak: input.streak,
      aqiLevel: AqiLevel.low,
      temperature: null,
      precipitation: null,
      userProfile: _kDummyProfile,
      currentState: input.currentBehavioralState,
    );

    const machine = BehavioralStateMachine();
    final transition = machine.evaluate(updatedSv);

    return BanditRewardOutput(
      newBanditState: newBanditState,
      newBehavioralState: transition.newState,
      stateChanged: transition.stateChanged,
    );
  }
  ```

---

### Task 2: Create `UpdateBanditReward` use case class (AC1–AC4)

- [x] (continued in the same file `update_bandit_reward.dart`) Add the injectable use case:

  ```dart
  @injectable
  class UpdateBanditReward {
    final AppDatabase _db;

    UpdateBanditReward(this._db);

    Future<Either<Failure, Unit>> call({
      required String armKey,
      required int rpeValue,
      required int? planId,
    }) async {
      try {
        // 1. Load current BanditState
        final banditRow = await _db.banditStateDao.getLatestState();
        final currentBanditState = banditRow != null
            ? _parseBanditState(banditRow)
            : ai_bandit.initialBanditState();

        // 2. Load updated RPE history from DB.
        // RpeFeedbackCubit already persisted the new RPE before emitting
        // RpeFeedbackSubmitted, so getLastN(10) includes the new value.
        final rpeRows = await _db.rpeFeedbackDao.getLastN(10);
        final updatedRpeHistory = rpeRows
            .map((r) => r.rpeValue)
            .where((v) => v >= 1 && v <= 10)
            .toList()
            .reversed
            .toList(); // most-recent-first → chronological

        // 3. Load current behavioral state
        final stateRow = await _db.behavioralStateDao.getLatestState();
        final currentBehavioralState = _parseState(stateRow?.currentState);

        // 4. Compute streak and missedSessions (same logic as GenerateDailyPlan)
        final sessions = await _db.sessionsDao.getAllSessions();
        final streak = _calculateStreak(sessions);
        final windowStart = _dateStr(DateTime.now().subtract(const Duration(days: 7)));
        final windowEnd = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
        final plansInWindow = await _db.dailyPlansDao.getPlansInDateRange(
          windowStart,
          windowEnd,
        );
        final missedSessions = const MissedSessionsCalculator().calculate(
          plansInWindow.map((p) => p.isCompleted).toList(),
        );

        // 5. Run in background isolate (ARCH7, NFR2)
        final input = BanditRewardInput(
          currentBanditState: currentBanditState,
          armKey: armKey,
          rpeValue: rpeValue,
          updatedRpeHistory: updatedRpeHistory,
          missedSessions: missedSessions,
          streak: streak,
          currentBehavioralState: currentBehavioralState,
        );
        final output = await compute(_computeRewardUpdate, input);

        // 6. Persist updated BanditState (AC2)
        final now = DateTime.now().toUtc();
        final weightsJson = jsonEncode(output.newBanditState.armWeights);
        if (banditRow != null) {
          await _db.banditStateDao.updateState(
            BanditStateData(
              id: banditRow.id,
              armWeightsJson: weightsJson,
              updatedAt: now,
            ),
          );
        } else {
          await _db.banditStateDao.insertState(
            BanditStateCompanion(
              armWeightsJson: drift.Value(weightsJson),
              updatedAt: drift.Value(now),
            ),
          );
        }

        // 7. Persist new BehavioralState if state changed OR no row exists (AC3)
        if (output.stateChanged || stateRow == null) {
          await _db.behavioralStateDao.insertState(
            BehavioralStateCompanion(
              currentState: drift.Value(output.newBehavioralState.name),
              recordedAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );
        }

        return const Right(unit);
      } catch (e, st) {
        developer.log(
          'UpdateBanditReward failed',
          name: 'UpdateBanditReward',
          error: e,
          stackTrace: st,
        );
        return Left(ServerFailure('bandit_reward_update_failed'));
      }
    }

    // ─── Private helpers (duplicated from GenerateDailyPlan — see Dev Notes) ───

    ai_bandit.BanditState _parseBanditState(BanditStateData row) {
      try {
        final decoded = (jsonDecode(row.armWeightsJson) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        final weights = {
          for (final key in ai_bandit.banditArmKeys)
            key: _validWeight(decoded[key]),
        };
        return ai_bandit.BanditState(
          armWeights: weights,
          updatedAt: row.updatedAt,
        );
      } catch (e) {
        developer.log(
          'Corrupt BanditState JSON — cold start',
          name: 'UpdateBanditReward',
          error: e,
        );
        return ai_bandit.initialBanditState();
      }
    }

    double _validWeight(double? w) =>
        (w != null && w.isFinite && w >= 0) ? w : 1.0;

    BehavioralState _parseState(String? stateStr) {
      return switch (stateStr?.toLowerCase()) {
        'recovering' => BehavioralState.recovering,
        'atrisk' => BehavioralState.atRisk,
        'fatigued' => BehavioralState.fatigued,
        _ => BehavioralState.active,
      };
    }

    int _calculateStreak(List<Session> sessions) {
      final completed = sessions
          .where((s) => s.completedAt != null && s.abandoned == false)
          .map((s) => _dateStr(s.completedAt!.toLocal()))
          .toSet();
      var day = DateTime.now();
      if (!completed.contains(_dateStr(day))) {
        day = day.subtract(const Duration(days: 1));
      }
      var streak = 0;
      while (completed.contains(_dateStr(day))) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      }
      return streak;
    }

    String _dateStr(DateTime dt) =>
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
  ```

  **Dev Notes — helpers duplication**: `_parseBanditState`, `_calculateStreak`, etc. duplicate logic from `GenerateDailyPlan`. Do NOT extract a shared helper in this story — both classes are in different layers (`domain/usecases/` vs the same path) and the duplication is minimal. A shared utility could be introduced in a Foundation story if the pattern grows.

  **Dev Notes — `BehavioralStateData` write pattern**: `BehavioralStateDao` only has `insertState()` (append-log pattern, consistent with `GenerateDailyPlan`). Do NOT add an `updateState()` method to `BehavioralStateDao` — the latest-state query (`getLatestState()` with `orderBy desc + limit 1`) is the intended read pattern.

---

### Task 3: Create `PostRpeAdaptationState` and `PostRpeAdaptationCubit` (AC5)

- [x] CREATE `lib/features/session/presentation/bloc/post_rpe_adaptation_state.dart`

  ```dart
  import 'package:pulse_coach/core/error/failures.dart';

  sealed class PostRpeAdaptationState {
    const PostRpeAdaptationState();
  }

  class PostRpeAdaptationInitial extends PostRpeAdaptationState {
    const PostRpeAdaptationInitial();
  }

  class PostRpeAdaptationRunning extends PostRpeAdaptationState {
    const PostRpeAdaptationRunning();
  }

  class PostRpeAdaptationDone extends PostRpeAdaptationState {
    const PostRpeAdaptationDone();
  }

  class PostRpeAdaptationError extends PostRpeAdaptationState {
    final Failure failure;
    const PostRpeAdaptationError(this.failure);
  }
  ```

- [x] CREATE `lib/features/session/presentation/bloc/post_rpe_adaptation_cubit.dart`

  ```dart
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:pulse_coach/features/session/domain/usecases/update_bandit_reward.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/post_rpe_adaptation_state.dart';

  class PostRpeAdaptationCubit extends Cubit<PostRpeAdaptationState> {
    final UpdateBanditReward _useCase;
    final String? _armKey;
    final int? _planId;
    bool _triggered = false;

    PostRpeAdaptationCubit({
      required UpdateBanditReward useCase,
      required String? armKey,
      required int? planId,
    }) : _useCase = useCase,
         _armKey = armKey,
         _planId = planId,
         super(const PostRpeAdaptationInitial());

    /// Fire-and-forget: called from RpePage when RpeFeedbackSubmitted fires.
    /// Idempotent — only the first call executes the use case (AC5a).
    Future<void> triggerUpdate(int rpeValue) async {
      if (_triggered || isClosed) return;
      _triggered = true;

      final armKey = _armKey;
      if (armKey == null || armKey.isEmpty) {
        if (!isClosed) emit(const PostRpeAdaptationDone());
        return;
      }

      if (!isClosed) emit(const PostRpeAdaptationRunning());

      final result = await _useCase.call(
        armKey: armKey,
        rpeValue: rpeValue,
        planId: _planId,
      );

      if (isClosed) return; // AC5b: no emit after close
      result.fold(
        (failure) => emit(PostRpeAdaptationError(failure)), // AC5c: explicit error
        (_) => emit(const PostRpeAdaptationDone()),
      );
    }
    // No close() override needed — no timers or subscriptions to cancel.
  }
  ```

  **E8-P1 invariants honoured:**
  - `_triggered` guard → `triggerUpdate()` is idempotent (AC5a).
  - `isClosed` checked before every emit (AC5b).
  - Failures emit `PostRpeAdaptationError(Failure)` — never `debugPrint`-only (AC5c).
  - `PostRpeAdaptationCubit` is NOT `@injectable` — constructed inline in `RpePage.initState()`.

---

### Task 4: Register `UpdateBanditReward` with DI

- [x] The `@injectable` annotation on `UpdateBanditReward` (Task 2) is sufficient — it takes `AppDatabase` as a constructor parameter. Run codegen to register it.

  ```bash
  cd pulse_coach && dart run build_runner build --delete-conflicting-outputs
  ```

  Verify `injection.config.dart` includes `UpdateBanditReward`.

---

### Task 5: Wire `PostRpeAdaptationCubit` in `RpePage` (AC1, AC5)

- [x] READ `lib/features/session/presentation/pages/rpe_page.dart` fully before editing.

- [x] UPDATE `lib/features/session/presentation/pages/rpe_page.dart`
  - Add import for `PostRpeAdaptationCubit`, `PostRpeAdaptationState`, `UpdateBanditReward`, `getIt`.
  - Add `PostRpeAdaptationCubit? _adaptationCubit;` field (alongside `RpeFeedbackCubit? _cubit`).
  - In `initState()`, after constructing `_cubit`, add:
    ```dart
    final args = widget.args;
    if (args != null) {
      _adaptationCubit = PostRpeAdaptationCubit(
        useCase: getIt<UpdateBanditReward>(),
        armKey: args.armKey,
        planId: args.planId,
      );
    }
    ```
  - In `dispose()`, add `_adaptationCubit?.close();` **before** `super.dispose()`.
  - In the existing `BlocListener` for `RpeFeedbackSubmitted`, add the fire-and-forget call **before** the navigation:
    ```dart
    listener: (context, state) {
      if (!context.mounted) return;
      if (state is RpeFeedbackSubmitted) {
        _adaptationCubit?.triggerUpdate(state.rpeValue); // fire-and-forget (AC4)
        // existing MiniSummaryArgs construction + context.go(AppRouter.sessionSummary)
        // ... (unchanged from Story 9.2)
      }
    },
    ```
  - The `RpeFeedbackError` listener path is unchanged.
  - `getIt` is ONLY called in `initState()` — never in `build()` (project rule).

---

### Task 6: Unit tests — `UpdateBanditReward` use case (AC1–AC4)

- [x] CREATE `test/domain/usecases/update_bandit_reward_test.dart`

  Use an in-memory `NativeDatabase.memory()` Drift database (project convention — never mock Drift):

  ```dart
  // Fake AppDatabase backed by in-memory DB:
  late AppDatabase db;
  late UpdateBanditReward useCase;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    useCase = UpdateBanditReward(db);
  });

  tearDown(() async => db.close());
  ```

  **9.3-UC-001: unrecognised armKey → bandit weights unchanged, returns Right(unit)**
  - Insert a `BanditStateData` row with all weights = 1.0.
  - Call `useCase(armKey: 'unknown_arm', rpeValue: 7, planId: null)`.
  - Assert `Right(unit)` returned.
  - Assert latest bandit state in DB still has all weights = 1.0.
  - Rationale: `BanditEngine.updateReward` is a no-op for unrecognised arms.

  **9.3-UC-002: RPE near target (rpe=7) → target arm weight increases**
  - Insert initial `BanditState` with `mobility_low = 0.5`.
  - Call `useCase(armKey: 'mobility_low', rpeValue: 7, planId: null)`.
  - Load updated row.
  - Assert `mobility_low > 0.5` (reward > 0, EMA pushes weight up).
  - Assert all other arms unchanged.

  **9.3-UC-003: RPE far from target (rpe=1) → target arm weight decreases**
  - Insert initial `BanditState` with `cardio_high = 0.8`.
  - Call `useCase(armKey: 'cardio_high', rpeValue: 1, planId: null)`.
  - Assert `cardio_high < 0.8`.

  **9.3-UC-004: no BanditState in DB → cold-start inserts new row**
  - DB starts empty (no bandit_state rows).
  - Call use case with valid armKey and rpeValue.
  - Assert `Right(unit)`.
  - Assert `db.banditStateDao.getLatestState()` returns non-null.

  **9.3-UC-005: BanditState exists → updates existing row (not inserts new)**
  - Insert one `BanditStateData` row.
  - Call use case twice (with different armKey each time).
  - Assert still only one `bandit_state` row in DB (update, not insert).
  - Tip: query `db.select(db.banditState).get()` and check `length == 1`.

  **9.3-UC-006: state machine transition fires → new behavioral_state row inserted**
  - Seed DB: insert 2 RPE feedback rows with rpeValue = 9 (triggers active → fatigued when lastNAvg(2) > 8.0).
  - Insert latest behavioral state row with `currentState = 'active'`.
  - Call `useCase(armKey: 'cardio_high', rpeValue: 9, planId: null)`.
  - Assert `Right(unit)`.
  - Assert a new `behavioral_state` row exists with `currentState = 'fatigued'`.

  **9.3-UC-007: no state machine transition → no new behavioral_state row**
  - Seed DB with behavioral state `'active'`, RPE history all around 6 (no transition condition met).
  - Count behavioral_state rows before: N.
  - Call use case.
  - Count after: still N (no new row inserted).

  **9.3-UC-008: DB error (simulate) → returns Left(Failure)**
  - Use a closed DB: call `db.close()` before calling use case.
  - Assert result is `Left<Failure, Unit>`.
  - Note: a closed Drift DB throws `StateError` or `DatabaseException` on access.

---

### Task 7: Unit tests — `PostRpeAdaptationCubit` (AC5)

- [x] CREATE `test/bloc/post_rpe_adaptation_cubit_test.dart`

  Use `mockito` with `@GenerateMocks([UpdateBanditReward])`. Run codegen after adding annotation.

  ```dart
  @GenerateMocks([UpdateBanditReward])
  void main() { ... }
  ```

  **9.3-CUBIT-001: idempotency — triggerUpdate called twice → use case called exactly once (AC5a)**
  ```dart
  blocTest<PostRpeAdaptationCubit, PostRpeAdaptationState>(
    'triggerUpdate is idempotent',
    build: () {
      when(mockUseCase.call(armKey: anyNamed('armKey'), rpeValue: anyNamed('rpeValue'), planId: anyNamed('planId')))
          .thenAnswer((_) async => const Right(unit));
      return PostRpeAdaptationCubit(useCase: mockUseCase, armKey: 'mobility_low', planId: 1);
    },
    act: (c) async {
      await c.triggerUpdate(7);
      await c.triggerUpdate(7); // second call — must be no-op
    },
    verify: (_) => verify(mockUseCase.call(armKey: anyNamed('armKey'), rpeValue: anyNamed('rpeValue'), planId: anyNamed('planId'))).called(1),
  );
  ```

  **9.3-CUBIT-002: success path → emits Running then Done**
  ```dart
  blocTest(
    'success emits Running then Done',
    build: () {
      when(...).thenAnswer((_) async => const Right(unit));
      return PostRpeAdaptationCubit(useCase: mockUseCase, armKey: 'cardio_medium', planId: null);
    },
    act: (c) => c.triggerUpdate(6),
    expect: () => [isA<PostRpeAdaptationRunning>(), isA<PostRpeAdaptationDone>()],
  );
  ```

  **9.3-CUBIT-003: use case returns Left → emits Running then Error (AC5c)**
  ```dart
  blocTest(
    'failure emits Running then Error',
    build: () {
      when(...).thenAnswer((_) async => Left(ServerFailure('bandit_reward_update_failed')));
      return PostRpeAdaptationCubit(useCase: mockUseCase, armKey: 'breathing_low', planId: null);
    },
    act: (c) => c.triggerUpdate(5),
    expect: () => [isA<PostRpeAdaptationRunning>(), isA<PostRpeAdaptationError>()],
  );
  ```

  **9.3-CUBIT-004: null armKey → no use case call, emits Done immediately**
  ```dart
  blocTest(
    'null armKey skips use case',
    build: () => PostRpeAdaptationCubit(useCase: mockUseCase, armKey: null, planId: null),
    act: (c) => c.triggerUpdate(7),
    expect: () => [isA<PostRpeAdaptationDone>()],
    verify: (_) => verifyNever(mockUseCase.call(armKey: anyNamed('armKey'), rpeValue: anyNamed('rpeValue'), planId: anyNamed('planId'))),
  );
  ```

  **9.3-CUBIT-005: close() before use case completes → no state emitted after close (AC5b)**
  ```dart
  test('no state emitted after close', () async {
    final completer = Completer<Either<Failure, Unit>>();
    when(...).thenAnswer((_) => completer.future);

    final cubit = PostRpeAdaptationCubit(useCase: mockUseCase, armKey: 'mobility_low', planId: null);
    final states = <PostRpeAdaptationState>[];
    cubit.stream.listen(states.add);

    unawaited(cubit.triggerUpdate(7)); // starts, waiting on completer
    await cubit.close();
    completer.complete(const Right(unit)); // resolves after close
    await Future.delayed(Duration.zero);

    expect(states.where((s) => s is PostRpeAdaptationDone), isEmpty);
  });
  ```

---

### Task 8: E7.5-T1 Stretch — Wire `BehavioralTransitionKey` through the stack

> **Decision gate**: Implement Task 8 IF it does not require more than 1 day of additional work.
> If deferred, add a note in Dev Agent Record explaining deferral, and PM creates Story 9.4.
> If absorbed, mark E7.5-T1 as `done` in `action-item-ledger.md`.

- [x] CREATE `lib/ai/state_machine/behavioral_transition_key.dart`

  ```dart
  /// Enum identifying which BehavioralStateMachine transition fired.
  ///
  /// 7 values — one per ARB key in app_it.arb / app_en.arb.
  /// StateIndicator resolves these to localized strings via AppLocalizations.
  enum BehavioralTransitionKey {
    activeToAtRisk,      // transitionActiveAtRisk
    fatiguedToAtRisk,    // transitionFatiguedAtRisk
    activeToFatigued,    // transitionActiveFatigued
    atRiskToRecovering,  // transitionAtRiskRecovering
    fatiguedToRecovering, // transitionFatiguedRecovering
    recoveringToActive,  // transitionRecoveringActive
    recoveringToFatigued, // transitionRecoveringFatigued
  }
  ```

- [x] UPDATE `lib/ai/state_machine/behavioral_transition.dart`

  Replace `transitionMessage: String?` with `transitionKey: BehavioralTransitionKey?`:

  ```dart
  import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
  import 'package:pulse_coach/ai/state_machine/behavioral_transition_key.dart';

  class BehavioralTransition {
    final BehavioralState newState;
    final BehavioralTransitionKey? transitionKey;

    const BehavioralTransition({
      required this.newState,
      this.transitionKey,
    });

    bool get stateChanged => transitionKey != null;
  }
  ```

  **Breaking change warning**: Any existing test or code that references `transitionMessage` will fail to compile. Fix all call sites as part of this task.

- [x] UPDATE `lib/ai/state_machine/behavioral_state_machine.dart`

  Replace all 6 `transitionMessage: '...'` hardcoded strings with `transitionKey:` enum values:

  | Rule | Old message | New transitionKey |
  |---|---|---|
  | 1: active → atRisk | `'Ci sei mancato...'` | `BehavioralTransitionKey.activeToAtRisk` |
  | 2: fatigued → atRisk | `'Il corpo chiede...'` | `BehavioralTransitionKey.fatiguedToAtRisk` |
  | 3: active → fatigued | `'Hai spinto forte...'` | `BehavioralTransitionKey.activeToFatigued` |
  | 4 (atRisk): atRisk/fatigued → recovering | `'Stai tornando...'` | `BehavioralTransitionKey.atRiskToRecovering` |
  | 4 (fatigued): atRisk/fatigued → recovering | same text | `BehavioralTransitionKey.fatiguedToRecovering` |
  | 5: recovering → active | `'Sei di nuovo...'` | `BehavioralTransitionKey.recoveringToActive` |
  | 6: recovering → fatigued | `'Stiamo rientrando...'` | `BehavioralTransitionKey.recoveringToFatigued` |

  **Implementation**: Change every `return const BehavioralTransition(newState: X, transitionMessage: '...')` to `return const BehavioralTransition(newState: X, transitionKey: BehavioralTransitionKey.Y)`.
  The no-transition return at line 101: `return BehavioralTransition(newState: current)` — no change needed (transitionKey defaults to null).

- [x] UPDATE `lib/ai/engine/ai_engine.dart`

  Add `transitionKey` to `AiEngineOutput`:

  ```dart
  import 'package:pulse_coach/ai/state_machine/behavioral_transition_key.dart';

  class AiEngineOutput {
    final DailyPlan plan;
    final BehavioralState newBehavioralState;
    final BehavioralTransitionKey? transitionKey; // new

    const AiEngineOutput({
      required this.plan,
      required this.newBehavioralState,
      this.transitionKey,
    });
  }
  ```

- [x] UPDATE `lib/ai/engine/ai_engine_isolate.dart`

  Propagate `transition.transitionKey` into `AiEngineOutput`:

  ```dart
  // Step 1: state machine
  final transition = machine.evaluate(sv);
  final newState = transition.newState;
  // ...
  return AiEngineOutput(
    plan: plan,
    newBehavioralState: newState,
    transitionKey: transition.transitionKey, // propagate
  );
  ```

- [x] UPDATE `lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`

  Add `transitionKey` to `DailyPlanLoaded`:

  ```dart
  import 'package:pulse_coach/ai/state_machine/behavioral_transition_key.dart';

  @freezed
  sealed class DailyPlanState with _$DailyPlanState {
    const factory DailyPlanState.loaded({
      required DailyPlan plan,
      @Default(BehavioralState.active) BehavioralState behavioralState,
      int? planDbId,
      BehavioralTransitionKey? transitionKey, // new — nullable, default null
    }) = DailyPlanLoaded;
    // ... other states unchanged
  }
  ```

  In `_onGenerateRequested` and `_onRegenerateRequested`, extract `transitionKey` from `_aiEngine` output. **Problem**: `DailyPlanBloc` doesn't have access to the `AiEngineOutput` directly — `GenerateDailyPlan` returns `Either<Failure, DailyPlan>` only. Two options:
  1. Read `transitionKey` from the new behavioral_state row's... but rows don't store transitionKey.
  2. Add `transitionKey` to `GenerateDailyPlan`'s return type.

  **Recommended**: Return `(DailyPlan, BehavioralTransitionKey?)` tuple from `GenerateDailyPlan.call()`, OR add `transitionKey` to the `DailyPlan` entity, OR read from the `behavioral_state` row change.

  **Simpler approach for stretch**: Since `DailyPlanBloc` reads `stateRow?.currentState` post-`GenerateDailyPlan`, and behavioral state is already persisted, `DailyPlanBloc` can compare the state before vs after to detect a transition. If states differ → the current `_parseState(stateRow?.currentState)` is the new state; the `transitionKey` can be inferred from (previousState, newState) pair.

  However, given the complexity of propagating `transitionKey` end-to-end through `GenerateDailyPlan`, **this sub-part of E7.5-T1** may be deferred to Story 9.4 if it expands scope. The critical part (removing hardcoded strings from `BehavioralStateMachine`) is already done in the steps above, which closes E7.5-T1's core blocker. The UI wiring can follow in 9.4.

  **Minimum viable E7.5-T1 closure**: Steps above (create enum, update BehavioralTransition + BehavioralStateMachine). `StateIndicator` resolution and `DailyPlanBloc` propagation are deferred to 9.4 if needed.

- [x] UPDATE `lib/features/today/presentation/widgets/state_indicator.dart` (if DailyPlanBloc propagation is done)

  ```dart
  // Add to StateMessages:
  static String? transitionMessageFor(BehavioralTransitionKey? key, AppLocalizations l10n) {
    return switch (key) {
      BehavioralTransitionKey.activeToAtRisk => l10n.transitionActiveAtRisk,
      BehavioralTransitionKey.fatiguedToAtRisk => l10n.transitionFatiguedAtRisk,
      BehavioralTransitionKey.activeToFatigued => l10n.transitionActiveFatigued,
      BehavioralTransitionKey.atRiskToRecovering => l10n.transitionAtRiskRecovering,
      BehavioralTransitionKey.fatiguedToRecovering => l10n.transitionFatiguedRecovering,
      BehavioralTransitionKey.recoveringToActive => l10n.transitionRecoveringActive,
      BehavioralTransitionKey.recoveringToFatigued => l10n.transitionRecoveringFatigued,
      null => null,
    };
  }
  ```

  Change `StateIndicator` constructor: replace `transitionMessage: String?` with `transitionKey: BehavioralTransitionKey?`. Resolve in `build()`:
  ```dart
  final subCopy = StateMessages.transitionMessageFor(transitionKey, l10n)
      ?? StateMessages.staticCopyFor(state, l10n);
  ```

  Update all call sites of `StateIndicator(transitionMessage: ...)` → `StateIndicator(transitionKey: ...)`.

- [x] UPDATE `test/domain/ai/behavioral_state_machine_test.dart`

  Replace all `transition.transitionMessage` assertions with `transition.transitionKey` assertions using the new enum values.

  E.g.: replace `expect(transition.transitionMessage, contains('Hai spinto'))` with `expect(transition.transitionKey, BehavioralTransitionKey.activeToFatigued)`.

- [x] UPDATE `test/widget/state_indicator_test.dart` (ARB invariant — E7.5-P2)

  Add presence assertions for the 7 `transition*` keys if they are not already covered:
  ```dart
  expect(allKeys, contains('transitionActiveAtRisk'));
  expect(allKeys, contains('transitionActiveFatigued'));
  // ... etc. for all 7 keys
  ```
  Use presence invariants only — no `hasLength(N)`.

  Add a new test: `StateMessages.transitionMessageFor(BehavioralTransitionKey.activeToAtRisk, l10n)` returns a non-empty string.

---

### Task 9: Baseline verification

- [x] Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` — verify `injection.config.dart` registers `UpdateBanditReward`.
- [x] Run `flutter test` from `pulse_coach/` — expect all 654 existing tests to pass plus the new ones (~15+ new).
- [x] Run `flutter analyze` — expect 0 issues.
- [x] Manual smoke (when device available):
  - Start session → complete → RPE tap → MiniSummary appears → auto-dismisses.
  - Confirm no crash or hang (adaptation runs silently in background).
  - Check `bandit_state` and `behavioral_state` DB tables updated (use Debug drawer if available, or logcat).

---

### Review Findings

> **Code review — 2026-05-22.** Sources: Blind Hunter (no context), Edge Case Hunter (project read access), Acceptance Auditor (spec + project). 18 findings retained after dedup; 4 dismissed as noise. AC1–AC6 all ✅ at the acceptance level — findings target hardening, dead plumbing, and test rigor.

**Decision-Needed — require product/architecture call before patching**

- [x] [Review][Decision→Patch] **Consume `AiEngineOutput.transitionKey` in `DailyPlanBloc`** — Resolved as patch (option 1): propagate `transitionKey` from `GenerateDailyPlan` through to `DailyPlanLoaded`, remove `DailyPlanBloc._transitionKeyFor` inference. Closes dead plumbing + TOCTOU race + silent-null fallback in one move. [`lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart:62-129,170-181`, `lib/ai/engine/ai_engine.dart:24-32`]

- [x] [Review][Decision→Patch] **Remove dead `planId` parameter** — Resolved as patch (option 1): drop `planId` from `UpdateBanditReward.call`, `PostRpeAdaptationCubit`, and the `rpe_page.dart` call site. The use case operates on the latest RPE via DAO; per-plan scoping not desired. [`update_bandit_reward.dart` call signature; `post_rpe_adaptation_cubit.dart:685,711`]

- [x] [Review][Decision→Dismiss] **`MissedSessionsCalculator` input semantics** — Investigated: `MissedSessionsCalculator.calculate(List<bool> completionFlags)` is *designed* to accept `isCompleted` flags and returns `completionFlags.where((c) => !c).length` (an `int`). `StateVector.missedSessions` is an `int`. Both `generate_daily_plan.dart:272` and `update_bandit_reward.dart:128` follow the same correct pattern. False positive — dismissed.

- [x] [Review][Decision→Dismiss] **Surface `PostRpeAdaptationError` to UI?** — Resolved as design choice (option 2): best-effort silent is the intended behavior. Post-RPE adaptation is already post-feedback; surfacing a background-task toast would confuse the user. AC5(c) is satisfied at the cubit boundary; UI consumer intentionally omitted. To be explicit in the commit message. [`rpe_page.dart:88-110`]

**Patch — applied 2026-05-22**

- [x] [Review][Patch] **P1: Drop spurious cold-start row in `behavioral_state`** — Guarded the insert on `output.stateChanged` only (was `|| stateRow == null`). Cold-start path is owned by `GenerateDailyPlan`. [`update_bandit_reward.dart:164`]
- [x] [Review][Patch] **P3: Log on `_validWeight` corruption recovery** — Added `developer.log('bandit_state: invalid weight coerced to 1.0 for arm=$armKey, raw=$weight', level: 900)`. Parser now takes the arm key for diagnostics. [`update_bandit_reward.dart:208-216`]
- [x] [Review][Patch] **P8: Strengthen 9.3-CUBIT-001** — Added `expect: () => [Running, Done]` to assert exactly one terminal state across the two `triggerUpdate` calls (was verify-only). [`test/bloc/post_rpe_adaptation_cubit_test.dart` 9.3-CUBIT-001]
- [x] [Review][Patch] **P9: New 9.3-UC-010 — atRisk camelCase parser round-trip** — Writes `BehavioralState.atRisk.name` ("atRisk") and verifies Rule 4 (atRisk→recovering) fires, proving the parser correctly reads canonical casing back through the DB. [`test/domain/usecases/update_bandit_reward_test.dart` 9.3-UC-010]
- [x] [Review][Patch] **P10 (ex-D1): Consume `AiEngineOutput.transitionKey` end-to-end** — Introduced `GenerateDailyPlanResult { plan, transitionKey }`; `GenerateDailyPlan` and `RegenerateDailyPlan` now return it; `DailyPlanBloc` reads `transitionKey` from the result and no longer reads pre/post `behavioral_state` rows. Closed dead plumbing + TOCTOU race + silent-null fallback in one move. `_transitionKeyFor` removed. [`generate_daily_plan.dart`, `regenerate_daily_plan.dart`, `daily_plan_bloc.dart`]
- [x] [Review][Patch] **P11 (ex-D2): Removed dead `planId` parameter** — Dropped from `UpdateBanditReward.call`, `PostRpeAdaptationCubit`, and the `rpe_page.dart` instantiation. The use case operates on the latest RPE via DAO; no per-plan scoping desired. [`update_bandit_reward.dart`, `post_rpe_adaptation_cubit.dart`, `rpe_page.dart`]

**Patch → Dismiss (re-evaluated during application)**

- [x] [Review][Patch→Dismiss] **P2: Don't latch `_triggered = true` on empty-armKey** — Re-read of code shows `triggerUpdate` already emits `PostRpeAdaptationDone` on the empty-armKey path (line 26 of cubit) before returning. The first call emits a terminal state; the second call's silent no-op is the correct idempotent semantics. Edge Case Hunter misread the order — dismissed.
- [x] [Review][Patch→Dismiss] **P6: `_transitionKeyFor` null logging** — N/A: `_transitionKeyFor` was removed entirely by P10. The whole inference path is gone, so there is nothing left to log.
- [x] [Review][Patch→Dismiss] **P7: `const BanditEngine()`** — Inapplicable: `BanditEngine` constructor body assigns `_random = random ?? Random()` and is not `const`-constructible. The spec literal was wrong; original non-const code is the only legal form.

**Patch → Defer (re-evaluated)**

- [x] [Review][Patch→Defer] **P4: Centralize `_parseState` parser** — Three copies now exist (`update_bandit_reward.dart`, `daily_plan_bloc.dart`, `generate_daily_plan.dart`). Casing is mathematically safe today (all readers `.toLowerCase()` against `'atrisk'` etc., and `BehavioralState.name` produces `"atRisk"` which lowercases to `"atrisk"`). P9 (new 9.3-UC-010 test) pins the canonical round-trip; consolidation is a refactor touching pre-existing `daily_plan` code outside this story's scope. Logged as deferred. [`update_bandit_reward.dart:213-219`, `daily_plan_bloc.dart:142-156`, `generate_daily_plan.dart:330-338`]
- [x] [Review][Patch→Defer] **P5: Timezone normalization in streak / missed-sessions window** — Pre-existing pattern: `generate_daily_plan.dart` uses the identical local-time approach (`_calculateStreak` lines 344-359, `_dateStr` line 361-362). Story 9.3 duplicated this pattern intentionally to match `GenerateDailyPlan`. Fixing it requires touching both files coherently to keep their semantics aligned — refactor out of story scope. Logged as deferred. [`update_bandit_reward.dart:221-244`, `generate_daily_plan.dart:344-362`]

**Defer — real, but not actionable in this story**

- [x] [Review][Defer] **`compute()` overhead vs O(1) bandit/state-machine work** — Isolate hop likely dominates the actual compute; AC4 still satisfied. [`update_bandit_reward.dart` `_computeRewardUpdate`] — deferred, perf optimization out of scope.
- [x] [Review][Defer] **Single `ServerFailure('bandit_reward_update_failed')` taxonomy** — All failure modes collapse to one string. Worth granular categories once a UI consumer exists. [`update_bandit_reward.dart:138-148`] — deferred until the Decision-Needed UI-surfacing call is made.
- [x] [Review][Defer] **`_kDummyProfile` latent contract violation** — `StateVector` is documented as profile-aware; current `BehavioralStateMachine` rules don't consume profile, so safe today, but adding any profile-keyed rule silently diverges the RPE-driven write from the plan-pipeline write. [`update_bandit_reward.dart:479-484`] — deferred, latent only.
- [x] [Review][Defer] **Use-case `Either` channel doesn't cover synchronous throw before first await** — Hypothetical only with mocks; production code can't reach this. — deferred, latent risk.
- [x] [Review][Defer] **`compute()` payload schema fragility on future `BanditState` changes** — No serialization smoke test; future non-transferable field would surface as opaque `ServerFailure`. — deferred, latent risk.

**Dismissed as noise (not written above):** test `DROP TABLE` setup in 9.3-UC-008 (intentional), `.reversed.toList()` filter edge, `Future.delayed(Duration.zero)` microtask pump (accepted Dart test pattern), Rule 4 `const` drop in `BehavioralStateMachine.evaluate()` (correct resolution of spec ambiguity).

---

### Review Outcome (2026-05-22)

**Status:** All review actions complete. Story moved to **done**.

- Decision-needed: 4 → resolved (2 patched, 2 dismissed)
- Patch findings: 11 proposed → **6 applied**, 3 dismissed on re-eval (P2 misread, P6 N/A after P10, P7 not const-constructible), 2 deferred (P4 cross-feature refactor, P5 pre-existing pattern in `GenerateDailyPlan`)
- Defer: 5 + 2 from re-eval = **7 total** in `deferred-work.md`
- Dismissed (incl. re-eval): 7
- **Tests:** 671 / 671 passing (was 670; +1 new 9.3-UC-010)
- **Analyzer:** 0 issues
- **AC1–AC6:** ✅ all still satisfied — review hardening preserved acceptance behavior

### Change Log Addendum

- 2026-05-22: Code-review patches applied — `AiEngineOutput.transitionKey` now consumed by `DailyPlanBloc` via new `GenerateDailyPlanResult` wrapper; dead `planId` parameter dropped from `UpdateBanditReward` / `PostRpeAdaptationCubit` / `rpe_page.dart`; spurious cold-start `behavioral_state` row insert removed from `UpdateBanditReward`; `_validWeight` now logs corruption recovery; CUBIT-001 strengthened with terminal-state assertion; new UC-010 pins atRisk camelCase parser round-trip. Note: `PostRpeAdaptationError` is intentionally not surfaced to UI (design choice — post-RPE adaptation is best-effort silent).

---

## Dev Notes

### Architecture: Where the Adaptation Fires in the Post-RPE Flow

```
InSessionPage → /session/rpe → RpePage
  RpeFeedbackCubit._persist() → DB write → emit(RpeFeedbackSubmitted)
  RpePage.BlocListener:
    1. _adaptationCubit.triggerUpdate(rpeValue)  ← fire-and-forget (Story 9.3)
    2. context.go(AppRouter.sessionSummary, extra: summaryArgs)  ← navigation (Story 9.2)

  [Background Dart Isolate via compute()]
    UpdateBanditReward loads state → _computeRewardUpdate → persist results
    PostRpeAdaptationCubit emits Done (or Error) — UI is already on MiniSummaryPage
```

The adaptation update is **fire-and-forget from the UI perspective**. Navigation is not gated on the update completing. `PostRpeAdaptationCubit.triggerUpdate()` is an async method but `RpePage` does NOT `await` it. The cubit's `Done`/`Error` state is not observed by any UI widget in this story (the cubit is owned by `RpePage` which has already navigated away).

### RPE History Timing

By the time `triggerUpdate()` is called from `RpePage.BlocListener`, `RpeFeedbackCubit._persist()` has already committed the new RPE row to the DB via `await _dao.insertFeedbackIdempotent(...)`. The emit of `RpeFeedbackSubmitted` happens AFTER the `await`. So `getLastN(10)` in `UpdateBanditReward` will include the new row. No manual RPE history injection needed.

### `BanditEngine` Has No Instance State — Just Construct Inline

`BanditEngine` is stateless (epsilon is constructor-injected). Inside `_computeRewardUpdate`, construct it as `const BanditEngine()` (which uses `epsilon: 0.2` default). This is correct for the reward update path — `epsilon` only matters for arm selection, not reward calculation. The `updateReward()` method delegates directly to `RewardCalculator.updateWeight()`.

### `BehavioralStateData.updatedAt` vs `DailyPlanLoaded.transitionKey` — Important Scope Boundary

`UpdateBanditReward` writes a new `behavioral_state` row when a transition occurs. This row is persisted to DB. The NEXT time `DailyPlanBloc` generates a plan (next day or on regenerate), it reads `behavioralStateDao.getLatestState()` and gets the updated state. Story 9.3 only ensures the state is persisted; surfacing the transition message in `StateIndicator` on the Today screen after a post-RPE update requires `DailyPlanBloc` to re-read state AND re-emit. This is NOT wired in Story 9.3 — Today screen's `StateIndicator` will show the updated state only after the next plan generation.

### E7.5-T1 Decision Log

The core deliverable of E7.5-T1 is removing the 7 hardcoded Italian literals from `BehavioralStateMachine`. Tasks 8a–8c (create enum, update BehavioralTransition, update BehavioralStateMachine) accomplish this. Tasks 8d–8h (AiEngineOutput → DailyPlanBloc → StateIndicator propagation) complete the UI surface-level wiring.

If time pressure forces a split: implement 8a–8c + state_machine_tests (closes the core), defer 8d–8h to Story 9.4. In that case, `StateIndicator` still accepts `transitionMessage: String?` and `DailyPlanBloc` emits `transitionKey: null` temporarily. This is safe — users see the static copy instead of the transition copy.

### `BanditStateDao.updateState` — Existing Implementation

```dart
Future<bool> updateState(BanditStateData data) =>
    update(banditState).replace(data);
```

This requires a fully populated `BanditStateData` with a valid `id`. Provide `id: banditRow.id` from the loaded row. Never construct `BanditStateData` with `id: 0` — Drift will reject it or replace the wrong row.

### `BehavioralStateDao` — Append-Log Pattern

Only `insertState()` exists — no `updateState()`. This is intentional (allows auditing state transition history). Always insert a new row. `getLatestState()` reads the most recent via `orderBy desc + limit 1`.

### Previous Story (9.2) Learnings Applied

- `getIt` only in `initState()`, never in `build()`.
- `isClosed` guard before every emit in the cubit.
- No `debugPrint`-only error handling — always emit explicit error state.
- All timer/async references cancelled in `close()` (not applicable here — no timers in `PostRpeAdaptationCubit`).
- Generated `app_localizations*.dart` — never stage (already `.gitignore`'d).

### E7.5-T1 Status After Story 9.3

If Tasks 8a–8c are completed: mark E7.5-T1 as `done` in `action-item-ledger.md` if full UI wiring is also done. Mark as `partial` (new status) or keep `pending` with updated note if only core is done. PM confirms.

### References

- Epic 9 Story 9.3 spec: `_bmad-output/planning-artifacts/epics.md` lines 1492–1527
- E7.5-T1 action item: `_bmad-output/implementation-artifacts/action-item-ledger.md` line 69
- `BanditEngine.updateReward()`: `pulse_coach/lib/ai/bandit/contextual_bandit.dart:84`
- `RewardCalculator.updateWeight()`: `pulse_coach/lib/ai/bandit/reward_calculator.dart:37`
- `BanditState` (domain): `pulse_coach/lib/ai/bandit/bandit_state.dart`
- `BanditStateDao`: `pulse_coach/lib/core/database/daos/bandit_state_dao.dart`
- `BehavioralStateMachine.evaluate()`: `pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart:25`
- `BehavioralTransition`: `pulse_coach/lib/ai/state_machine/behavioral_transition.dart`
- `BehavioralStateDao`: `pulse_coach/lib/core/database/daos/behavioral_state_dao.dart`
- `RpeFeedbackDao.getLastN()`: `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart:48`
- `RpePage` (to update): `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart`
- `RpeFeedbackCubit._persist()`: `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart:43`
- `AiEngine` + `AiEngineOutput`: `pulse_coach/lib/ai/engine/ai_engine.dart`
- `AiEngineIsolate._runPipeline`: `pulse_coach/lib/ai/engine/ai_engine_isolate.dart:36`
- `GenerateDailyPlan` (pattern reference for streak/missed): `pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart`
- `DailyPlanBloc`: `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`
- `StateIndicator` (to update for E7.5-T1): `pulse_coach/lib/features/today/presentation/widgets/state_indicator.dart`
- `MissedSessionsCalculator`: `pulse_coach/lib/ai/missed_sessions/missed_sessions_calculator.dart`
- `AppDatabase` (DAOs used): `pulse_coach/lib/core/database/app_database.dart`
- Transition ARB keys: `pulse_coach/lib/l10n/app/app_it.arb` (7 `transition*` keys lines 12–18)
- Sprint change proposal (Epic 9 alignment): `_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-20.md`
- Previous story 9.2: `_bmad-output/implementation-artifacts/9-2-minisummary-and-completionring-animation.md`
- Sprint status: `_bmad-output/implementation-artifacts/sprint-status.yaml`
- DI registration: `pulse_coach/lib/core/di/injection.config.dart`
- Project context (rules): `_bmad-output/project-context.md`

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-05-22: `dart run build_runner build --delete-conflicting-outputs` passed; generated DI, Freezed, Drift/Mockito outputs. Build runner warned that `--delete-conflicting-outputs` is ignored by the current tool version.
- 2026-05-22: `flutter test test/domain/usecases/update_bandit_reward_test.dart test/bloc/post_rpe_adaptation_cubit_test.dart test/domain/ai/behavioral_state_machine_test.dart test/widget/state_indicator_test.dart test/widget/rpe_page_test.dart test/bloc/daily_plan_bloc_test.dart` passed.
- 2026-05-22: `flutter test test/widget` passed after adding `UpdateBanditReward` registration to `pages_smoke_test.dart`.
- 2026-05-22: `flutter analyze` passed with no issues.
- 2026-05-22: final `flutter test` passed: 670/670.
- 2026-05-22: `adb devices` returned no attached devices; manual smoke was not run because no Android device was available.

### Completion Notes List

- Implemented `UpdateBanditReward` with isolate payload classes, `compute()` execution, EMA bandit reward persistence, and behavioral state re-evaluation/persistence.
- Added `PostRpeAdaptationCubit` lifecycle handling: idempotent trigger, no emits after close, explicit error state, and null/empty arm skip.
- Wired post-RPE adaptation into `RpePage` as fire-and-forget before navigation to mini summary.
- Completed E7.5-T1 stretch by replacing hardcoded state-machine transition messages with `BehavioralTransitionKey`, propagating keys through AI/DailyPlan/Today, and resolving localized copy in `StateIndicator`.
- Added unit/widget coverage for reward updates, cubit invariants, transition-key behavior, DailyPlan transition-key inference, and RPE page smoke setup.
- Manual device smoke not executed: no ADB device was attached at validation time.

### File List

- `_bmad-output/implementation-artifacts/9-3-bandit-reward-update-and-state-machine-re-evaluation.md`
- `_bmad-output/implementation-artifacts/action-item-ledger.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/ai/engine/ai_engine.dart`
- `pulse_coach/lib/ai/engine/ai_engine_isolate.dart`
- `pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart`
- `pulse_coach/lib/ai/state_machine/behavioral_transition.dart`
- `pulse_coach/lib/ai/state_machine/behavioral_transition_key.dart`
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.freezed.dart`
- `pulse_coach/lib/features/session/domain/usecases/update_bandit_reward.dart`
- `pulse_coach/lib/features/session/presentation/bloc/post_rpe_adaptation_cubit.dart`
- `pulse_coach/lib/features/session/presentation/bloc/post_rpe_adaptation_state.dart`
- `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart`
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart`
- `pulse_coach/lib/features/today/presentation/widgets/state_indicator.dart`
- `pulse_coach/test/bloc/daily_plan_bloc_test.dart`
- `pulse_coach/test/bloc/post_rpe_adaptation_cubit_test.dart`
- `pulse_coach/test/bloc/post_rpe_adaptation_cubit_test.mocks.dart`
- `pulse_coach/test/bloc/today_session_cubit_test.mocks.dart`
- `pulse_coach/test/domain/ai/behavioral_state_machine_test.dart`
- `pulse_coach/test/domain/usecases/update_bandit_reward_test.dart`
- `pulse_coach/test/widget/pages_smoke_test.dart`
- `pulse_coach/test/widget/rpe_page_test.dart`
- `pulse_coach/test/widget/state_indicator_test.dart`
- `pulse_coach/test/widget/today_page_test.mocks.dart`

### Change Log

- 2026-05-22: Story 9.3 created by create-story workflow. Baseline: 654/654 tests passing, 0 analyzer issues.
- 2026-05-22: Implemented bandit reward update, post-RPE adaptation cubit, transition-key i18n stretch, and tests; story moved to review.
