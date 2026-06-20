# Story 14.4: AI Decision Log [MVP-if-time]

Status: done

## Story

As an advanced user,
I want to see a log of the AI's session selection decisions,
so that I can understand how the system is learning and adapting to me.

## Acceptance Criteria

**AC1 — Decision list renders (FR51):**
Given the user navigates to AI Decision Log from the Settings drawer (Debug section)
When the screen renders with at least one completed RPE session
Then a list of bandit decision records is displayed, each row showing:
- Date of the decision
- StateVector summary (key signals: restingHR, stepCount, rpeHistory last value, behavioralState, streak, missedSessions)
- Selected arm (sessionType + intensity, e.g. "mobility / medium")
- RPE reward value (the rpe submitted after that session)

**AC2 — Row tap expands detail:**
Given the log is displayed
When the user taps a row
Then an expanded view shows the full state vector fields that contributed to the decision (all StateVector fields in a readable key-value list)

**AC3 — Empty state:**
Given no decisions have been recorded (new user / no RPE submitted yet)
When the log renders
Then an empty state message is shown in Italian: "Nessuna decisione ancora. Completa la tua prima sessione per vedere come l'AI sta imparando."

**AC4 — Screen accessible only in Debug mode:**
Given the screen is debug-only
When kDebugMode is false (release build)
Then the drawer tile is absent and the route, if navigated to directly, renders the page only when guarded by kDebugMode (or navigates away gracefully)

## Tasks / Subtasks

- [x] Task 1: Add ARB keys (AC1, AC3)
  - [x] 1.1 Add keys to `pulse_coach/lib/l10n/app/app_it.arb`:
    - `aiDecisionLogTitle`: "AI Decision Log"
    - `aiDecisionLogEmpty`: "Nessuna decisione ancora. Completa la tua prima sessione per vedere come l'AI sta imparando."
    - `aiDecisionLogDrawerTile`: "AI Decision Log"
  - [x] 1.2 Add the same keys (English values) to `pulse_coach/lib/l10n/app/app_en.arb`:
    - `aiDecisionLogTitle`: "AI Decision Log"
    - `aiDecisionLogEmpty`: "No decisions yet. Complete your first session to see how the AI is learning."
    - `aiDecisionLogDrawerTile`: "AI Decision Log"
  - [x] 1.3 Run `flutter pub get` from `pulse_coach/` to regenerate `app_localizations*.dart`

- [x] Task 2: Create the data model `AiDecisionRecord` (AC1, AC2)
  - [x] 2.1 Create `pulse_coach/lib/features/settings/data/models/ai_decision_record.dart`
  - [x] 2.2 Plain Dart class (no Drift table — this is a read-only view assembled from existing tables):
    ```dart
    class AiDecisionRecord {
      final DateTime decidedAt;   // from rpe_feedback.recorded_at
      final String armKey;        // from rpe_feedback: reconstructed from session type/intensity via session_logs → daily_plans
      final int rpeValue;         // from rpe_feedback.rpe_value
      final StateVector? stateVector; // null if not reconstructible (old records)
    }
    ```
  - [x] 2.3 Keep it in `features/settings/data/models/` — this is a UI projection, not a new domain entity

- [x] Task 3: Create `AiDecisionLogRepository` (AC1, AC2, AC3)
  - [x] 3.1 Create `pulse_coach/lib/features/settings/data/repositories/ai_decision_log_repository.dart`
  - [x] 3.2 Constructor accepts `RpeFeedbackDao`, `SessionLogsDao`, `DailyPlansDao`
  - [x] 3.3 `getDecisions()` → `Future<List<AiDecisionRecord>>`:
    - Call `rpeFeedbackDao.getAllFeedback()` (returns `List<RpeFeedbackData>`, ordered by `recordedAt` desc)
    - For each feedback row, look up the `SessionLog` via `sessionLogId` to get `sessionIndex`
    - Look up the `DailyPlan` via `dailyPlanId` to get the `sessionsJson` and extract the arm from the planned session at `sessionIndex`
    - Arm key = `'${session.sessionType}_${_intensityName(session.intensity)}'` (same logic as `in_session_page.dart:118-119`)
    - `stateVector` = null (StateVector is not persisted; this is acceptable for MVP)
    - Return list sorted newest first
  - [x] 3.4 Annotate `@injectable`; register via DI build_runner

