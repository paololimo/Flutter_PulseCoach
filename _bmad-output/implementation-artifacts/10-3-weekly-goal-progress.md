# Story 10.3: Weekly Goal Progress

Status: done

## Story

As a user,
I want to see how many sessions I've completed vs my weekly target,
so that I have a simple sense of whether I'm on track this week.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The user views the Progress screen | When it renders | A weekly goal indicator shows "X di Y sessioni questa settimana" with a `LinearProgressIndicator` (FR31) — visible above the TabBar regardless of which tab is active |
| AC2 | The user has completed 0 sessions this week | When the indicator renders | It shows "0 di 3 sessioni questa settimana" and an encouraging message "Inizia la tua prima sessione questa settimana!" |
| AC3 | The user has completed 3 of 3 sessions this week | When the indicator renders | The progress bar is fully filled in `colorScheme.primary` and the label shows "3 di 3 sessioni questa settimana" |
| AC4 | The weekly target (Y) | In all states | Y is always **3** (the AI initial session count cap from FR12) — no schema change; no user-configurable field |
| AC5 | X (completed this week) | When computed | Only non-abandoned session logs whose `completedAt` falls in the current ISO week (Monday 00:00 UTC → Sunday 23:59 UTC) are counted |
| AC6 | The `ProgressStats` entity carries the weekly data | After the story is implemented | `ProgressStats` has two new required fields: `completedThisWeek: int` and `weeklyTarget: int` — `ProgressLocalDataSource.getProgressStats()` populates them; all existing callers of the `ProgressStats(...)` constructor are updated |
| AC7 | The indicator at 360dp | When rendered at phone width | No overflow — tested by `10.3-WIDGET-001` using `set360dpSurface()` |
| AC8 | Epic 10 is read-side only (E8-P3 invariant) | In this story | No new Drift tables or columns — `app_database.dart` is NOT modified; the weekly count is derived from existing `session_logs` rows |

## Tasks / Subtasks

---

### Task 1: Extend `ProgressStats` entity with weekly fields (AC4, AC6)

