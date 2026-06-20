# Story 10.2: Progress Charts

Status: done

## Story

As a user,
I want to see animated charts of my key metrics (minutes/week, completion rate, RPE trend, session type breakdown),
so that I can understand my progress at a glance without interpreting raw data.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The user views the Progress screen charts tab | When the charts render with ≥ 3 sessions | 4 charts are displayed using `fl_chart`: (a) minutes per week (BarChart), (b) completion rate (PieChart donut), (c) RPE trend over time (LineChart), (d) session type breakdown (PieChart donut) — satisfying FR30, UX-DR19 |
| AC2 | The charts render for the first time | When they animate in | Each chart has a 250ms ease-in-out entry animation via `duration: const Duration(milliseconds: 250)` + `curve: Curves.easeInOut` (fl_chart 1.2 API, constructor args on the chart widget) on every fl_chart widget (FR32, UX-DR18). _(Updated 2026-05-26 by code review DN1: the original `swapAnimationDuration`/`swapAnimationCurve` properties are deprecated/removed in fl_chart 1.2; the 1.2 `duration`/`curve` args preserve the same 250ms ease-in-out behavior.)_ |
| AC3 | New session data arrives (after completing a session) | When the user revisits the charts tab | The charts animate smoothly to the new data (cubit factory lifecycle ensures a fresh `loadStats()` on each tab entry — no instant jump) |
| AC4 | Insufficient data exists (`completedCount + abandonedCount < 3`) | When the charts tab renders | The entire charts tab shows a centered placeholder text ("Completa più sessioni per vedere i tuoi progressi") — no individual chart renders |
| AC5 | The E7-T2 viewport/golden test infra is established in this story | When the chart layout tests run | The test suite asserts all 4 charts render without overflow at a **360dp** surface (`Size(360, 800)`) — closing E7-T2 and the layout-blindness class of bug from `9.1-WIDGET-005`. A reusable helper `set360dpSurface(WidgetTester)` in `test/helpers/viewport_helper.dart` is used across all 360dp layout assertions |
| AC6 | `fl_chart` is in `pubspec.yaml` at `^1.0.0` (resolved to ≥ 1.2) | When this story is implemented | The decision is recorded: **USE** `fl_chart`. All 4 charts are imported and rendered via `fl_chart`; no alternative or prune |
| AC7 | The cubit lifecycle (E8-P1 invariant) | When `ProgressStatsCubit.close()` is called before `loadStats()` completes | The cubit does NOT emit after close — every emit is guarded by `if (!isClosed)` |
| AC8 | The charts tab is loading (initial fetch in progress) | When inspected | Three `ShimmerPlaceholder` rows (height 200 each) are displayed, not the real charts |

## Tasks / Subtasks

---

### Task 1: Create `ProgressStats` domain entity (AC1, AC4)

- [x] CREATE `pulse_coach/lib/features/progress/domain/entities/progress_stats.dart`

  All three types in one file, one `part` declaration:

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'progress_stats.freezed.dart';

  /// One ISO-week bucket for the minutes-per-week bar chart.
  @freezed
  abstract class WeeklyMinutes with _$WeeklyMinutes {
    const factory WeeklyMinutes({
      /// Human-readable label, e.g. '03/06' (Monday date of that week DD/MM).
      required String weekLabel,
      required int totalMinutes,
    }) = _WeeklyMinutes;
  }

  /// One RPE observation for the RPE trend line chart.
  @freezed
  abstract class RpeDataPoint with _$RpeDataPoint {
    const factory RpeDataPoint({
      required DateTime completedAt,
      required int rpeValue,
    }) = _RpeDataPoint;
  }

  /// Aggregated stats for the Progress charts tab.
  ///
  /// Assembled by [ProgressLocalDataSource.getProgressStats] from
  /// session_logs + daily_plans + rpe_feedback. Never persisted; pure
  /// read-side projection.
  @freezed
  abstract class ProgressStats with _$ProgressStats {
    const factory ProgressStats({
      /// Completed (not abandoned) sessions.
      required int completedCount,
      /// Abandoned sessions.
      required int abandonedCount,
      /// Last ≤ 8 ISO weeks, oldest first. Weeks with 0 minutes are included
      /// only if they fall between the first and last session dates.
      required List<WeeklyMinutes> minutesPerWeek,
      /// Last ≤ 20 sessions with RPE, oldest first. Abandoned sessions (no RPE)
      /// are excluded.
      required List<RpeDataPoint> rpeTrend,
      /// Session type counts, e.g. {'mobility': 5, 'cardio': 3, 'breathing': 2}.
      /// Types with count 0 are omitted.
      required Map<String, int> sessionTypeCounts,
    }) = _ProgressStats;
  }
  ```

  After creating this file run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` to generate `progress_stats.freezed.dart`.

---

### Task 2: Add `getProgressStats()` to `ProgressRepository` interface (AC1)

- [x] READ `pulse_coach/lib/features/progress/domain/repositories/progress_repository.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/features/progress/domain/repositories/progress_repository.dart`

  Add the new contract method (keep `getSessionHistory` unchanged):

  ```dart
  import 'package:dartz/dartz.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
  import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

  abstract class ProgressRepository {
    Future<Either<Failure, List<SessionHistoryEntry>>> getSessionHistory();
    Future<Either<Failure, ProgressStats>> getProgressStats();
  }
  ```

---

### Task 3: Create `GetProgressStats` use case (AC1)

