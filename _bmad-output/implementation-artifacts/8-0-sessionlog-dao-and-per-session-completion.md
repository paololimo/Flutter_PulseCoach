# Story 8.0: SessionLog DAO + Per-Session Completion Persistence

Status: done

## Story

As a returning user,
I want my session completion progress to survive closing and reopening the app,
So that the Today screen's progress ring and completed-session cards reflect what I actually finished today.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The user has completed 1 or more sessions on the Today screen earlier today | The user force-stops the app and relaunches it | The Today screen restores the same `CompletionRing` fraction and the same `CompletedSessionCard` stack that were visible before the force-stop (closes E7-F1) |
| AC2 | A fresh install with no prior completions | The Today screen loads | `CompletionRing` reads `0/N` and no `CompletedSessionCard`s are shown (no false positives from prior days) |
| AC3 | A daily plan is regenerated (whether or not `generatedAt` and `sessions.length` are identical to the previous plan) | `TodaySessionCubit` evaluates plan identity | It uses a stable persisted plan ID (not the `_isSamePlan` timestamp+length heuristic in `today_page.dart:46-47`) — a same-second regenerate that produces identical length **does not** preserve stale completion state from the previous plan |
| AC4 | The new persistence layer is in place | `flutter test` and `flutter analyze` run from `pulse_coach/` | Zero-tolerance baseline is preserved (`flutter analyze` 0 issues) and the test suite grows with new DAO + cubit-persistence tests |

## Tasks / Subtasks

### Task 1: Create `SessionLogs` Drift table (AC1, AC2, AC3)

- [x] CREATE `pulse_coach/lib/core/database/tables/session_logs_table.dart`
  ```dart
  import 'package:drift/drift.dart';

  @DataClassName('SessionLog')
  class SessionLogs extends Table {
    IntColumn get id => integer().autoIncrement()();
    IntColumn get dailyPlanId => integer()();        // FK → daily_plans.id
    IntColumn get sessionIndex => integer()();       // 0-based index in plan
    DateTimeColumn get completedAt => dateTime()();
    DateTimeColumn get createdAt => dateTime()();
  }
  ```
  - **No nullable columns**: every row represents a completed session; if not complete, no row.
  - `dailyPlanId` is the `daily_plans.id` auto-increment PK (integer), not `planDate` (string). This provides the stable identity guaranteeed by AC3.

### Task 2: Create `SessionLogsDao` (AC1, AC2)

- [x] CREATE `pulse_coach/lib/core/database/daos/session_logs_dao.dart`
  ```dart
  import 'package:drift/drift.dart';
  import 'package:pulse_coach/core/database/app_database.dart';
  import 'package:pulse_coach/core/database/tables/session_logs_table.dart';

  part 'session_logs_dao.g.dart';

  @DriftAccessor(tables: [SessionLogs])
  class SessionLogsDao extends DatabaseAccessor<AppDatabase>
      with _$SessionLogsDaoMixin {
    SessionLogsDao(super.db);

    Future<int> insertLog(SessionLogsCompanion entry) =>
        into(sessionLogs).insert(entry);

    Future<List<SessionLog>> getLogsForPlan(int planId) =>
        (select(sessionLogs)
              ..where((t) => t.dailyPlanId.equals(planId)))
            .get();

    Future<int> deleteLogsForPlan(int planId) =>
        (delete(sessionLogs)
              ..where((t) => t.dailyPlanId.equals(planId)))
            .go();
  }
  ```

### Task 3: Register table + DAO in `AppDatabase`, bump schema version (AC1, AC4)

- [x] UPDATE `pulse_coach/lib/core/database/app_database.dart`
  - Add imports for `SessionLogs` table and `SessionLogsDao`
  - Add `SessionLogs` to `@DriftDatabase(tables: [...])`
  - Add `SessionLogsDao` to `@DriftDatabase(daos: [...])`
  - Bump `schemaVersion` from `4` → `5`
  - Add migration branch to `onUpgrade`:
    ```dart
    if (from < 5) {
      await m.createTable(sessionLogs);
    }
    ```
  - **Expose accessor**: `SessionLogsDao get sessionLogsDao => SessionLogsDao(this);`
    (Mirror the pattern of other DAOs — check how `behavioralStateDao` is exposed and replicate exactly.)