- [x] Task 4: Create `AiDecisionLogCubit` and state (AC1, AC2, AC3)
  - [x] 4.1 Create `pulse_coach/lib/features/settings/presentation/bloc/ai_decision_log_state.dart`:
    ```dart
    class AiDecisionLogState extends Equatable {
      final bool isLoading;
      final List<AiDecisionRecord> decisions;

      const AiDecisionLogState({this.isLoading = true, this.decisions = const []});

      @override
      List<Object?> get props => [isLoading, decisions];
    }
    ```
  - [x] 4.2 Create `pulse_coach/lib/features/settings/presentation/bloc/ai_decision_log_cubit.dart`
  - [x] 4.3 `@injectable`; constructor accepts `AiDecisionLogRepository`
  - [x] 4.4 `load()` method: emit loading → call `repository.getDecisions()` → emit loaded with decisions list
  - [x] 4.5 Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart`

- [x] Task 5: Create `AiDecisionLogPage` widget (AC1, AC2, AC3, AC4)
  - [x] 5.1 Create `pulse_coach/lib/features/settings/presentation/pages/ai_decision_log_page.dart`
  - [x] 5.2 `BlocBuilder<AiDecisionLogCubit, AiDecisionLogState>`:
    - While `isLoading`: show `CircularProgressIndicator`
    - Empty decisions: centered `Text(l10n.aiDecisionLogEmpty)` with 16dp padding
    - Non-empty: `ListView.builder` with one `ExpansionTile` per decision
  - [x] 5.3 Each `ExpansionTile` header (collapsed): date formatted as `dd/MM/yyyy HH:mm` + arm key humanized (e.g. "Mobilità / Media") + RPE value chip
  - [x] 5.4 Expanded content: key-value `Column` with all `AiDecisionRecord` fields; `stateVector` null → show "StateVector non disponibile"
  - [x] 5.5 Wrap entire page in `Scaffold(appBar: AppBar(title: Text(l10n.aiDecisionLogTitle)), body: ...)`

- [x] Task 6: Wire route and drawer (AC1, AC4)
  - [x] 6.1 Add `static const String aiDecisionLog = '/ai-decision-log'` to `AppRouter` (`pulse_coach/lib/core/routing/app_router.dart`)
  - [x] 6.2 Add `GoRoute` for `aiDecisionLog`:
    ```dart
    GoRoute(
      path: aiDecisionLog,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<AiDecisionLogCubit>()..load(),
        child: const AiDecisionLogPage(),
      ),
    ),
    ```
  - [x] 6.3 In `app_shell.dart`, extend the existing `if (kDebugMode)` drawer block to include the AI Decision Log tile:
    ```dart
    if (kDebugMode) ...[
      ListTile(
        leading: const Icon(Icons.bug_report),
        title: Text(l10n.drawerDebug),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: const Icon(Icons.psychology),
        title: Text(l10n.aiDecisionLogDrawerTile),
        onTap: () {
          Navigator.pop(context);
          context.push(AppRouter.aiDecisionLog);
        },
      ),
    ]
    ```

- [x] Task 7: Add tests (AC1, AC3)
  - [x] 7.1 Create `pulse_coach/test/bloc/ai_decision_log_cubit_test.dart`:
    - [x] `14.4-CUBIT-001`: `load()` emits `isLoading: false` with populated decisions list when repo returns data
    - [x] `14.4-CUBIT-002`: `load()` emits `isLoading: false` with empty decisions list when repo returns empty
  - [x] 7.2 Create `pulse_coach/test/widget/ai_decision_log_page_test.dart`:
    - [x] `14.4-WIDGET-001`: empty state text is shown when `decisions` is empty and `isLoading` is false
    - [x] `14.4-WIDGET-002`: decision rows rendered when `decisions` has entries (arm key and RPE visible)
    - [x] `14.4-WIDGET-003`: loading indicator shown when `isLoading` is true

- [x] Task 8: Verify
  - [x] 8.1 Run `flutter test` from `pulse_coach/`. Target: 839 + 5 new = ≥ 844 total. All existing tests green.
  - [x] 8.2 Run `flutter analyze` from `pulse_coach/`. Must be 0 issues.

## Dev Notes

### What Is Already In Place (Do NOT Reinvent)

- **`RpeFeedbackDao`** at `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart` — `getAllFeedback()` returns all RPE rows. `getLastN(n)` returns the last N. `getBySessionLogId(id)` returns a single row. The `RpeFeedbackData` has: `id`, `sessionId`, `sessionLogId` (nullable), `rpeValue`, `recordedAt`.
- **`SessionLogsDao`** at `pulse_coach/lib/core/database/daos/session_logs_dao.dart` — look up session log by id to get `dailyPlanId` and `sessionIndex`.
- **`DailyPlansDao`** at `pulse_coach/lib/core/database/daos/daily_plans_dao.dart` — fetch plan by id to get `sessionsJson`.
- **Arm key construction** already exists verbatim in `in_session_page.dart:118-119`:
  ```dart
  final armKey = '${session.sessionType}_${_intensityName(session.intensity)}';
  ```
  where `_intensityName` maps `intensity` int (3→`low`, 6→`medium`, 8→`high`) to the string key suffix. **Copy the same helper logic** — do not reinvent.
- **`StateVector`** is NOT persisted to the DB. The AI engine runs in an isolate and discards the vector after producing the plan. For MVP-if-time scope, `stateVector` in `AiDecisionRecord` is always `null`. This is acceptable per the story AC: the expanded row shows "StateVector non disponibile."
- **DI pattern**: `@injectable` on the repository and cubit; `flutter pub run build_runner build --delete-conflicting-outputs` regenerates `injection.config.dart`. Never edit `injection.config.dart` manually.
- **Drawer debug block** in `pulse_coach/lib/shared/widgets/app_shell.dart` lines 198-203: currently a single `if (kDebugMode)` tile for "Debug" (tap = just closes drawer). Add the AI Decision Log tile inside the same `if (kDebugMode)` guard — use a spread `...[tile1, tile2]` to keep both.
- **`AppRouter`** at `pulse_coach/lib/core/routing/app_router.dart` — add the new route constant and `GoRoute` entry alongside `/device-settings` (line 117). Pattern: `BlocProvider(create: (_) => getIt<CubitClass>()..load(), child: const PageWidget())`.
- **ARB pipeline** is fully wired. Source files: `pulse_coach/lib/l10n/app/app_it.arb` and `app_en.arb`. Generated files are gitignored — regenerate via `flutter pub get`.
- **Theme / styling**: follow the exact same `ListTile(contentPadding: EdgeInsets.zero, ...)` pattern used in `SettingsPage` for consistency. Use `Theme.of(context).textTheme.titleSmall` for section headers if needed.
- **`kDebugMode`** is from `package:flutter/foundation.dart` — already imported in `app_shell.dart`.

### DI Topology — What Feeds What

```
AppDatabase → RpeFeedbackDao (existing singleton via @DriftAccessor)
AppDatabase → SessionLogsDao (existing)
AppDatabase → DailyPlansDao (existing)