- [x] READ `pulse_coach/lib/features/progress/domain/entities/progress_stats.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/features/progress/domain/entities/progress_stats.dart`

  Add two required fields to the `ProgressStats` factory:

  ```dart
  @freezed
  abstract class ProgressStats with _$ProgressStats {
    const factory ProgressStats({
      /// Completed (not abandoned) sessions.
      required int completedCount,

      /// Abandoned sessions.
      required int abandonedCount,

      /// Last <= 8 ISO weeks, oldest first.
      required List<WeeklyMinutes> minutesPerWeek,

      /// Last <= 20 sessions with RPE, oldest first.
      required List<RpeDataPoint> rpeTrend,

      /// Session type counts, e.g. {'mobility': 5, 'cardio': 3}.
      required Map<String, int> sessionTypeCounts,

      /// Non-abandoned sessions completed in the current ISO week (Mon–Sun).
      required int completedThisWeek,

      /// Always 3 — the AI initial session-count cap (FR12). Not user-configurable.
      required int weeklyTarget,
    }) = _ProgressStats;
  }
  ```

  After editing, run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` to regenerate `progress_stats.freezed.dart`.

---

### Task 2: Update `ProgressLocalDataSource.getProgressStats()` (AC5, AC6, AC8)

- [x] READ `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart`

  **Empty path:** update the early-return `ProgressStats` to include the two new required fields:
  ```dart
  return const ProgressStats(
    completedCount: 0,
    abandonedCount: 0,
    minutesPerWeek: [],
    rpeTrend: [],
    sessionTypeCounts: {},
    completedThisWeek: 0,
    weeklyTarget: 3,
  );
  ```

  **Populated path:** add the weekly count computation **before** the final `return ProgressStats(...)`:
  ```dart
  // ── Sessions completed in the current ISO week ──
  final now = DateTime.now().toUtc();
  final weekStart = _mondayOf(now);
  final weekEnd = weekStart.add(const Duration(days: 7));
  final completedThisWeek = completed
      .where(
        (e) =>
            !e.abandoned &&
            e.completedAt.toUtc().isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            e.completedAt.toUtc().isBefore(weekEnd),
      )
      .length;
  ```

  Update the final `return ProgressStats(...)` to include the two new fields:
  ```dart
  return ProgressStats(
    completedCount: completed.length,
    abandonedCount: abandoned.length,
    minutesPerWeek: minutesPerWeek,
    rpeTrend: rpePoints,
    sessionTypeCounts: typeCounts,
    completedThisWeek: completedThisWeek,
    weeklyTarget: 3,
  );
  ```

  **No other changes** — `_mondayOf()` helper already exists and is reused here.

---

### Task 3: Fix all callers of `ProgressStats(...)` that break after Task 1 (AC6)

After adding required fields to `ProgressStats`, the compiler will flag these existing call sites. Update every one:

- [x] `pulse_coach/test/data/progress/progress_stats_data_source_test.dart` — any inline `ProgressStats(...)` construction needs `completedThisWeek: 0, weeklyTarget: 3` added.
- [x] `pulse_coach/test/bloc/progress_stats_cubit_test.dart` — the `_emptyStats()` helper at the bottom needs `completedThisWeek: 0, weeklyTarget: 3` added:
  ```dart
  ProgressStats _emptyStats() => const ProgressStats(
        completedCount: 0,
        abandonedCount: 0,
        minutesPerWeek: [],
        rpeTrend: [],
        sessionTypeCounts: {},
        completedThisWeek: 0,
        weeklyTarget: 3,
      );
  ```
- [x] Any other test or source file that constructs `ProgressStats(...)` directly — search with `grep -rn "ProgressStats(" pulse_coach/ --include="*.dart"` and fix each one.

---

### Task 4: Create `WeeklyGoalIndicator` widget (AC1, AC2, AC3, AC7)

- [x] CREATE `pulse_coach/lib/features/progress/presentation/widgets/weekly_goal_indicator.dart`

  ```dart
  import 'package:flutter/material.dart';

  class WeeklyGoalIndicator extends StatelessWidget {
    const WeeklyGoalIndicator({
      super.key,
      required this.completedThisWeek,
      required this.weeklyTarget,
    });

    final int completedThisWeek;
    final int weeklyTarget;

    @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;
      final progress = weeklyTarget > 0
          ? (completedThisWeek / weeklyTarget).clamp(0.0, 1.0)
          : 0.0;
      final isComplete = completedThisWeek >= weeklyTarget;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$completedThisWeek di $weeklyTarget sessioni questa settimana',
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            if (completedThisWeek == 0) ...[
              const SizedBox(height: 6),
              Text(
                'Inizia la tua prima sessione questa settimana!',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (isComplete) ...[
              const SizedBox(height: 6),
              Text(
                'Obiettivo raggiunto!',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }
  ```

---

### Task 5: Integrate `WeeklyGoalIndicator` into `ProgressPage` (AC1, AC2, AC3)

- [x] READ `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart`

  Add the import for `WeeklyGoalIndicator`:
  ```dart
  import 'package:pulse_coach/features/progress/presentation/widgets/weekly_goal_indicator.dart';
  ```

  In `_ProgressView.build()`, insert the `WeeklyGoalIndicator` above the `TabBar`. It reads from `ProgressStatsCubit` which is already provided by the parent `ProgressPage`. The indicator shows a shimmer row while loading, then the real indicator once loaded:

  Replace `_ProgressView` body:
  ```dart
  class _ProgressView extends StatelessWidget {
    const _ProgressView();

    @override
    Widget build(BuildContext context) {
      return Column(
        children: [
          BlocBuilder<ProgressStatsCubit, ProgressStatsState>(
            builder: (context, state) {
              if (state is ProgressStatsLoaded) {
                return WeeklyGoalIndicator(
                  completedThisWeek: state.stats.completedThisWeek,
                  weeklyTarget: state.stats.weeklyTarget,
                );
              }
              // Loading / initial / error: compact shimmer row
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ShimmerPlaceholder(height: 56),
              );
            },
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Cronologia'),
              Tab(text: 'Grafici'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [_HistoryTab(), _ChartsTab()],
            ),
          ),
        ],
      );
    }
  }
  ```

  **File size check**: after this edit the file should be well under 400 lines. No split required.

---

### Task 6: Write tests (AC1–AC8)

#### 6a: Data source test — weekly count computation

- [x] UPDATE `pulse_coach/test/data/progress/progress_stats_data_source_test.dart`

  Add to the existing `group('ProgressLocalDataSource.getProgressStats', ...)` block. Also fix any existing `ProgressStats(...)` construction (Task 3):

  ```dart
  test('10.3-DATA-001: completedThisWeek counts only non-abandoned logs in current ISO week', () async {
    // Insert: 1 completed today, 1 completed last Monday (previous week), 1 abandoned today
    // Expected: completedThisWeek == 1
  });

  test('10.3-DATA-002: completedThisWeek is 0 when no sessions this week', () async {
    // Insert: 1 completed session from 14 days ago
    // Expected: completedThisWeek == 0
  });

  test('10.3-DATA-003: weeklyTarget is always 3', () async {
    final result = await dataSource.getProgressStats();
    expect(result.weeklyTarget, 3);
  });
  ```

  **Important:** these tests involve `DateTime.now()` for the current week boundary. When inserting test rows, compute the Monday of the current week the same way as `_mondayOf(DateTime.now())` — use `DateTime(year, month, day)` to construct date-only values. See the existing week-grouping tests (10.2-DATA-004 / 10.2-DATA-005) for the test helper pattern.

#### 6b: Widget test — `WeeklyGoalIndicator`

- [x] CREATE `pulse_coach/test/widget/progress/weekly_goal_indicator_test.dart`

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/weekly_goal_indicator.dart';
  import '../../helpers/viewport_helper.dart';

  Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  void main() {
    group('WeeklyGoalIndicator', () {
      testWidgets('10.3-WIDGET-001: renders without overflow at 360dp', (tester) async {
        set360dpSurface(tester);
        await tester.pumpWidget(
          _wrap(const WeeklyGoalIndicator(completedThisWeek: 1, weeklyTarget: 3)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('10.3-WIDGET-002: shows correct text for 1 of 3', (tester) async {
        await tester.pumpWidget(
          _wrap(const WeeklyGoalIndicator(completedThisWeek: 1, weeklyTarget: 3)),
        );
        await tester.pumpAndSettle();
        expect(find.text('1 di 3 sessioni questa settimana'), findsOneWidget);
      });

      testWidgets('10.3-WIDGET-003: shows encouraging text when 0 sessions', (tester) async {
        await tester.pumpWidget(
          _wrap(const WeeklyGoalIndicator(completedThisWeek: 0, weeklyTarget: 3)),
        );
        await tester.pumpAndSettle();
        expect(find.text('0 di 3 sessioni questa settimana'), findsOneWidget);
        expect(
          find.text('Inizia la tua prima sessione questa settimana!'),
          findsOneWidget,
        );
      });

      testWidgets('10.3-WIDGET-004: shows completion text when target met', (tester) async {
        await tester.pumpWidget(
          _wrap(const WeeklyGoalIndicator(completedThisWeek: 3, weeklyTarget: 3)),
        );
        await tester.pumpAndSettle();
        expect(find.text('3 di 3 sessioni questa settimana'), findsOneWidget);
        expect(find.text('Obiettivo raggiunto!'), findsOneWidget);
      });

      testWidgets('10.3-WIDGET-005: LinearProgressIndicator is present', (tester) async {
        await tester.pumpWidget(
          _wrap(const WeeklyGoalIndicator(completedThisWeek: 2, weeklyTarget: 3)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });
  }
  ```

---

### Task 7: Run `build_runner`, analyze, and test

- [x] From `pulse_coach/`, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected regenerated files:
  - `lib/features/progress/domain/entities/progress_stats.freezed.dart` (two new fields)

- [x] Run `flutter analyze` — expect 0 issues.
- [x] Run `flutter test` — expect all 726 prior tests passing, plus new tests from Task 6.

---

### Review Findings

_Code review 2026-05-27 (bmad-code-review). Verified: 28/28 targeted tests pass, freezed regen consistent, all `ProgressStats(...)` call sites updated._

- [x] [Review][Decision][Resolved: accepted] `_mondayOf` converted to UTC — alters Story 10.2 `minutesPerWeek` bucketing on non-UTC devices and deviates from Task 2 ("No other changes — `_mondayOf()` helper already exists and is reused here") [pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart:168-171]. The helper now does `date.toUtc()` then `DateTime.utc(...)`; previously it used local `DateTime(...)`. The change is required for the new weekly comparison to be correct (the new `weekStart` is compared against `completedAt.toUtc()`) and aligns with the project's "DateTime UTC internally" rule. **Resolution (Paolo, 2026-05-27): accept the unified-UTC behavior.** Regression note: this shifts the 10.2 weekly-minutes chart buckets for non-UTC devices (e.g. an Italian user on CET/CEST: a session at Mon 00:30 local = Sun 22:30 UTC now buckets into the prior week). The previous local-time bucketing was a latent inconsistency with the project UTC rule; the new behavior is intentional and considered more correct. No dedicated non-UTC bucketing test was added.
- [x] [Review][Defer] Weekly indicator shows a perpetual shimmer on `ProgressStatsError` [pulse_coach/lib/features/progress/presentation/pages/progress_page.dart:44-57] — deferred, spec-sanctioned. The `BlocBuilder` only special-cases `ProgressStatsLoaded`; `ProgressStatsError` falls through to the shimmer branch, so a failed stats load shows an indefinite loading shimmer instead of an error/empty affordance. Task 5 explicitly directs "Loading / initial / error: compact shimmer row", so this is intentional, but perpetual-shimmer-on-error is a UX smell worth recording.

## Dev Notes

### Weekly target is a constant (not from profile or DB)

`UserProfile` has `fitnessLevel`, `goal`, `availableTime`, `physicalConstraints` — no "sessions per week" field. The epics explicitly state "3 sessions in a week" as the target, matching FR12's initial session-count cap. `weeklyTarget: 3` is a literal constant in `ProgressLocalDataSource.getProgressStats()`. If a future story introduces user-configurable session frequency, it will be added then.

### ISO week boundary computation

The current week is defined as: Monday 00:00 UTC (inclusive) through the following Monday 00:00 UTC (exclusive). `_mondayOf(DateTime.now().toUtc())` gives the Monday boundary. `completed.where(e => completedAt >= weekStart && completedAt < weekEnd)` is the correct filter. Both dates must be compared in UTC per the project rule ("always use DateTime UTC internally").

### `WeeklyGoalIndicator` placement: above the TabBar

The indicator is placed in `_ProgressView` above the `TabBar` (not inside either tab body). This makes it persistent — the user sees their weekly progress regardless of whether they are looking at history or charts. The `BlocBuilder<ProgressStatsCubit>` in `_ProgressView` is safe because `ProgressStatsCubit` is provided by the parent `ProgressPage.build()`.

### Shimmer during loading (AC1)

While `ProgressStatsCubit` is in `ProgressStatsInitial` or `ProgressStatsLoading` state, the indicator slot shows a 56dp `ShimmerPlaceholder`. This avoids a jarring empty gap before stats load, consistent with the project rule that async loading uses shimmer (never `CircularProgressIndicator`).

### No new Cubit / use case needed (AC8)

`ProgressStatsCubit` + `GetProgressStats` already exist (Story 10.2). The weekly data is computed inside `ProgressLocalDataSource.getProgressStats()` and carried in `ProgressStats`. No new Bloc or use case is required.

### `ProgressStats` is a freezed class — all callers must be updated

Adding required fields to a `@freezed` class breaks every existing `ProgressStats(...)` constructor call. Run `grep -rn "ProgressStats(" pulse_coach/ --include="*.dart"` to find all callers. The known locations are:
- `progress_local_data_source.dart` (two call sites — empty path and populated path)
- `progress_stats_cubit_test.dart` (`_emptyStats()` helper)
- `progress_stats_data_source_test.dart` (any inline construction)
- Possibly `progress_page_test.mocks.dart` — generated, no manual edit needed

Do NOT add `@Default` annotations — the fields are intentionally required so the compiler enforces completeness.

### `LinearProgressIndicator.borderRadius` — Flutter 3.19+ API

`LinearProgressIndicator` received a `borderRadius` parameter in Flutter 3.19. The project uses Flutter 3.41.x — safe to use.

### `colorScheme.surfaceContainerHighest`

Used for the progress bar background. Available from Flutter 3.22+ (M3 token). Same token already used in `CompletionRateChart` (Story 10.2) — consistent.

### Italian labels

All user-facing text in Italian (locale-locked to `it`):
- Progress label: `'$completedThisWeek di $weeklyTarget sessioni questa settimana'`
- Zero-session nudge: `'Inizia la tua prima sessione questa settimana!'`
- Completion: `'Obiettivo raggiunto!'`

Do NOT create ARB keys in this story (same rule as 10.1/10.2 — ARB wiring is E7.5-T1 scope, already closed; new strings go directly in widget for now, pending a future i18n story).

### Tone: empathy without guilt

Per UX spec ("Progress shaming is forbidden"). The "0 sessions" message is encouraging, not accusatory. "Inizia la tua prima sessione questa settimana!" frames it as an invitation, not a failure. "Obiettivo raggiunto!" is understated satisfaction — no badge noise, no confetti. This is deliberate.

### E8-P3 invariant: no schema changes

Epic 10 is read-side only. `app_database.dart` is NOT touched. The weekly count is derived from `session_logs.completed_at` + `session_logs.abandoned` — both columns already exist (Story 8.0). No `dart run build_runner build` is needed for DB schema, only for freezed (new fields in `ProgressStats`).

### File size check for `progress_page.dart`

The current `progress_page.dart` is 278 lines. After Task 5 adds the BlocBuilder (≈15 lines) and the import (1 line), it will be ≈294 lines — well within the 200–400 line guideline.

### References

- Epics.md Story 10.3: `_bmad-output/planning-artifacts/epics.md` lines 1622–1642
- PRD FR31: `_bmad-output/planning-artifacts/prd.md` line 584
- PRD FR12 (session count cap = 3): `_bmad-output/planning-artifacts/prd.md` line 567
- UX spec (empathy without guilt, anti-streak design): `_bmad-output/planning-artifacts/ux-design-specification.md` lines 51, 264
- Project context (DateTime UTC rule): `_bmad-output/project-context.md` line 39
- Previous story (10.2 — ProgressStats, ProgressStatsCubit, ProgressPage): `_bmad-output/implementation-artifacts/10-2-progress-charts.md`
- `ProgressStats` entity: `pulse_coach/lib/features/progress/domain/entities/progress_stats.dart`
- `ProgressLocalDataSource`: `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart`
- `ProgressStatsCubit` / `ProgressStatsState`: `pulse_coach/lib/features/progress/presentation/bloc/`
- `ProgressPage`: `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart`
- `ShimmerPlaceholder`: `pulse_coach/lib/shared/widgets/shimmer_placeholder.dart`
- `set360dpSurface` helper: `pulse_coach/test/helpers/viewport_helper.dart`
- Existing weekly count tests (10.2-DATA-004 pattern): `pulse_coach/test/data/progress/progress_stats_data_source_test.dart`
- Sprint status: `_bmad-output/implementation-artifacts/sprint-status.yaml`
- Action item ledger (Category A snapshot): `_bmad-output/implementation-artifacts/action-item-ledger.md`

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `flutter test test/data/progress/progress_stats_data_source_test.dart test/widget/progress/weekly_goal_indicator_test.dart test/widget/progress/progress_page_test.dart` failed during RED with missing `ProgressStats.completedThisWeek`, missing `ProgressStats.weeklyTarget`, and missing `WeeklyGoalIndicator`.
- `dart run build_runner build --delete-conflicting-outputs` passed and regenerated Freezed output for `ProgressStats`.
- `flutter test test/data/progress/progress_stats_data_source_test.dart test/widget/progress/weekly_goal_indicator_test.dart test/widget/progress/progress_page_test.dart test/bloc/progress_stats_cubit_test.dart` passed.
- `flutter analyze` passed with 0 issues.
- `flutter test` passed with 735 tests.

### Completion Notes List

- Added required weekly progress fields to `ProgressStats` and regenerated Freezed code.
- Computed `completedThisWeek` from existing session logs only, using non-abandoned completions in the current UTC ISO week and a fixed `weeklyTarget` of 3.
- Added `WeeklyGoalIndicator` and mounted it above the Progress tab bar with shimmer fallback while stats load.
- Added data, widget, and ProgressPage coverage for weekly counts, fixed target, 360dp rendering, progress label states, and persistent indicator placement across tabs.

### File List

- `_bmad-output/implementation-artifacts/10-3-weekly-goal-progress.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart`
- `pulse_coach/lib/features/progress/domain/entities/progress_stats.dart`
- `pulse_coach/lib/features/progress/domain/entities/progress_stats.freezed.dart`
- `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart`
- `pulse_coach/lib/features/progress/presentation/widgets/weekly_goal_indicator.dart`
- `pulse_coach/test/bloc/progress_stats_cubit_test.dart`
- `pulse_coach/test/data/progress/progress_stats_data_source_test.dart`
- `pulse_coach/test/widget/app_shell_test.dart`
- `pulse_coach/test/widget/pages_smoke_test.dart`
- `pulse_coach/test/widget/progress/progress_page_test.dart`
- `pulse_coach/test/widget/progress/weekly_goal_indicator_test.dart`

### Change Log

- 2026-05-27: Implemented weekly goal progress indicator and read-side weekly count projection for Story 10.3.