### Task 4: Expose `planDbId` through `DailyPlanLoaded` state (AC3)

- [x] UPDATE `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`
  - In `DailyPlanLoaded` freezed factory, add: `@Default(0) int planDbId`
    ```dart
    const factory DailyPlanState.loaded({
      required DailyPlan plan,
      @Default(BehavioralState.active) BehavioralState behavioralState,
      @Default(0) int planDbId,
    }) = DailyPlanLoaded;
    ```
  - In `_onGenerateRequested`: after the `result.fold` success branch retrieves `plan`, also query `_db.dailyPlansDao.getPlanForDate(plan.planDate)` and pass its `.id` as `planDbId`. If the row is null (edge case), default to `0`.
  - Apply the **same change** in `_onRegenerateRequested`.
  - Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `daily_plan_bloc.freezed.dart`.

  > **Why fetch by planDate?** `GenerateDailyPlan` use case inserts into `daily_plans_table` and returns the `DailyPlan` entity, but the entity has no `dbId` field (domain purity). The cleanest data-layer bridge is to re-query by `planDate` — the `UNIQUE` constraint on `planDate` means the row is unambiguous. This query happens in the bloc where `_db` is already a direct dependency.

### Task 5: Refactor `TodaySessionCubit` to persist completions (AC1, AC2, AC3)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart`

  **State additions** (no freezed needed — plain class is fine; keep existing copyWith pattern):
  - No state changes visible to UI needed; persistence is transparent.

  **Cubit constructor + fields**:
  ```dart
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
  import 'package:pulse_coach/core/database/app_database.dart' show SessionLogsCompanion;
  import 'package:drift/drift.dart' show Value;

  @injectable
  class TodaySessionCubit extends Cubit<TodaySessionState> {
    final SessionLogsDao _sessionLogsDao;
    int _currentPlanId = 0;

    TodaySessionCubit(this._sessionLogsDao) : super(const TodaySessionState());
    ...
  }
  ```

  **`planLoaded` → async, with plan ID**:
  ```dart
  Future<void> planLoaded(int totalSessions, int planId) async {
    if (planId == 0) {
      // fallback: no DB row yet; reset to empty (shouldn't happen in prod)
      emit(TodaySessionState(totalSessions: totalSessions));
      return;
    }
    _currentPlanId = planId;
    final logs = await _sessionLogsDao.getLogsForPlan(planId);
    final completed = {for (final log in logs) log.sessionIndex};
    final heroIndex = _firstIncompleteIndex(completed, totalSessions, after: -1) ?? 0;
    emit(TodaySessionState(
      heroIndex: heroIndex,
      completedIndices: completed,
      totalSessions: totalSessions,
    ));
  }
  ```

  **`markSessionCompleted` → async, persists to DB**:
  ```dart
  Future<void> markSessionCompleted() async {
    if (state.totalSessions == 0 ||
        state.completedCount >= state.totalSessions ||
        state.isCompleted(state.heroIndex)) {
      return;
    }
    if (_currentPlanId > 0) {
      await _sessionLogsDao.insertLog(SessionLogsCompanion(
        dailyPlanId: Value(_currentPlanId),
        sessionIndex: Value(state.heroIndex),
        completedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
      ));
    }
    final newCompleted = <int>{...state.completedIndices, state.heroIndex};
    final nextHero = _firstIncompleteIndex(newCompleted, state.totalSessions, after: state.heroIndex);
    emit(state.copyWith(
      completedIndices: newCompleted,
      heroIndex: nextHero ?? state.heroIndex,
    ));
  }
  ```

  - **Keep `swapHero` unchanged** — it's a pure UI operation, no DB interaction needed.
  - Add `@injectable` annotation on the class (factory, not singleton — each Today route navigation gets a fresh cubit).