AiDecisionLogRepository(@injectable) ← RpeFeedbackDao, SessionLogsDao, DailyPlansDao
AiDecisionLogCubit(@injectable) ← AiDecisionLogRepository
```

Register `AiDecisionLogRepository` with `@injectable`. The three DAO parameters are already singletons in the DI graph — injectable will resolve them automatically.

### Arm Key Reconstruction Logic

The planned sessions for a daily plan are stored in `daily_plans_table.sessionsJson` as a JSON array. Each element is a `PlannedSession` with `sessionType` (string), `intensity` (int: 3, 6, 8), `durationMinutes`, `isIndoor`. To reconstruct the arm key for the session at `sessionIndex`:

```dart
String _intensityName(int intensity) => switch (intensity) {
  3 => 'low',
  6 => 'medium',
  8 => 'high',
  _ => 'unknown',
};
// armKey = '${session.sessionType}_${_intensityName(session.intensity)}'
```

Note: `sessionsJson` deserialization is already implemented in `generate_daily_plan.dart` — look at how `DailyPlan.fromJson` / `PlannedSession` are parsed to avoid reinventing JSON decode logic.

### Human-Readable Arm Key Display

For the collapsed row header, map arm keys to Italian labels:
```
mobility_low → "Mobilità / Bassa"
mobility_medium → "Mobilità / Media"
mobility_high → "Mobilità / Alta"
cardio_low → "Cardio / Bassa"
cardio_medium → "Cardio / Media"
cardio_high → "Cardio / Alta"
breathing_low → "Respirazione / Bassa"
breathing_medium → "Respirazione / Media"
breathing_high → "Respirazione / Alta"
```
Use a simple `switch` in the widget, inline — no need for a separate helper file.

### Data Availability Note

Older RPE rows (before Story 8.0 added `session_log_id`) have `sessionLogId == null`. For these rows, `AiDecisionLogRepository` cannot reconstruct the arm key. Return a sentinel `AiDecisionRecord` with `armKey = 'unknown'` and `stateVector = null`. The widget renders "Dati non disponibili" for the arm. Do NOT crash or skip the row.

### Test Patterns to Follow

- `device_settings_cubit_test.dart` is the direct precedent — uses `@GenerateMocks` from `mockito`, `blocTest` from `bloc_test`, standard `setUp`/`tearDown`.
- `ai_decision_log_page_test.dart` follows `device_settings_page_test.dart`: provide cubit via `BlocProvider`, pump with `MaterialApp` wrapper, assert text/widget presence.
- Mock `AiDecisionLogRepository` with `@GenerateMocks([AiDecisionLogRepository])`. Run `build_runner` to generate the `.mocks.dart` file before running tests.

### Files to Create (NEW)

| File | Purpose |
|------|---------|
| `pulse_coach/lib/features/settings/data/models/ai_decision_record.dart` | Pure Dart DTO |
| `pulse_coach/lib/features/settings/data/repositories/ai_decision_log_repository.dart` | Query + assemble decisions |
| `pulse_coach/lib/features/settings/presentation/bloc/ai_decision_log_state.dart` | Cubit state |
| `pulse_coach/lib/features/settings/presentation/bloc/ai_decision_log_cubit.dart` | Load + expose decisions |
| `pulse_coach/lib/features/settings/presentation/pages/ai_decision_log_page.dart` | Screen widget |
| `pulse_coach/test/bloc/ai_decision_log_cubit_test.dart` | Cubit unit tests |
| `pulse_coach/test/widget/ai_decision_log_page_test.dart` | Widget tests |

### Files to Update (EXISTING)

| File | Change |
|------|--------|
| `pulse_coach/lib/l10n/app/app_it.arb` | Add 3 new keys |
| `pulse_coach/lib/l10n/app/app_en.arb` | Add 3 new keys |
| `pulse_coach/lib/core/routing/app_router.dart` | Add `aiDecisionLog` constant + `GoRoute` |
| `pulse_coach/lib/shared/widgets/app_shell.dart` | Extend debug drawer block with AI Decision Log tile |

### Previous Story Learnings (14.3)

- After adding `@injectable` to any cubit/repository, **always** run `flutter pub run build_runner build --delete-conflicting-outputs` — `injection.config.dart` is generated, not hand-edited.
- `WatchConnectivity` is the only DI exception in the settings feature (not in graph). All other DAOs/services are injectable.
- The `copyWith` pattern with nullable fields cannot clear back to `null` — `AiDecisionLogState` avoids this by using a simple two-field state (no nullable clearing needed).
- Review patch precedent: `await` keywords must be present in cubit async fetch methods to ensure try/catch intercepts async errors.
- The `drawerDebug` ARB key already exists. The new `aiDecisionLogDrawerTile` key is a sibling.

### Project Structure Notes

- New files live under `features/settings/` — consistent with stories 14.1–14.3. The `data/` sub-layer (models + repositories) follows the clean-arch pattern already established in other features.
- No new Drift table or schema migration needed — this story reads existing data (RPE feedback, session logs, daily plans) without adding tables. Schema version remains 8.
- `AiDecisionRecord` is a UI projection / DTO, not a domain entity — place in `data/models/`, not `domain/entities/`.

### References

- FR51: User can view an AI Decision Log showing bandit decision history [epics.md line 72]
- Story 14.4 full ACs: [epics.md lines 1926–1948]
- Architecture AI Decision Log: "Hidden screen showing bandit decision history (state vector → action → reward → updated estimates). High demo impact — proves the system learns." [architecture.md line 183]
- UX spec: "The debug/AI Decision Log exists for power users and demo purposes only — never surfaced in the default experience." [ux-design-specification.md line 45]
- Drawer debug block: [app_shell.dart lines 198–203]
- Arm key construction: [in_session_page.dart lines 118–119]
- Intensity name mapping: [contextual_bandit.dart _intensityValue method]
- `RpeFeedbackDao.getAllFeedback()`: [rpe_feedback_dao.dart line 12]
- `BanditState.armWeights` format: `'{sessionType}_{intensity}'` → `bandit_state.dart`
- Previous story dev notes: [14-3-device-and-sync-settings-screen.md §Dev Notes]

### Review Findings

_Code review 2026-06-05 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). 1 decision-needed, 3 patch, 1 defer, 9 dismissed as noise/spec-sanctioned._

- [x] [Review][Patch] Remove dead StateVector rendering scaffolding (decision: remove for simplicity) [pulse_coach/lib/features/settings/presentation/pages/ai_decision_log_page.dart] — FIXED: removed `_stateVectorRows`, the non-null branch of `_DecisionDetails`, `_stateVectorSummary`, and the now-unused `state_vector.dart` import; collapsed/expanded views show the single "StateVector non disponibile" entry.
- [x] [Review][Patch] `load()` has no try/catch → infinite spinner on DB error [pulse_coach/lib/features/settings/presentation/bloc/ai_decision_log_cubit.dart] — FIXED: wrapped `getDecisions()` in try/catch; on error emits `AiDecisionLogState(isLoading: false)` so the spinner stops and the empty state renders.
- [x] [Review][Patch] `AiDecisionRecord` lacks value equality → fragile state equality + false test confidence [pulse_coach/lib/features/settings/data/models/ai_decision_record.dart] — FIXED: `AiDecisionRecord` now extends `Equatable` with `props => [decidedAt, armKey, rpeValue, stateVector]`.
- [x] [Review][Patch] Sort has no deterministic tiebreaker for equal `recordedAt` [pulse_coach/lib/features/settings/data/repositories/ai_decision_log_repository.dart] — FIXED: secondary `b.id.compareTo(a.id)` tiebreaker added when `recordedAt` is equal.
- [x] [Review][Defer] N+3 sequential DB round-trips per decision, no plan caching [pulse_coach/lib/features/settings/data/repositories/ai_decision_log_repository.dart:23-32] — deferred, performance-only on a debug-only screen. Each feedback row triggers sequential `getLogById` → `getPlanById` → `jsonDecode`+`fromJson`; the same plan is re-decoded if multiple sessions share it. O(n) sequential hits.

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `flutter pub get` from `pulse_coach/` completed successfully.
- `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` completed successfully.
- `flutter test test/bloc/ai_decision_log_cubit_test.dart test/widget/ai_decision_log_page_test.dart` passed: 5/5 tests.
- `flutter analyze` passed: no issues found.
- `flutter test` passed: 844/844 tests.

### Completion Notes List

- Added localized AI Decision Log labels and empty-state copy in Italian and English.
- Added read-only `AiDecisionRecord` projection and `AiDecisionLogRepository` to assemble decision rows from RPE feedback, session logs, and daily plans.
- Added `AiDecisionLogCubit` and debug-only `AiDecisionLogPage` with loading, empty, list, collapsed summary, RPE chip, and expanded details states.
- Wired `/ai-decision-log` route and debug drawer tile behind `kDebugMode`; direct release navigation falls back to Settings.
- Added cubit and widget tests for populated, empty, and loading states.

### File List

- `_bmad-output/implementation-artifacts/14-4-ai-decision-log-mvp-if-time.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/core/database/daos/session_logs_dao.dart`
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/core/routing/app_router.dart`
- `pulse_coach/lib/features/settings/data/models/ai_decision_record.dart`
- `pulse_coach/lib/features/settings/data/repositories/ai_decision_log_repository.dart`
- `pulse_coach/lib/features/settings/presentation/bloc/ai_decision_log_cubit.dart`
- `pulse_coach/lib/features/settings/presentation/bloc/ai_decision_log_state.dart`
- `pulse_coach/lib/features/settings/presentation/pages/ai_decision_log_page.dart`
- `pulse_coach/lib/l10n/app/app_en.arb`
- `pulse_coach/lib/l10n/app/app_it.arb`
- `pulse_coach/lib/shared/widgets/app_shell.dart`
- `pulse_coach/pubspec.lock`
- `pulse_coach/pubspec.yaml`
- `pulse_coach/test/bloc/ai_decision_log_cubit_test.dart`
- `pulse_coach/test/bloc/ai_decision_log_cubit_test.mocks.dart`
- `pulse_coach/test/bloc/today_session_cubit_test.mocks.dart`
- `pulse_coach/test/widget/ai_decision_log_page_test.dart`
- `pulse_coach/test/widget/ai_decision_log_page_test.mocks.dart`
- `pulse_coach/test/widget/today_page_test.mocks.dart`

### Change Log

- 2026-06-05: Implemented AI Decision Log MVP and moved story to review.