- [x] CREATE `pulse_coach/lib/features/progress/domain/usecases/get_progress_stats.dart`

  ```dart
  import 'package:dartz/dartz.dart';
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
  import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';

  @lazySingleton
  class GetProgressStats {
    const GetProgressStats(this._repository);

    final ProgressRepository _repository;

    Future<Either<Failure, ProgressStats>> call() =>
        _repository.getProgressStats();
  }
  ```

---

### Task 4: Add `getProgressStats()` to `ProgressLocalDataSource` (AC1, AC4)

- [x] READ `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart`

  Add the new method **below** the existing `getSessionHistory()`. Do NOT modify the existing method.

  ```dart
  Future<ProgressStats> getProgressStats() async {
    final entries = await getSessionHistory();

    if (entries.isEmpty) {
      return const ProgressStats(
        completedCount: 0,
        abandonedCount: 0,
        minutesPerWeek: [],
        rpeTrend: [],
        sessionTypeCounts: {},
      );
    }

    final completed = entries.where((e) => !e.abandoned).toList();
    final abandoned = entries.where((e) => e.abandoned).toList();

    // ── RPE trend (last 20 completed sessions with RPE, oldest first) ──
    final rpePoints = completed
        .where((e) => e.rpeValue != null)
        .take(20)
        .map((e) => RpeDataPoint(completedAt: e.completedAt, rpeValue: e.rpeValue!))
        .toList()
        .reversed
        .toList();

    // ── Session type counts (all sessions incl. abandoned) ──
    final typeCounts = <String, int>{};
    for (final e in entries) {
      typeCounts[e.sessionType] = (typeCounts[e.sessionType] ?? 0) + 1;
    }

    // ── Minutes per week (last 8 ISO weeks, oldest first) ──
    // Week key: Monday date as yyyy-MM-dd string for grouping.
    final weekMinutes = <String, int>{};
    final weekLabels = <String, String>{};

    for (final e in entries) {
      final weekStart = _mondayOf(e.completedAt);
      final weekKey = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      final minutes = e.abandoned
          ? (e.elapsedSeconds ?? 0) ~/ 60
          : e.durationMinutes;
      weekMinutes[weekKey] = (weekMinutes[weekKey] ?? 0) + minutes;
      weekLabels[weekKey] = '${weekStart.day.toString().padLeft(2, '0')}/${weekStart.month.toString().padLeft(2, '0')}';
    }

    // Sort week keys ascending (oldest first), keep last 8.
    final sortedKeys = weekMinutes.keys.toList()..sort();
    final last8 = sortedKeys.length > 8 ? sortedKeys.sublist(sortedKeys.length - 8) : sortedKeys;

    final minutesPerWeek = last8
        .map((k) => WeeklyMinutes(weekLabel: weekLabels[k]!, totalMinutes: weekMinutes[k]!))
        .toList();

    return ProgressStats(
      completedCount: completed.length,
      abandonedCount: abandoned.length,
      minutesPerWeek: minutesPerWeek,
      rpeTrend: rpePoints,
      sessionTypeCounts: typeCounts,
    );
  }

  // Returns the Monday (start of ISO week) for [date].
  DateTime _mondayOf(DateTime date) {
    final weekday = date.weekday; // 1=Mon, 7=Sun
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }
  ```

  **Import additions needed at the top of the file:**
  ```dart
  import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
  ```

---

### Task 5: Add `getProgressStats()` to `ProgressRepositoryImpl` (AC1)

- [x] READ `pulse_coach/lib/features/progress/data/repositories/progress_repository_impl.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/features/progress/data/repositories/progress_repository_impl.dart`

  Add the new method override **below** the existing `getSessionHistory()` implementation:

  ```dart
  @override
  Future<Either<Failure, ProgressStats>> getProgressStats() async {
    try {
      final stats = await _dataSource.getProgressStats();
      return Right(stats);
    } catch (e, st) {
      AppLogger.error(
        'getProgressStats failed',
        name: 'ProgressRepositoryImpl',
        error: e,
        stackTrace: st,
      );
      return const Left(CacheFailure('progress_stats_load_failed'));
    }
  }
  ```

  **Import addition:**
  ```dart
  import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
  ```

---

### Task 6: Create `ProgressStatsState` sealed class (AC1, AC4, AC7, AC8)

- [x] CREATE `pulse_coach/lib/features/progress/presentation/bloc/progress_stats_state.dart`

  Following the same sealed-class pattern as `progress_state.dart`:

  ```dart
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';

  sealed class ProgressStatsState {
    const ProgressStatsState();
  }

  class ProgressStatsInitial extends ProgressStatsState {
    const ProgressStatsInitial();
  }

  class ProgressStatsLoading extends ProgressStatsState {
    const ProgressStatsLoading();
  }

  class ProgressStatsLoaded extends ProgressStatsState {
    const ProgressStatsLoaded(this.stats);
    final ProgressStats stats;
  }

  class ProgressStatsError extends ProgressStatsState {
    const ProgressStatsError(this.failure);
    final Failure failure;
  }
  ```

---

### Task 7: Create `ProgressStatsCubit` (AC1, AC7)

- [x] CREATE `pulse_coach/lib/features/progress/presentation/bloc/progress_stats_cubit.dart`

  ```dart
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/logging/app_logger.dart';
  import 'package:pulse_coach/features/progress/domain/usecases/get_progress_stats.dart';
  import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_state.dart';

  // Factory (not singleton): ProgressPage provides this via BlocProvider(create:),
  // which closes the cubit when the Progress tab is disposed. Mirrors the @injectable
  // lifecycle of ProgressCubit (same rationale — singleton would be reused closed).
  @injectable
  class ProgressStatsCubit extends Cubit<ProgressStatsState> {
    ProgressStatsCubit(this._getProgressStats) : super(const ProgressStatsInitial());

    final GetProgressStats _getProgressStats;

    Future<void> load() async {
      if (!isClosed) emit(const ProgressStatsLoading());

      final result = await _getProgressStats();

      result.fold(
        (failure) {
          AppLogger.error(
            'getProgressStats failed: ${failure.message}',
            name: 'ProgressStatsCubit',
          );
          if (!isClosed) emit(ProgressStatsError(failure));
        },
        (stats) {
          if (!isClosed) emit(ProgressStatsLoaded(stats));
        },
      );
    }
  }
  ```