### Task 6: Update `TodayPage` — replace `_isSamePlan` with `planDbId` comparison (AC3)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/pages/today_page.dart`
  - **Remove** the `_isSamePlan` static method (lines 46-47).
  - **Update `listenWhen`**:
    ```dart
    listenWhen: (previous, current) =>
        current is DailyPlanLoaded &&
        (previous is! DailyPlanLoaded ||
            (previous as DailyPlanLoaded).planDbId !=
                (current as DailyPlanLoaded).planDbId),
    ```
    Or more idiomatically using pattern matching:
    ```dart
    listenWhen: (previous, current) {
      if (current is! DailyPlanLoaded) return false;
      if (previous is! DailyPlanLoaded) return true;
      return previous.planDbId != current.planDbId;
    },
    ```
  - **Update `listener`**: call async cubit method — use `unawaited` or `ignore` the future to avoid lint:
    ```dart
    listener: (context, state) {
      if (state case DailyPlanLoaded(:final plan, :final planDbId)) {
        context.read<TodaySessionCubit>()
            .planLoaded(plan.sessions.length, planDbId)
            .ignore();  // fire-and-forget; cubit emits states when ready
      }
    },
    ```

### Task 7: Wire `TodaySessionCubit` through DI in router (AC1)

- [x] UPDATE `pulse_coach/lib/core/routing/app_router.dart`
  - Change `BlocProvider(create: (_) => TodaySessionCubit())` to:
    ```dart
    BlocProvider(create: (_) => getIt<TodaySessionCubit>()),
    ```
  - `getIt<TodaySessionCubit>()` works because `@injectable` registers it as a factory — each `create` call returns a fresh instance with `SessionLogsDao` injected.

### Task 8: Regenerate build_runner outputs (AC4)

- [x] Run from `pulse_coach/`:
  ```
  dart run build_runner build --delete-conflicting-outputs
  ```
  - Generates `session_logs_dao.g.dart`, updates `app_database.g.dart`, `injection.config.dart`, `daily_plan_bloc.freezed.dart`.
  - Commit all generated files alongside source changes.

### Task 9: Add `SessionLogsDao` tests (AC4)

- [x] CREATE `pulse_coach/test/data/daos/session_logs_dao_test.dart`
  - Use `NativeDatabase.memory()` (never mock Drift DB — see project rules).
  - Test IDs in pattern `8.0-DAO-00N`.

  Required tests:
  ```
  8.0-DAO-001: insertLog stores a row retrievable by getLogsForPlan
  8.0-DAO-002: getLogsForPlan returns only logs for the given planId
  8.0-DAO-003: getLogsForPlan returns empty list for unknown planId
  8.0-DAO-004: insertLog for two different sessions yields two logs
  8.0-DAO-005: deleteLogsForPlan removes all rows for planId, returns count
  8.0-DAO-006: deleteLogsForPlan on unknown planId returns 0, no error
  ```

### Task 10: Update `TodaySessionCubit` tests (AC4)

- [x] UPDATE `pulse_coach/test/bloc/today_session_cubit_test.dart`
  - All existing tests (`7.3-UNIT-004` through `7.3-UNIT-012`) must be adapted for the new constructor signature. Provide a `MockSessionLogsDao`:
    ```dart
    @GenerateMocks([SessionLogsDao])
    ```
    Stub `getLogsForPlan` to return `[]` and `insertLog` to return `Future.value(1)` for the existing tests — behavior should be unchanged.
  - Add new persistence tests with IDs `8.0-UNIT-00N`:

  ```
  8.0-UNIT-001: planLoaded with planId=0 emits empty state without querying DAO
  8.0-UNIT-002: planLoaded with valid planId queries DAO and restores completedIndices
  8.0-UNIT-003: planLoaded with planId change resets completions even if same session count
  8.0-UNIT-004: markSessionCompleted calls insertLog with correct planId + sessionIndex
  8.0-UNIT-005: markSessionCompleted does NOT call insertLog when currentPlanId is 0
  8.0-UNIT-006: markSessionCompleted on already-completed session does not insert duplicate
  ```

  > **Note on E7-P2:** This story introduces a Cubit with index-into-collection state. The identity vs. position risk for `heroIndex` / `completedIndices` already exists — Story 8.0 does not change that logic, only wraps it with persistence. The E7-P2 process item (architect review during create-story) is addressed by this note; the existing Story 7.3 index tests (`7.3-UNIT-009`) remain the guard.

### Task 11: Update `today_page_test.dart` for async cubit (AC4)

- [x] UPDATE `pulse_coach/test/widget/today_page_test.dart`
  - `TodaySessionCubit` in the test's `BlocProvider` must now be mocked (add `MockTodaySessionCubit` via `@GenerateMocks`), or the test must provide a real cubit instance with a `MockSessionLogsDao`.
  - Update any test that calls `cubit.planLoaded(n)` → `cubit.planLoaded(n, planId)` (async — await or ignore).
  - Tests that assert Today screen content after plan load should still pass because the cubit's emitted states are structurally unchanged.

### Task 12: Run full baseline verification (AC4)

- [x] Run `flutter analyze` from `pulse_coach/` → expect 0 issues
- [x] Run `flutter test` from `pulse_coach/` → expect ≥ 516 tests passing + new DAO/cubit tests
- [x] Verify `schemaVersion == 5` in `app_database.dart`
- [x] Verify `SessionLogs` table appears in `@DriftDatabase(tables: [...])`

---

## Dev Notes

### Current State of Files Being Modified

**`lib/features/today/presentation/cubit/today_session_cubit.dart`**
- Plain class state (`TodaySessionState`), no `@freezed` — keep this pattern; do not convert to freezed.
- `TodaySessionCubit()` has no parameters — Story 8.0 adds `SessionLogsDao` as a required positional parameter.
- `planLoaded(int totalSessions)` is synchronous — Story 8.0 makes it `Future<void>` and adds a `planId` parameter.
- `markSessionCompleted()` is synchronous — Story 8.0 makes it `Future<void>`.
- **DO NOT** change the return type of `swapHero` — it remains synchronous `void`.

**`lib/features/today/presentation/pages/today_page.dart`**
- `_isSamePlan` at lines 46-47 is the fragile heuristic to remove: `a.generatedAt == b.generatedAt && a.sessions.length == b.sessions.length`.
- `context.read<TodaySessionCubit>().planLoaded(plan.sessions.length)` is inside `BlocConsumer.listener` — after this story, call `.ignore()` on the returned future to suppress `unawaited_futures` lint.
- `context.read<TodaySessionCubit>().markSessionCompleted()` is called from `_HeroZone.build()` (line 230) inside an `onStart` VoidCallback. Since `markSessionCompleted()` becomes async, the callback must call it and ignore the future: `onStart: () => context.read<TodaySessionCubit>().markSessionCompleted().ignore()`.
- `context.read<TodaySessionCubit>().swapHero(entry.index)` (line 166) stays synchronous — no change.

**`lib/core/database/app_database.dart`**
- Current `schemaVersion = 4` (see migration comments).
- Other DAO accessors are exposed as getters: `BehavioralStateDao get behavioralStateDao => BehavioralStateDao(this);` — replicate this exact pattern for `SessionLogsDao`.
- Look at the existing `if (from < 2)`, `if (from < 3)`, `if (from < 4)` migration blocks and add `if (from < 5) { await m.createTable(sessionLogs); }`.

**`lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`**
- Both `_onGenerateRequested` and `_onRegenerateRequested` already query `_db.behavioralStateDao.getLatestState()` after plan generation. Add the analogous `_db.dailyPlansDao.getPlanForDate(plan.planDate)` call in the same location and extract `.id` for `planDbId`.
- Pattern for both handlers (in the `result.fold` success callback):
  ```dart
  (plan) async {
    final stateRow = await _db.behavioralStateDao.getLatestState();
    final planRow = await _db.dailyPlansDao.getPlanForDate(plan.planDate);
    if (isClosed) return;
    emit(DailyPlanState.loaded(
      plan: plan,
      behavioralState: _parseState(stateRow?.currentState),
      planDbId: planRow?.id ?? 0,
    ));
  },
  ```