---

### Task 8: Create the 4 chart widgets (AC1, AC2, AC5)

Each chart widget is a pure `StatelessWidget` — receives pre-computed data from `ProgressStats` and renders a bounded `fl_chart` widget. All use `duration: const Duration(milliseconds: 250)` and `curve: Curves.easeInOut` (fl_chart 1.2 constructor args) for the entry animation (AC2). _(Updated 2026-05-26 by code review DN1 — see AC2 note; the `swapAnimation*` properties shown in the code snippets below are the deprecated 0.x API and were implemented with the 1.2 equivalents.)_

#### 8a: `MinutesPerWeekChart`

- [x] CREATE `pulse_coach/lib/features/progress/presentation/widgets/minutes_per_week_chart.dart`

  ```dart
  import 'package:fl_chart/fl_chart.dart';
  import 'package:flutter/material.dart';
  import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';

  class MinutesPerWeekChart extends StatelessWidget {
    const MinutesPerWeekChart({super.key, required this.minutesPerWeek});

    final List<WeeklyMinutes> minutesPerWeek;

    @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;

      final barGroups = <BarChartGroupData>[];
      for (var i = 0; i < minutesPerWeek.length; i++) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: minutesPerWeek[i].totalMinutes.toDouble(),
                color: colorScheme.primary,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        );
      }

      return BarChart(
        BarChartData(
          barGroups: barGroups,
          swapAnimationDuration: const Duration(milliseconds: 250),
          swapAnimationCurve: Curves.easeInOut,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= minutesPerWeek.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    minutesPerWeek[index].weekLabel,
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                reservedSize: 24,
              ),
            ),
          ),
        ),
      );
    }
  }
  ```

#### 8b: `CompletionRateChart`

- [x] CREATE `pulse_coach/lib/features/progress/presentation/widgets/completion_rate_chart.dart`

  ```dart
  import 'package:fl_chart/fl_chart.dart';
  import 'package:flutter/material.dart';

  class CompletionRateChart extends StatelessWidget {
    const CompletionRateChart({
      super.key,
      required this.completedCount,
      required this.abandonedCount,
    });

    final int completedCount;
    final int abandonedCount;

    @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;
      final total = completedCount + abandonedCount;
      final completionPct = total > 0 ? (completedCount / total * 100) : 0.0;

      return Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 60,
              swapAnimationDuration: const Duration(milliseconds: 250),
              swapAnimationCurve: Curves.easeInOut,
              sections: [
                PieChartSectionData(
                  value: completedCount.toDouble(),
                  color: colorScheme.primary,
                  radius: 24,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: abandonedCount.toDouble(),
                  color: colorScheme.surfaceContainerHighest,
                  radius: 24,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Text(
            '${completionPct.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
        ],
      );
    }
  }
  ```

#### 8c: `RpeTrendChart`

- [x] CREATE `pulse_coach/lib/features/progress/presentation/widgets/rpe_trend_chart.dart`

  ```dart
  import 'package:fl_chart/fl_chart.dart';
  import 'package:flutter/material.dart';
  import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';

  class RpeTrendChart extends StatelessWidget {
    const RpeTrendChart({super.key, required this.rpeTrend});

    final List<RpeDataPoint> rpeTrend;

    @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;

      final spots = <FlSpot>[];
      for (var i = 0; i < rpeTrend.length; i++) {
        spots.add(FlSpot(i.toDouble(), rpeTrend[i].rpeValue.toDouble()));
      }

      return LineChart(
        LineChartData(
          swapAnimationDuration: const Duration(milliseconds: 250),
          swapAnimationCurve: Curves.easeInOut,
          minY: 0,
          maxY: 10,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 2,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: colorScheme.secondary,
              barWidth: 2,
              dotData: FlDotData(
                getDotPainter: (spot, pct, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: colorScheme.secondary,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.secondary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      );
    }
  }
  ```

#### 8d: `SessionTypeBreakdownChart`

- [x] CREATE `pulse_coach/lib/features/progress/presentation/widgets/session_type_breakdown_chart.dart`

  ```dart
  import 'package:fl_chart/fl_chart.dart';
  import 'package:flutter/material.dart';

  class SessionTypeBreakdownChart extends StatelessWidget {
    const SessionTypeBreakdownChart({super.key, required this.sessionTypeCounts});

    final Map<String, int> sessionTypeCounts;

    static const _typeColors = {
      'mobility': Color(0xFF7DD3C0),   // primary aqua green
      'cardio': Color(0xFFA78BDA),     // secondary purple
      'breathing': Color(0xFFE8C87A),  // tertiary gold
    };

    static const _typeLabels = {
      'mobility': 'Mobilità',
      'cardio': 'Cardio',
      'breathing': 'Respirazione',
    };

    @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;
      final total = sessionTypeCounts.values.fold(0, (a, b) => a + b);

      final sections = <PieChartSectionData>[];
      sessionTypeCounts.forEach((type, count) {
        final pct = total > 0 ? count / total * 100 : 0.0;
        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            color: _typeColors[type] ?? colorScheme.onSurface,
            radius: 48,
            title: '${pct.toStringAsFixed(0)}%',
            titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
          ),
        );
      });

      return Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                swapAnimationDuration: const Duration(milliseconds: 250),
                swapAnimationCurve: Curves.easeInOut,
                sections: sections,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sessionTypeCounts.keys.map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _typeColors[type] ?? colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _typeLabels[type] ?? type,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
        ],
      );
    }
  }
  ```