**`lib/core/routing/app_router.dart`**
- `TodaySessionCubit()` is constructed inline at line 53. Replace with `getIt<TodaySessionCubit>()`. The `getIt` import is already present.

### Architecture Compliance

- **Clean Architecture**: `SessionLogsDao` lives in `lib/core/database/daos/` — same layer as `DailyPlansDao`. Correct.
- **Drift pattern**: `@DriftAccessor(tables: [SessionLogs])` + `with _$SessionLogsDaoMixin`. Must add `part 'session_logs_dao.g.dart';`. Never mock Drift DB in tests — use `NativeDatabase.memory()`.
- **DI**: `TodaySessionCubit` gets `@injectable` (factory). `SessionLogsDao` is registered as part of `AppDatabase` setup — it will be available via `getIt` after `build_runner` regenerates `injection.config.dart`.
- **build_runner order**: Run ONCE after all source changes are made. Do not run multiple times.
- **Freezed**: `DailyPlanState.loaded` is `@freezed` — adding a field with `@Default(0)` is backward-compatible; no migration of existing frozen state needed.

### Anti-Patterns to Avoid

| ❌ | ✅ |
|---|---|
| Mock the Drift database in DAO tests | Use `NativeDatabase.memory()` and a real `AppDatabase.forTesting(executor)` |
| Leave `TodaySessionCubit()` as a direct constructor call in tests | Inject `MockSessionLogsDao` via the new constructor |
| Use `today_page.dart`'s `_isSamePlan` as the identity check | Remove it — use `planDbId` comparison in `listenWhen` |
| Make `planLoaded` synchronous (ignore the async nature) | Await the DB query; emit state only after completions are loaded |
| Add `dbId` to the `DailyPlan` domain entity | Keep entity clean; fetch DB row in bloc via `dailyPlansDao.getPlanForDate` |
| Register `TodaySessionCubit` as a `@singleton` | Register as `@injectable` factory — each Today navigation needs a fresh instance |
| Call `markSessionCompleted()` without ignoring the returned future in VoidCallback | `.ignore()` the future in `onStart:` callback (prevents `unawaited_futures` lint error) |

### Test Naming Convention

- New DAO tests: `8.0-DAO-001` through `8.0-DAO-006`
- New cubit persistence tests: `8.0-UNIT-001` through `8.0-UNIT-006`
- Existing cubit tests `7.3-UNIT-004` through `7.3-UNIT-012` must be updated but IDs stay the same.

### E7-P2 Process Note (Architect Identity-vs-Position Review)

Story 8.0 keeps `heroIndex` as a positional index (not a session type key or DB ID). This is intentional: the `TodaySessionCubit` already handles this correctly via `completedIndices: Set<int>` + the `_firstIncompleteIndex` scan. The persistence layer adds the DB rowId as the plan identity signal without changing how completed session *positions* are tracked. The existing Story 7.3 tests (`7.3-UNIT-009` through `7.3-UNIT-012`) remain the guards for positional-identity correctness.

### Deferred Items Budget Note

The ledger shows 11 `pending`/`in-progress` items vs. the 5-item cap (CLAUDE.md rule). Story 8.0 closes `E7-F1` (currently `in-progress`). The PM should triage the remaining items at Epic 8 kickoff. The story proceeds per the standing decision to insert Story 8.0 before Story 8.1.

### References

- `_isSamePlan` heuristic to remove: `pulse_coach/lib/features/today/presentation/pages/today_page.dart:46-47`
- `TodaySessionCubit` current inline DI in router: `pulse_coach/lib/core/routing/app_router.dart:53`
- `AppDatabase.schemaVersion` and migration: `pulse_coach/lib/core/database/app_database.dart:37-52`
- `DailyPlanLoaded` freezed state: `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart` (DailyPlanState section)
- DAO accessor pattern (e.g. `BehavioralStateDao`): `pulse_coach/lib/core/database/daos/behavioral_state_dao.dart`
- E7-F1 tracked in: `_bmad-output/implementation-artifacts/action-item-ledger.md` (Epic 7 In-Sprint Findings section)
- E7-P2 (architect review process): `_bmad-output/implementation-artifacts/action-item-ledger.md` (Epic 7 Retro section)

---

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-05-16: `flutter test test/core/database/daos/session_logs_dao_test.dart test/bloc/today_session_cubit_test.dart` failed red before implementation because `SessionLogs`, `SessionLogsDao`, `sessionLogsDao`, and new Cubit signatures did not exist.
- 2026-05-16: `dart run build_runner build --delete-conflicting-outputs` initially generated code but reported missing DI registration for `SessionLogsDao`; added provider in `HealthModule` and regenerated successfully.
- 2026-05-16: `flutter test test/core/database/daos/session_logs_dao_test.dart test/bloc/today_session_cubit_test.dart test/widget/today_page_test.dart` passed after fixing UTC/local `DateTime` assertion by comparing epoch milliseconds.
- 2026-05-16: `flutter analyze` passed with no issues.
- 2026-05-16: `flutter test` passed with 535 tests.

### Completion Notes List

- Implemented `SessionLogs` table and `SessionLogsDao` with insert, read-by-plan, and delete-by-plan operations.
- Registered `SessionLogs` in Drift schema v5 and generated the corresponding database/DAO code.
- Added `DailyPlanLoaded.planDbId` and populated it by re-querying the persisted daily plan row after generate/regenerate.
- Refactored `TodaySessionCubit` to restore and persist completed session indices per stable `dailyPlanId`, while preserving existing positional hero/session behavior.
- Replaced Today page plan identity comparison with `planDbId` and wired async Cubit methods with `.ignore()` in UI callbacks.
- Wired `TodaySessionCubit` through DI and updated tests/router smoke helpers to inject `SessionLogsDao`.
- Added DAO, Cubit persistence, DailyPlanBloc plan ID, database migration, and updated widget/router tests.
- Placed `session_logs_dao_test.dart` under the repository's existing DAO test convention, `test/core/database/daos/`, rather than introducing a new `test/data/daos/` tree.

### File List