---

### Task 9: Update `ProgressPage` — add tabs and wire `ProgressStatsCubit` (AC1, AC4, AC8)

- [x] READ `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart`

  Replace the full file. The page now uses `MultiBlocProvider` + `DefaultTabController` + two tabs ("Cronologia" and "Grafici"). All existing history UI classes (`_HistoryShimmer`, `_EmptyState`, `_HistoryList`, `_ErrorState`) move into `_HistoryTab`. New chart UI is in `_ChartsTab` and `_ChartsDashboard`.

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:pulse_coach/core/di/injection.dart';
  import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
  import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
  import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart';
  import 'package:pulse_coach/features/progress/presentation/bloc/progress_state.dart';
  import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_cubit.dart';
  import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_state.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/completion_rate_chart.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/minutes_per_week_chart.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/rpe_trend_chart.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/session_history_tile.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/session_type_breakdown_chart.dart';
  import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

  class ProgressPage extends StatelessWidget {
    const ProgressPage({super.key});

    @override
    Widget build(BuildContext context) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<ProgressCubit>(
            create: (_) => getIt<ProgressCubit>()..load(),
          ),
          BlocProvider<ProgressStatsCubit>(
            create: (_) => getIt<ProgressStatsCubit>()..load(),
          ),
        ],
        child: DefaultTabController(
          length: 2,
          child: const _ProgressView(),
        ),
      );
    }
  }

  class _ProgressView extends StatelessWidget {
    const _ProgressView();

    @override
    Widget build(BuildContext context) {
      return const Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Cronologia'),
              Tab(text: 'Grafici'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _HistoryTab(),
                _ChartsTab(),
              ],
            ),
          ),
        ],
      );
    }
  }

  // ── History tab ────────────────────────────────────────────────────────────

  class _HistoryTab extends StatelessWidget {
    const _HistoryTab();

    @override
    Widget build(BuildContext context) {
      return BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, state) => switch (state) {
          ProgressInitial() || ProgressHistoryLoading() => const _HistoryShimmer(),
          ProgressHistoryLoaded(:final entries) when entries.isEmpty =>
            const _EmptyState(),
          ProgressHistoryLoaded(:final entries) => _HistoryList(entries: entries),
          ProgressHistoryError() => const _HistoryErrorState(),
        },
      );
    }
  }

  class _HistoryShimmer extends StatelessWidget {
    const _HistoryShimmer();

    @override
    Widget build(BuildContext context) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: const [
          ShimmerPlaceholder(height: 72),
          SizedBox(height: 8),
          ShimmerPlaceholder(height: 72),
          SizedBox(height: 8),
          ShimmerPlaceholder(height: 72),
        ],
      );
    }
  }

  class _EmptyState extends StatelessWidget {
    const _EmptyState();

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Text(
          'Nessuna sessione ancora. Inizia la tua prima oggi!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  class _HistoryList extends StatelessWidget {
    const _HistoryList({required this.entries});

    final List<SessionHistoryEntry> entries;

    @override
    Widget build(BuildContext context) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) =>
            SessionHistoryTile(entry: entries[index]),
      );
    }
  }

  class _HistoryErrorState extends StatelessWidget {
    const _HistoryErrorState();

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Text(
          'Impossibile caricare la cronologia',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      );
    }
  }

  // ── Charts tab ─────────────────────────────────────────────────────────────

  class _ChartsTab extends StatelessWidget {
    const _ChartsTab();

    @override
    Widget build(BuildContext context) {
      return BlocBuilder<ProgressStatsCubit, ProgressStatsState>(
        builder: (context, state) => switch (state) {
          ProgressStatsInitial() || ProgressStatsLoading() => const _ChartsShimmer(),
          ProgressStatsLoaded(:final stats)
              when stats.completedCount + stats.abandonedCount < 3 =>
            const _InsufficientDataState(),
          ProgressStatsLoaded(:final stats) => _ChartsDashboard(stats: stats),
          ProgressStatsError() => const _ChartsErrorState(),
        },
      );
    }
  }

  class _ChartsShimmer extends StatelessWidget {
    const _ChartsShimmer();

    @override
    Widget build(BuildContext context) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ShimmerPlaceholder(height: 200),
          SizedBox(height: 24),
          ShimmerPlaceholder(height: 200),
          SizedBox(height: 24),
          ShimmerPlaceholder(height: 200),
        ],
      );
    }
  }

  class _InsufficientDataState extends StatelessWidget {
    const _InsufficientDataState();

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Text(
          'Completa più sessioni per vedere i tuoi progressi',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  class _ChartsErrorState extends StatelessWidget {
    const _ChartsErrorState();

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Text(
          'Impossibile caricare i grafici',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      );
    }
  }

  class _ChartsDashboard extends StatelessWidget {
    const _ChartsDashboard({required this.stats});

    final ProgressStats stats;

    @override
    Widget build(BuildContext context) {
      final textTheme = Theme.of(context).textTheme;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Minuti per settimana', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: MinutesPerWeekChart(minutesPerWeek: stats.minutesPerWeek),
          ),
          const SizedBox(height: 24),
          Text('Tasso di completamento', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: CompletionRateChart(
              completedCount: stats.completedCount,
              abandonedCount: stats.abandonedCount,
            ),
          ),
          const SizedBox(height: 24),
          Text('Andamento RPE', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: RpeTrendChart(rpeTrend: stats.rpeTrend),
          ),
          const SizedBox(height: 24),
          Text('Tipologie di sessione', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: SessionTypeBreakdownChart(
              sessionTypeCounts: stats.sessionTypeCounts,
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }
  }
  ```

  **File size check**: this file will be ~200+ lines. The 200-400 line range is acceptable; do NOT extract into sub-files unless the file exceeds 400 lines after implementation.

---

### Task 10: Create `test/helpers/viewport_helper.dart` — closes E7-T2 (AC5)

- [x] CREATE `pulse_coach/test/helpers/viewport_helper.dart`

  ```dart
  import 'package:flutter_test/flutter_test.dart';

  /// Sets the test surface to 360×800 dp at 1:1 pixel ratio (Samsung A520F width).
  ///
  /// Call at the start of any test that must assert layout correctness on a
  /// phone-width surface. Registers teardowns to reset both physicalSize and
  /// devicePixelRatio automatically after the test.
  ///
  /// Closes E7-T2 (Epic 9 retro action E9R-2). The RPE overflow
  /// `9.1-WIDGET-005` was only caught on device because the default
  /// flutter_test surface is 800dp wide. Any widget with layout constraints
  /// that differ between 360dp and 800dp must use this helper.
  void set360dpSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  ```

---

### Task 11: Write tests (AC1–AC8)

#### 11a: Unit test — `ProgressLocalDataSource.getProgressStats()`

- [x] CREATE `pulse_coach/test/data/progress/progress_stats_data_source_test.dart`

  Use `NativeDatabase.memory()` — do NOT mock Drift:

  ```dart
  void main() {
    group('ProgressLocalDataSource.getProgressStats', () {
      late AppDatabase db;
      late ProgressLocalDataSource dataSource;

      setUp(() {
        db = AppDatabase.forTesting(NativeDatabase.memory());
        dataSource = ProgressLocalDataSource(
          SessionLogsDao(db),
          DailyPlansDao(db),
          RpeFeedbackDao(db),
        );
      });

      tearDown(() => db.close());

      test('10.2-DATA-001: returns empty ProgressStats when no session logs exist', () async {
        final result = await dataSource.getProgressStats();
        expect(result.completedCount, 0);
        expect(result.abandonedCount, 0);
        expect(result.minutesPerWeek, isEmpty);
        expect(result.rpeTrend, isEmpty);
        expect(result.sessionTypeCounts, isEmpty);
      });

      test('10.2-DATA-002: completedCount / abandonedCount are correct', () async {
        // insert 2 completed + 1 abandoned session logs via test helpers
        // assert completedCount == 2, abandonedCount == 1
      });

      test('10.2-DATA-003: rpeTrend excludes abandoned sessions and sessions with no RPE', () async {
        // insert 1 completed+RPE, 1 completed+noRPE, 1 abandoned
        // assert rpeTrend.length == 1
      });

      test('10.2-DATA-004: minutesPerWeek groups by ISO week and sums minutes', () async {
        // insert 2 sessions in same week (cardio 20min + mobility 15min)
        // assert minutesPerWeek.single.totalMinutes == 35
      });

      test('10.2-DATA-005: minutesPerWeek keeps at most 8 weeks', () async {
        // insert sessions in 10 different weeks
        // assert minutesPerWeek.length <= 8
      });

      test('10.2-DATA-006: sessionTypeCounts groups by type correctly', () async {
        // insert 2 cardio + 1 mobility
        // assert sessionTypeCounts['cardio'] == 2 && sessionTypeCounts['mobility'] == 1
      });
    });
  }
  ```

  Use the same `DailyPlan` test-data helper documented in Story 10.1 Dev Notes (insert a DailyPlan row, then SessionLog at `sessionIndex: 0`).

#### 11b: Cubit test — `ProgressStatsCubit`

- [x] CREATE `pulse_coach/test/bloc/progress_stats_cubit_test.dart`

  Use `@GenerateMocks([GetProgressStats])`. Run build_runner to generate mocks.

  ```dart
  @GenerateMocks([GetProgressStats])
  void main() {
    group('ProgressStatsCubit', () {
      late MockGetProgressStats mockGetProgressStats;
      late ProgressStatsCubit cubit;

      setUp(() {
        mockGetProgressStats = MockGetProgressStats();
        cubit = ProgressStatsCubit(mockGetProgressStats);
      });

      tearDown(() => cubit.close());

      test('10.2-CUBIT-001: initial state is ProgressStatsInitial', () {
        expect(cubit.state, isA<ProgressStatsInitial>());
      });

      blocTest<ProgressStatsCubit, ProgressStatsState>(
        '10.2-CUBIT-002: load() emits [ProgressStatsLoading, ProgressStatsLoaded] on success',
        build: () {
          when(mockGetProgressStats()).thenAnswer((_) async => Right(_emptyStats()));
          return ProgressStatsCubit(mockGetProgressStats);
        },
        act: (c) => c.load(),
        expect: () => [isA<ProgressStatsLoading>(), isA<ProgressStatsLoaded>()],
      );

      blocTest<ProgressStatsCubit, ProgressStatsState>(
        '10.2-CUBIT-003: load() emits [ProgressStatsLoading, ProgressStatsError] on failure',
        build: () {
          when(mockGetProgressStats()).thenAnswer(
            (_) async => const Left(CacheFailure('progress_stats_load_failed')),
          );
          return ProgressStatsCubit(mockGetProgressStats);
        },
        act: (c) => c.load(),
        expect: () => [isA<ProgressStatsLoading>(), isA<ProgressStatsError>()],
      );

      test('10.2-CUBIT-004: no emit after close (E8-P1 invariant)', () async {
        when(mockGetProgressStats()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Right(_emptyStats());
        });
        unawaited(cubit.load());
        await cubit.close();
        // If isClosed guard is missing, this would throw StateError.
        // The Future completes after close — expect no exception.
      });
    });
  }

  ProgressStats _emptyStats() => const ProgressStats(
        completedCount: 0,
        abandonedCount: 0,
        minutesPerWeek: [],
        rpeTrend: [],
        sessionTypeCounts: {},
      );
  ```

#### 11c: Widget tests — charts at 360dp (closes E7-T2 / AC5)

- [x] CREATE `pulse_coach/test/widget/progress/progress_charts_test.dart`

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/completion_rate_chart.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/minutes_per_week_chart.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/rpe_trend_chart.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/session_type_breakdown_chart.dart';
  import '../../helpers/viewport_helper.dart';

  Widget _wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SizedBox(height: 200, child: child)),
      );

  void main() {
    group('MinutesPerWeekChart — 360dp', () {
      testWidgets('10.2-WIDGET-001: renders without overflow at 360dp', (tester) async {
        set360dpSurface(tester);
        await tester.pumpWidget(_wrap(
          MinutesPerWeekChart(minutesPerWeek: [
            const WeeklyMinutes(weekLabel: '26/05', totalMinutes: 45),
            const WeeklyMinutes(weekLabel: '02/06', totalMinutes: 60),
          ]),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('CompletionRateChart — 360dp', () {
      testWidgets('10.2-WIDGET-002: renders without overflow at 360dp', (tester) async {
        set360dpSurface(tester);
        await tester.pumpWidget(
          _wrap(const CompletionRateChart(completedCount: 5, abandonedCount: 2)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('10.2-WIDGET-003: shows 71% for 5 completed / 2 abandoned', (tester) async {
        await tester.pumpWidget(
          _wrap(const CompletionRateChart(completedCount: 5, abandonedCount: 2)),
        );
        await tester.pumpAndSettle();
        expect(find.text('71%'), findsOneWidget);
      });
    });

    group('RpeTrendChart — 360dp', () {
      testWidgets('10.2-WIDGET-004: renders without overflow at 360dp', (tester) async {
        set360dpSurface(tester);
        await tester.pumpWidget(_wrap(
          RpeTrendChart(rpeTrend: [
            RpeDataPoint(completedAt: DateTime(2026, 5, 20), rpeValue: 6),
            RpeDataPoint(completedAt: DateTime(2026, 5, 22), rpeValue: 7),
            RpeDataPoint(completedAt: DateTime(2026, 5, 24), rpeValue: 5),
          ]),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('SessionTypeBreakdownChart — 360dp', () {
      testWidgets('10.2-WIDGET-005: renders without overflow at 360dp', (tester) async {
        set360dpSurface(tester);
        await tester.pumpWidget(_wrap(
          const SessionTypeBreakdownChart(
            sessionTypeCounts: {'cardio': 3, 'mobility': 2, 'breathing': 1},
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('_InsufficientDataState (<3 sessions)', () {
      testWidgets('10.2-WIDGET-006: shows placeholder text when stats has <3 sessions', (tester) async {
        // Pre-seed ProgressStatsCubit with ProgressStatsLoaded(emptyStats where completedCount+abandonedCount == 2)
        // Expect "Completa più sessioni per vedere i tuoi progressi" text
        // (wire via BlocProvider in ProgressPage pattern — see 10.1 widget tests for setup)
      });
    });
  }
  ```

---

### Task 12: Run `build_runner`, analyze, and test

- [x] From `pulse_coach/`, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  Expected new generated files:
  - `lib/features/progress/domain/entities/progress_stats.freezed.dart`
  - `test/bloc/progress_stats_cubit_test.mocks.dart`
  - Updated `lib/core/di/injection.config.dart` (new `@lazySingleton` for `GetProgressStats`, `@injectable` for `ProgressStatsCubit`)

- [x] Run `flutter analyze` — expect 0 issues.
- [x] Run `flutter test` — expect all 705 prior tests passing, plus new tests from Task 11.

---

## Dev Notes

### Why `ProgressStatsCubit` is `@injectable` (not `@lazySingleton`)

`ProgressPage` provides this cubit via `BlocProvider(create: ...)`, which closes the cubit when the Progress tab is disposed from the navigation stack. A singleton would be reused already-closed on the next tab visit — the `if (!isClosed)` guards would silently swallow every emit, and the charts tab would freeze on the shimmer frame. This is the same bug that hit `ProgressCubit` in Story 10.1 (Review Finding "Decision Needed" → patch applied). Matching pattern: `ProgressCubit`, `DailyPlanBloc`, `TodaySessionCubit` are all `@injectable` factories for the same reason.

### E7-T2 is CLOSED by this story

E7-T2 (Epic 7 Retro, re-targeted at Epic 9 Retro via E9R-2) requires: "viewport/golden test infra at 360dp before Story 10.2". Story 10.2 satisfies this by:
1. Creating `test/helpers/viewport_helper.dart` with `set360dpSurface()`.
2. Applying it in `10.2-WIDGET-001` through `10.2-WIDGET-005` for all 4 chart widgets.

The `tester.view.physicalSize = const Size(360, 640)` pattern already existed in 3 test files; `set360dpSurface()` formalizes it and adds auto-teardown. Update action-item-ledger `E7-T2` status to `done` after test suite passes.

### `fl_chart` decision (AC6) — USE

`fl_chart ^1.0.0` is already in `pubspec.yaml` (line 44, from Story 6.5.4 bump). The resolved version is ≥ 1.2. This story uses it for all 4 charts. The AC6 decision is **USE** — no prune, no alternative library.

**fl_chart 1.x API notes** (vs 0.x):
- `BarChartRodData.toY` replaces deprecated `y`. Use `toY`.
- `FlDotCirclePainter` is the concrete class for `getDotPainter` callback.
- `BarAreaData.color` should use `.withValues(alpha: 0.15)` (not deprecated `.withOpacity`) for Dart 3 null-safety compliance.
- `swapAnimationDuration` + `swapAnimationCurve` are top-level properties on all chart data classes.

### `ProgressLocalDataSource.getProgressStats()` reuses `getSessionHistory()`

This avoids duplicating the plan-join / RPE-join logic. The N+1 penalty is accepted at this milestone (noted as a deferred optimization in Story 10.1 Review). The computation itself is O(n) over the already-fetched list.

### No schema changes in this story

Epic 10 is read-side only (from Epic 9 retro, E8-P3 preserved). Do NOT add new Drift tables or columns. `app_database.dart` is not touched.

### `ColorScheme.surfaceContainerHighest` availability

`ColorScheme.surfaceContainerHighest` is available from Flutter 3.22+ (M3 token). The project uses Flutter 3.41.x — safe to use. If the IDE linter flags it as unknown, verify the Flutter SDK version via `flutter --version`.

### 360dp chart layout constraint

Each chart in `_ChartsDashboard` is wrapped in `SizedBox(height: 200, ...)`. At 360dp width, `fl_chart` widgets respect the parent `BoxConstraints` and fill width. The `SizedBox` prevents unbounded height. No overflow is expected because:
- `BarChart`, `LineChart`, `PieChart` all implement `RenderBox.performLayout` respecting `BoxConstraints.maxWidth`.
- `SessionTypeBreakdownChart` uses a `Row` with `Expanded` on the pie — the legend column is fixed width; must not overflow at 360dp. If the legend text overflows on very narrow screens, use `Text(overflow: TextOverflow.ellipsis)`.

### `_HistoryList` separator parameter — Dart 3.0 positional wildcard

The existing `separatorBuilder: (_, _)` uses the positional wildcard (`_` as second parameter) which is valid in Dart 3.0+. Keep it unchanged when migrating this code into the new file.

### Italian labels

All user-facing text is Italian (consistent with app locale lock):
- Tab labels: `'Cronologia'`, `'Grafici'`
- Chart section headers: `'Minuti per settimana'`, `'Tasso di completamento'`, `'Andamento RPE'`, `'Tipologie di sessione'`
- Empty-data state: `'Completa più sessioni per vedere i tuoi progressi'`
- Error state: `'Impossibile caricare i grafici'`
- Type labels in legend: `'Mobilità'`, `'Cardio'`, `'Respirazione'`

Do NOT create ARB keys in this story (same rule as 10.1 — ARB wiring is E7.5-T1 scope).

### E8-P1 invariant (Cubit lifecycle)

`ProgressStatsCubit.load()` applies the E8-P1 invariant: every `emit` is guarded by `if (!isClosed)`. Both the error branch and the success branch in `fold()` are guarded. The `fold` callback fires synchronously after `await _getProgressStats()`, so exactly two guards are needed (one per fold arm). The test `10.2-CUBIT-004` verifies the no-emit-after-close behavior.

### `ProgressStats` freezed + `Map<String, int>` equality

Freezed generates deep equality for all fields. `Map<String, int>` equality in Dart compares content (order-independent for same keys). `List<WeeklyMinutes>` equality uses the generated `WeeklyMinutes.==` from freezed. This is correct behavior — cubit state equality works properly.

### Test helper import path

In test files, import the viewport helper with a relative path:
```dart
import '../../helpers/viewport_helper.dart';
```
(from `test/widget/progress/` → `test/helpers/`)

Or via package path if a `test/` package alias is set up. Prefer relative import within test/ since it's not a lib/ package.

### References

- Epics.md Story 10.2: `_bmad-output/planning-artifacts/epics.md` (lines 1590–1621)
- UX spec (DR19 — fl_chart animated charts): `_bmad-output/planning-artifacts/ux-design-specification.md` (line 143)
- UX spec (DR18 — 250ms ease-in-out animation constants): line 142
- Architecture (progress widget tree): `_bmad-output/planning-artifacts/architecture.md` (lines 737–763)
- Previous story (10.1): `_bmad-output/implementation-artifacts/10-1-session-history-timeline.md`
- Action item ledger (E7-T2, E9R-2): `_bmad-output/implementation-artifacts/action-item-ledger.md`
- Project context: `_bmad-output/project-context.md`
- `ProgressCubit` / `ProgressState`: `pulse_coach/lib/features/progress/presentation/bloc/`
- `ProgressLocalDataSource`: `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart`
- `ProgressRepositoryImpl`: `pulse_coach/lib/features/progress/data/repositories/progress_repository_impl.dart`
- `SessionHistoryEntry`: `pulse_coach/lib/features/progress/domain/entities/session_history_entry.dart`
- `ShimmerPlaceholder`: `pulse_coach/lib/shared/widgets/shimmer_placeholder.dart`
- `AppLogger`: `pulse_coach/lib/core/logging/app_logger.dart`
- `Failure`, `CacheFailure`: `pulse_coach/lib/core/error/failures.dart`
- Existing 360dp test pattern: `pulse_coach/test/widget/rpe_input_widget_test.dart:72`
- Sprint status: `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `dart run build_runner build --delete-conflicting-outputs` (passed; generated Freezed, Mockito mocks, and Injectable DI)
- `flutter test test/data/progress/progress_stats_data_source_test.dart test/bloc/progress_stats_cubit_test.dart test/widget/progress/progress_charts_test.dart test/widget/progress/progress_page_test.dart` (passed during implementation: 22 tests)
- `flutter test test/widget/progress/progress_page_test.dart` (passed after AC1 page coverage addition: 8 tests)
- `flutter analyze` (passed: no issues)
- `flutter test` (passed: 725 tests)

### Implementation Plan

- Add a read-side `ProgressStats` projection assembled from existing session history data, without schema changes.
- Extend the progress repository/use-case layer and wire a factory-scoped `ProgressStatsCubit` through Injectable.
- Replace `ProgressPage` with History/Grafici tabs, preserving existing history behavior and adding chart loading, insufficient-data, error, and dashboard states.
- Render all four charts with `fl_chart` using 250ms `duration` and `Curves.easeInOut`; this uses the non-deprecated fl_chart 1.2 API while satisfying the animation behavior in AC2.
- Add 360dp viewport helper and chart/page tests to close E7-T2 / E9R-2.

### Completion Notes List

- Created `ProgressStats`, `WeeklyMinutes`, and `RpeDataPoint` Freezed entities plus generated code.
- Added `GetProgressStats`, repository contract/implementation support, and `ProgressLocalDataSource.getProgressStats()` aggregation for counts, weekly minutes, RPE trend, and session-type breakdown.
- Added `ProgressStatsCubit` with guarded emits after async work to satisfy the no-emit-after-close invariant.
- Added four bounded `fl_chart` widgets and wired them into the Progress screen under the new `Grafici` tab with shimmer and insufficient-data states.
- Added datasource, cubit, page, and 360dp chart widget tests; updated smoke/shell test stubs for the new repository contract and cubit dependency.
- Updated the action-item ledger to close E7-T2 and E9R-2 after successful validation.

### File List

- `_bmad-output/implementation-artifacts/10-2-progress-charts.md`
- `_bmad-output/implementation-artifacts/action-item-ledger.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart`
- `pulse_coach/lib/features/progress/data/repositories/progress_repository_impl.dart`
- `pulse_coach/lib/features/progress/domain/entities/progress_stats.dart`
- `pulse_coach/lib/features/progress/domain/entities/progress_stats.freezed.dart`
- `pulse_coach/lib/features/progress/domain/repositories/progress_repository.dart`
- `pulse_coach/lib/features/progress/domain/usecases/get_progress_stats.dart`
- `pulse_coach/lib/features/progress/presentation/bloc/progress_stats_cubit.dart`
- `pulse_coach/lib/features/progress/presentation/bloc/progress_stats_state.dart`
- `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart`
- `pulse_coach/lib/features/progress/presentation/widgets/completion_rate_chart.dart`
- `pulse_coach/lib/features/progress/presentation/widgets/minutes_per_week_chart.dart`
- `pulse_coach/lib/features/progress/presentation/widgets/rpe_trend_chart.dart`
- `pulse_coach/lib/features/progress/presentation/widgets/session_type_breakdown_chart.dart`
- `pulse_coach/test/bloc/progress_stats_cubit_test.dart`
- `pulse_coach/test/bloc/progress_stats_cubit_test.mocks.dart`
- `pulse_coach/test/data/progress/progress_stats_data_source_test.dart`
- `pulse_coach/test/helpers/viewport_helper.dart`
- `pulse_coach/test/widget/app_shell_test.dart`
- `pulse_coach/test/widget/pages_smoke_test.dart`
- `pulse_coach/test/widget/progress/progress_charts_test.dart`
- `pulse_coach/test/widget/progress/progress_page_test.dart`
- `pulse_coach/test/widget/progress/progress_page_test.mocks.dart`

### Change Log

- 2026-05-26: Implemented Story 10.2 progress charts, 360dp viewport coverage, and BMad ledger closure updates.

### Review Findings

_Code review 2026-05-26 (adversarial: Blind Hunter + Edge Case Hunter + Acceptance Auditor). No Critical/High production defects found. All 8 ACs functionally satisfied. 2 decision-needed, 0 patch, 0 defer, 12 dismissed as noise/false-positive._

- [x] [Review][Decision] AC2 animation API naming contradiction — RESOLVED 2026-05-26 (DN1 → option 1): spec ratified to the fl_chart 1.2 API. AC2 and Task 8 mandated `swapAnimationDuration` + `swapAnimationCurve`, but those are deprecated/removed in fl_chart 1.2. The code uses the 1.2 API (`duration: const Duration(milliseconds: 250)` + `curve: Curves.easeInOut`) on all 4 chart widgets, preserving the specified 250ms ease-in-out behavior. AC2 + Task 8 text updated; no code change.
- [x] [Review][Patch] Add per-chart empty-state for empty `rpeTrend` [progress_page.dart] — RESOLVED 2026-05-26 (DN2 → option 1). Added `_RpeEmptyState` widget; `_ChartsDashboard` now renders it (text: "Nessun dato RPE ancora disponibile") instead of `RpeTrendChart` when `stats.rpeTrend.isEmpty`. Covered by new test `10.2-WIDGET-009`. `flutter analyze` clean; `flutter test` 726/726 passing (+1).