- `pulse_coach/lib/core/database/tables/session_logs_table.dart` (NEW)
- `pulse_coach/lib/core/database/daos/session_logs_dao.dart` (NEW)
- `pulse_coach/lib/core/database/daos/session_logs_dao.g.dart` (NEW — generated)
- `pulse_coach/lib/core/database/app_database.dart` (UPDATE — add table + DAO + schemaVersion 5 + migration)
- `pulse_coach/lib/core/database/app_database.g.dart` (UPDATE — regenerated)
- `pulse_coach/lib/core/di/health_module.dart` (UPDATE — register SessionLogsDao provider)
- `pulse_coach/lib/core/di/injection.config.dart` (UPDATE — regenerated TodaySessionCubit + SessionLogsDao DI)
- `pulse_coach/lib/core/routing/app_router.dart` (UPDATE — getIt<TodaySessionCubit>())
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart` (UPDATE — add planDbId to DailyPlanLoaded + fetch DB row ID in both handlers)
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.freezed.dart` (UPDATE — regenerated)
- `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart` (UPDATE — add SessionLogsDao dep, async planLoaded + markSessionCompleted, @injectable)
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart` (UPDATE — replace _isSamePlan with planDbId listenWhen, async ignore in listener + onStart)
- `pulse_coach/test/core/database/daos/session_logs_dao_test.dart` (NEW)
- `pulse_coach/test/core/database/app_database_test.dart` (UPDATE — schema v5 and v4→v5 migration coverage)
- `pulse_coach/test/core/routing/app_router_test.dart` (UPDATE — register TodaySessionCubit DI in router tests)
- `pulse_coach/test/bloc/daily_plan_bloc_test.dart` (UPDATE — assert persisted planDbId)
- `pulse_coach/test/bloc/today_session_cubit_test.dart` (UPDATE — adapt constructor, add 8.0-UNIT tests)
- `pulse_coach/test/bloc/today_session_cubit_test.mocks.dart` (NEW — generated)
- `pulse_coach/test/widget/today_page_test.dart` (UPDATE — async planLoaded, mock/inject SessionLogsDao)
- `pulse_coach/test/widget/today_page_test.mocks.dart` (UPDATE — generated SessionLogsDao mock)
- `pulse_coach/test/widget/app_shell_test.dart` (UPDATE — inject test TodaySessionCubit)
- `pulse_coach/test/widget/pages_smoke_test.dart` (UPDATE — inject test TodaySessionCubit)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (UPDATE — story status review)
- `_bmad-output/implementation-artifacts/8-0-sessionlog-dao-and-per-session-completion.md` (UPDATE — task/status/dev record)

### Change Log

- 2026-05-16: Implemented per-session completion persistence via `SessionLogs` and stable persisted daily plan IDs.
- 2026-05-16: Added DAO, Cubit, Bloc, database migration, router, and widget test coverage; `flutter analyze` and `flutter test` pass.
- 2026-05-17: Code review passed. Resolved 1 decision + applied 12 patches:
  - schema v6 with UNIQUE(dailyPlanId, sessionIndex) + FK (ON DELETE CASCADE) + `PRAGMA foreign_keys = ON` in `beforeOpen`;
  - `SessionLogsDao.insertLog` uses `InsertMode.insertOrIgnore`;
  - `DailyPlanLoaded.planDbId` is now nullable (sentinel `0` removed);
  - `TodaySessionCubit` got try/catch around `insertLog`, in-flight stale-planId guard, hero-when-all-complete fallback, sanitization of stale `sessionIndex >= totalSessions`;
  - new tests: 8.0-DAO-007 (unique-key idempotency), 8.0-DAO-008 (FK cascade), 8.0-UNIT-007 (all-complete hero), 8.0-UNIT-008 (insertLog throws), 8.0-UNIT-009 (stale-index sanitization), composite migration v3→v6;
  - strengthened 8.0-UNIT-003 (non-empty replacement set), 8.0-UNIT-004 (completedAt recency), 8.0-UNIT-005 (planLoaded(null) regression).
  - `flutter test` 541/541 pass, `flutter analyze` 0 issues.

### Review Findings

_Code review 2026-05-17 — three parallel reviewers (Blind Hunter, Edge Case Hunter, Acceptance Auditor). AC1–AC4 all satisfied; AC3 verified manually (regenerate flow calls `deletePlanForDate` before `insertPlan`, producing a new `daily_plans.id` even for same-second same-length regenerates)._

- [x] [Review][Decision] `completedAt` vs `createdAt` duplicate column — **resolved 2026-05-17 (Paolo): keep both for convention** (all other tables carry `createdAt`; no code change). [`pulse_coach/lib/core/database/tables/session_logs_table.dart:8-9`]
- [x] [Review][Patch] Add `UNIQUE(dailyPlanId, sessionIndex)` constraint + use `InsertMode.insertOrIgnore` in `insertLog` — current in-memory guard `state.isCompleted(...)` is the only defense against duplicates; a double-tap or out-of-cubit insert can create duplicates [`pulse_coach/lib/core/database/tables/session_logs_table.dart:4-10`, `pulse_coach/lib/core/database/daos/session_logs_dao.dart:12-13`]
- [x] [Review][Patch] Add FK `references(dailyPlans, #id)` + index on `dailyPlanId` + call `deleteLogsForPlan(oldId)` from `RegenerateDailyPlan` (or via FK cascade) — orphan log rows currently accumulate forever because regenerate deletes the plan row without cleaning logs [`session_logs_table.dart:6`, `pulse_coach/lib/features/daily_plan/data/repositories/daily_plan_repository_impl.dart:46`]
- [x] [Review][Patch] Wrap `insertLog` in try/catch and emit `error`/no-op on failure — DB-locked / disk-full / constraint exceptions currently bubble unhandled, freezing the ring [`pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart:79-95`]
- [x] [Review][Patch] Hero fallback when all sessions complete — `_firstIncompleteIndex(..., after: -1) ?? 0` selects index `0` (a completed session) when `completed == {0..N-1}`. Return last index or a "done" sentinel [`pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart:48-56`]
- [x] [Review][Patch] Sanitize stale `sessionIndex >= totalSessions` on `planLoaded` — a regenerate with fewer sessions yields `completedCount > total` and a broken ring [`pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart:41-61`]
- [x] [Review][Patch] In-flight guard + stale-planId check around `markSessionCompleted` / `planLoaded` — `await insertLog` followed by `emit(state.copyWith(...))` can write to a stale state if a regenerate landed mid-insert; `_currentPlanId` must be re-checked after every await [`cubit.dart:72-104`]
- [x] [Review][Patch] Replace `planDbId == 0` sentinel with nullable `int?` — `DailyPlanLoaded.planDbId` falls back to `0` when `getPlanForDate` returns null (fresh install race); a nullable field is unambiguous and prevents silent persistence drops [`pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart:66-71,101-110`, `cubit.dart:42-58`]
- [x] [Review][Patch] Add test: all-sessions-complete hero fallback (covers the patch above) [`pulse_coach/test/bloc/today_session_cubit_test.dart`]
- [x] [Review][Patch] Add test: `planLoaded(n, validId)` → `planLoaded(m, 0)` → `markSessionCompleted` does not write to previous plan (Auditor-flagged regression gap; 8.0-UNIT-005 currently passes by accident because `_currentPlanId` defaults to 0) [`pulse_coach/test/bloc/today_session_cubit_test.dart`]
- [x] [Review][Patch] Strengthen 8.0-UNIT-003 — current assertion is satisfied by the new DAO read overwriting; add a variant where DAO returns a different non-empty set for the new planId to prove the reset is "drop previous in-memory state" not "merge" [`pulse_coach/test/bloc/today_session_cubit_test.dart`]
- [x] [Review][Patch] Strengthen 8.0-UNIT-004 — assert `completedAt` is recent (e.g. within ±5s of `DateTime.now()`) instead of only `Value.present == true` [`pulse_coach/test/bloc/today_session_cubit_test.dart:215-228`]
- [x] [Review][Patch] Add migration test `v3 → v5` (combined `addColumn` + `createTable`) — only `v4 → v5` is covered, and existing alpha users likely span multiple older versions [`pulse_coach/test/core/database/app_database_test.dart`]
- [x] [Review][Defer] Day-boundary / TZ leak in `getLogsForPlan` — currently inert because `daily_plans.planDate` is UNIQUE per day, so logs for a planId are inherently same-day; revisit if plan rows ever span days [`cubit.dart:41-61`] — deferred, currently inert
- [x] [Review][Defer] Use `Future.wait` for the two independent awaits (`getLatestState` + `getPlanForDate`) in `DailyPlanBloc` — micro-perf, every generate adds one DB round trip [`daily_plan_bloc.dart:65-72,100-110`] — deferred, perf-only
- [x] [Review][Defer] Layering smell: `DailyPlanBloc` re-queries `getPlanForDate` for a row the usecase just wrote — plan id should be returned by `GenerateDailyPlan`/`RegenerateDailyPlan` instead [`daily_plan_bloc.dart:66,101`] — deferred, refactor candidate
- [x] [Review][Defer] `_TestingTodaySessionCubit` copy-pasted across `app_shell_test.dart:131-147` and `pages_smoke_test.dart:228-243` — extract a shared test helper — deferred, DRY cleanup
- [x] [Review][Defer] Empty plan (`sessions.length == 0`) renders as "all done" with ring 0/0 — no telemetry signal; acceptable for v1 [`cubit.dart:41-61`] — deferred, low priority
- [x] [Review][Defer] No `provideDummy<SessionLog>` in `today_session_cubit_test.dart` — latent fragility when a third DAO method (e.g. `deleteLogsForPlan`) is exercised in a future test — deferred, test-suite hygiene
- [x] [Review][Defer] `SessionLogsDao` is `@singleton` while `TodaySessionCubit` is `@injectable` (factory) — fine now, but a future singleton cubit would turn `_currentPlanId` into shared mutable state [`health_module.dart:34-37`] — deferred, latent
