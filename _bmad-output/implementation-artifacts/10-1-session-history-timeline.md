# Story 10.1: Session History Timeline

Status: done

## Story

As a user,
I want to see a chronological timeline of all my completed and abandoned sessions,
So that I can track what I've done and see patterns in my activity.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The user navigates to the Progress screen | When the history renders with data | Sessions are displayed in **reverse chronological order** (most recent first) with: date label, session type icon, session name, duration (minutes), and RPE value (or "—" when none recorded) — satisfying FR29 |
| AC2 | A session was abandoned | When it appears in the timeline | It is visually distinguished from completed sessions (muted opacity ≤ 0.5 **or** an explicit "Abbandonata" label in a secondary/error color — choose one approach and apply consistently) |
| AC3 | No sessions have been completed or abandoned | When the history timeline renders | An empty-state text message ("Nessuna sessione ancora. Inizia la tua prima oggi!") is shown — **no illustration** (UX spec rule: empty states use minimal text only) |
| AC4 | The history is loading (initial fetch in progress) | When inspected | Three `ShimmerPlaceholder` rows (height 72) are displayed instead of content, using the existing `ShimmerPlaceholder` widget at `lib/shared/widgets/shimmer_placeholder.dart` |
| AC5 | The DAO read fails | When the cubit emits | A `ProgressHistoryError` state is emitted via `AppLogger.error` + error state — error text ("Impossibile caricare la cronologia") is shown in the UI |
| AC6 | The cubit lifecycle: `close()` is called before the `getSessionHistory` Future completes | When the future returns | The cubit does NOT emit after close — every emit is guarded by `if (!isClosed)` (E8-P1 invariant) |

## Tasks / Subtasks

---

### Task 1: Add `getAllLogsOrderedByDate()` to `SessionLogsDao` (AC1, AC4)

- [x] READ `pulse_coach/lib/core/database/daos/session_logs_dao.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/core/database/daos/session_logs_dao.dart`

  Add a new method that returns ALL session log rows sorted by `completedAt` descending (most recent first):

  ```dart
  /// Returns all session log rows across all plans, most recent first.
  /// Used by the progress history feature (read-only; no plan filter).
  Future<List<SessionLog>> getAllLogsOrderedByDate() =>
      (select(sessionLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .get();
  ```

  **No other changes to this file.** Do not remove or alter existing methods.

---

### Task 2: Add `getBySessionLogId()` to `RpeFeedbackDao` (AC1)

- [x] READ `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart`

  Add one lookup method:

  ```dart
  /// Returns the RPE feedback row for [sessionLogId], or null when the user
  /// did not rate this session (e.g. abandoned before the RPE screen).
  Future<RpeFeedbackData?> getBySessionLogId(int sessionLogId) =>
      (select(rpeFeedback)
            ..where((t) => t.sessionLogId.equals(sessionLogId))
            ..limit(1))
          .getSingleOrNull();
  ```

  **No other changes to this file.**

---

### Task 3: Create `SessionHistoryEntry` domain entity (AC1, AC2)

- [x] CREATE `pulse_coach/lib/features/progress/domain/entities/session_history_entry.dart`

  This is a **pure Dart** read-only value object. Use `@freezed` for consistency with other domain entities.

  **IMPORTANT**: After creating this file, you MUST run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` to generate `.freezed.dart` and `.g.dart` files (even though json_serializable is not needed here, the `part` declaration for freezed is required).

  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'session_history_entry.freezed.dart';

  /// Flattened view of one session_logs row, enriched with plan data and RPE.
  ///
  /// Constructed by [ProgressLocalDataSource] from session_logs +
  /// daily_plans (planJson) + rpe_feedback joins. Read-only; never persisted.
  @freezed
  abstract class SessionHistoryEntry with _$SessionHistoryEntry {
    const factory SessionHistoryEntry({
      required int sessionLogId,
      required DateTime completedAt,
      /// 'mobility' | 'cardio' | 'breathing' — from PlannedSession.sessionType
      required String sessionType,
      required int durationMinutes,
      required bool abandoned,
      /// null when user did not submit RPE for this session
      int? rpeValue,
      /// elapsed seconds at abandon time; null for completed sessions
      int? elapsedSeconds,
    }) = _SessionHistoryEntry;
  }
  ```

  **No `fromJson` factory needed** — this entity is assembled by the data source, never deserialized from external JSON.

---

### Task 4: Create `ProgressRepository` interface (domain layer)

- [x] CREATE `pulse_coach/lib/features/progress/domain/repositories/progress_repository.dart`

  ```dart
  import 'package:dartz/dartz.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

  /// Read-only contract for the progress feature.
  ///
  /// Story 10.1 uses only [getSessionHistory]. Story 10.2+ will add
  /// [getProgressStats] here — do NOT add it now.
  abstract class ProgressRepository {
    Future<Either<Failure, List<SessionHistoryEntry>>> getSessionHistory();
  }
  ```

---

### Task 5: Create `GetSessionHistory` use case (domain layer)

- [x] CREATE `pulse_coach/lib/features/progress/domain/usecases/get_session_history.dart`

  ```dart
  import 'package:dartz/dartz.dart';
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
  import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';

  @lazySingleton
  class GetSessionHistory {
    const GetSessionHistory(this._repository);

    final ProgressRepository _repository;

    Future<Either<Failure, List<SessionHistoryEntry>>> call() =>
        _repository.getSessionHistory();
  }
  ```

---

### Task 6: Create `ProgressLocalDataSource` (data layer)

- [x] CREATE `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart`

  This class **assembles** `SessionHistoryEntry` objects by joining across three DAOs. It is pure Dart — no Flutter imports.

  ```dart
  import 'dart:convert';

  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
  import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
  import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
  import 'package:pulse_coach/core/logging/app_logger.dart';
  import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
  import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

  @lazySingleton
  class ProgressLocalDataSource {
    const ProgressLocalDataSource(
      this._sessionLogsDao,
      this._dailyPlansDao,
      this._rpeFeedbackDao,
    );

    final SessionLogsDao _sessionLogsDao;
    final DailyPlansDao _dailyPlansDao;
    final RpeFeedbackDao _rpeFeedbackDao;

    Future<List<SessionHistoryEntry>> getSessionHistory() async {
      final logs = await _sessionLogsDao.getAllLogsOrderedByDate();
      final entries = <SessionHistoryEntry>[];

      for (final log in logs) {
        final planRow = await _dailyPlansDao.getPlanById(log.dailyPlanId);
        if (planRow == null) {
          AppLogger.warning(
            'SessionLog ${log.id} references missing plan ${log.dailyPlanId} — skipping',
            name: 'ProgressLocalDataSource',
          );
          continue;
        }

        late final DailyPlan plan;
        try {
          plan = DailyPlan.fromJson(
            jsonDecode(planRow.planJson) as Map<String, dynamic>,
          );
        } catch (e, st) {
          AppLogger.error(
            'Failed to parse planJson for plan ${planRow.id}',
            name: 'ProgressLocalDataSource',
            error: e,
            stackTrace: st,
          );
          continue;
        }

        if (log.sessionIndex < 0 || log.sessionIndex >= plan.sessions.length) {
          AppLogger.warning(
            'SessionLog ${log.id}: sessionIndex ${log.sessionIndex} out of range '
            'for plan ${planRow.id} (sessions.length = ${plan.sessions.length}) — skipping',
            name: 'ProgressLocalDataSource',
          );
          continue;
        }

        final session = plan.sessions[log.sessionIndex];
        final feedback = await _rpeFeedbackDao.getBySessionLogId(log.id);

        entries.add(
          SessionHistoryEntry(
            sessionLogId: log.id,
            completedAt: log.completedAt,
            sessionType: session.sessionType,
            durationMinutes: session.durationMinutes,
            abandoned: log.abandoned,
            rpeValue: feedback?.rpeValue,
            elapsedSeconds: log.elapsedSeconds,
          ),
        );
      }

      return entries;
    }
  }
  ```

  **Defensive notes for the data loop:**
  - A missing `planRow` or JSON parse failure skips the entry with a warning rather than crashing the whole list.
  - `sessionIndex` bounds check prevents index-out-of-range on corrupt/migrated data.
  - This is acceptable UX: a handful of corrupt rows are hidden from the timeline; the user sees valid entries.

---

### Task 7: Create `ProgressRepositoryImpl` (data layer)

- [x] CREATE `pulse_coach/lib/features/progress/data/repositories/progress_repository_impl.dart`

  ```dart
  import 'package:dartz/dartz.dart';
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/progress/data/datasources/progress_local_data_source.dart';
  import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
  import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';

  @LazySingleton(as: ProgressRepository)
  class ProgressRepositoryImpl implements ProgressRepository {
    const ProgressRepositoryImpl(this._dataSource);

    final ProgressLocalDataSource _dataSource;

    @override
    Future<Either<Failure, List<SessionHistoryEntry>>> getSessionHistory() async {
      try {
        final entries = await _dataSource.getSessionHistory();
        return Right(entries);
      } catch (e, st) {
        return Left(CacheFailure('progress_history_load_failed'));
      }
    }
  }
  ```

  **Import**: `CacheFailure` from `package:pulse_coach/core/error/failures.dart`.
  **Note**: The repository catch wraps ALL exceptions as `CacheFailure` — this is the layer boundary pattern used throughout the project.

---

### Task 8: Create `ProgressState` sealed class (presentation layer)

- [x] CREATE `pulse_coach/lib/features/progress/presentation/bloc/progress_state.dart`

  Following the `MiniSummaryState` / `PostRpeAdaptationState` pattern — sealed class, no freezed (UI-only state):

  ```dart
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

  sealed class ProgressState {
    const ProgressState();
  }

  class ProgressInitial extends ProgressState {
    const ProgressInitial();
  }

  class ProgressHistoryLoading extends ProgressState {
    const ProgressHistoryLoading();
  }

  class ProgressHistoryLoaded extends ProgressState {
    const ProgressHistoryLoaded(this.entries);
    final List<SessionHistoryEntry> entries;
  }

  class ProgressHistoryError extends ProgressState {
    const ProgressHistoryError(this.failure);
    final Failure failure;
  }
  ```

---

### Task 9: Create `ProgressCubit` (presentation layer)

- [x] CREATE `pulse_coach/lib/features/progress/presentation/bloc/progress_cubit.dart`

  ```dart
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/logging/app_logger.dart';
  import 'package:pulse_coach/features/progress/domain/usecases/get_session_history.dart';
  import 'package:pulse_coach/features/progress/presentation/bloc/progress_state.dart';

  @lazySingleton
  class ProgressCubit extends Cubit<ProgressState> {
    ProgressCubit(this._getSessionHistory) : super(const ProgressInitial());

    final GetSessionHistory _getSessionHistory;

    Future<void> load() async {
      if (!isClosed) emit(const ProgressHistoryLoading());

      final result = await _getSessionHistory();

      result.fold(
        (failure) {
          AppLogger.error(
            'getSessionHistory failed: ${failure.message}',
            name: 'ProgressCubit',
          );
          if (!isClosed) emit(ProgressHistoryError(failure));
        },
        (entries) {
          if (!isClosed) emit(ProgressHistoryLoaded(entries));
        },
      );
    }
  }
  ```

  **DI annotation**: `@lazySingleton` — the Progress tab persists in the bottom nav shell; a single shared instance is correct. If a fresh load is ever needed, call `cubit.load()` again from the page.

---

### Task 10: Create `SessionHistoryTile` widget (presentation layer)

- [x] CREATE `pulse_coach/lib/features/progress/presentation/widgets/session_history_tile.dart`

  ```dart
  import 'package:flutter/material.dart';
  import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

  class SessionHistoryTile extends StatelessWidget {
    const SessionHistoryTile({super.key, required this.entry});

    final SessionHistoryEntry entry;

    @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;
      final isAbandoned = entry.abandoned;

      return Opacity(
        opacity: isAbandoned ? 0.45 : 1.0,
        child: ListTile(
          leading: _SessionTypeIcon(sessionType: entry.sessionType),
          title: Text(
            _sessionLabel(entry.sessionType),
            style: textTheme.bodyLarge,
          ),
          subtitle: Text(
            _subtitleText(entry),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: _RpeBadge(rpeValue: entry.rpeValue),
        ),
      );
    }

    String _sessionLabel(String sessionType) => switch (sessionType) {
          'mobility' => 'Mobilità',
          'cardio' => 'Cardio',
          'breathing' => 'Respirazione',
          _ => sessionType,
        };

    String _subtitleText(SessionHistoryEntry e) {
      final date = _formatDate(e.completedAt);
      final duration = e.abandoned && e.elapsedSeconds != null
          ? '${(e.elapsedSeconds! ~/ 60)}min (abbandonata)'
          : '${e.durationMinutes}min';
      return '$date · $duration';
    }

    String _formatDate(DateTime dt) {
      // Simple day/month/year — no intl dependency needed for this milestone.
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    }
  }

  class _SessionTypeIcon extends StatelessWidget {
    const _SessionTypeIcon({required this.sessionType});
    final String sessionType;

    @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;
      final iconData = switch (sessionType) {
        'mobility' => Icons.self_improvement,
        'cardio' => Icons.directions_run,
        'breathing' => Icons.air,
        _ => Icons.fitness_center,
      };
      return CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(iconData, color: colorScheme.onPrimaryContainer, size: 20),
      );
    }
  }

  class _RpeBadge extends StatelessWidget {
    const _RpeBadge({required this.rpeValue});
    final int? rpeValue;

    @override
    Widget build(BuildContext context) {
      final textTheme = Theme.of(context).textTheme;
      final colorScheme = Theme.of(context).colorScheme;
      if (rpeValue == null) {
        return Text('—', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline));
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'RPE $rpeValue',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      );
    }
  }
  ```

---

### Task 11: Replace `ProgressPage` stub with real implementation

- [x] READ `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart` fully before editing.

  Current content: a 9-line stub `Center(child: Text('Progress — Story 10.x'))`.

- [x] UPDATE `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart`

  Replace the entire file:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:pulse_coach/core/di/injection.dart';
  import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart';
  import 'package:pulse_coach/features/progress/presentation/bloc/progress_state.dart';
  import 'package:pulse_coach/features/progress/presentation/widgets/session_history_tile.dart';
  import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

  class ProgressPage extends StatelessWidget {
    const ProgressPage({super.key});

    @override
    Widget build(BuildContext context) {
      return BlocProvider<ProgressCubit>(
        create: (_) => getIt<ProgressCubit>()..load(),
        child: const _ProgressView(),
      );
    }
  }

  class _ProgressView extends StatelessWidget {
    const _ProgressView();

    @override
    Widget build(BuildContext context) {
      return BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, state) => switch (state) {
          ProgressInitial() || ProgressHistoryLoading() => const _HistoryShimmer(),
          ProgressHistoryLoaded(:final entries) when entries.isEmpty =>
            const _EmptyState(),
          ProgressHistoryLoaded(:final entries) => _HistoryList(entries: entries),
          ProgressHistoryError(:final failure) => _ErrorState(message: failure.message),
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

    final List entries;

    @override
    Widget build(BuildContext context) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) =>
            SessionHistoryTile(entry: entries[index]),
      );
    }
  }

  class _ErrorState extends StatelessWidget {
    const _ErrorState({required this.message});
    final String message;

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
  ```

  **IMPORTANT — `_HistoryList.entries` type**: Use `List<SessionHistoryEntry>` not `List` (dynamic). Fix the type annotation to `final List<SessionHistoryEntry> entries;` — the `List` dynamic type above is a placeholder to prevent copy-paste issues; always use the concrete import.

---

### Task 12: Run `build_runner` and update DI config

- [x] From `pulse_coach/`, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

  This generates:
  - `lib/features/progress/domain/entities/session_history_entry.freezed.dart`
  - Updated `lib/core/di/injection.config.dart` (picks up new `@lazySingleton` and `@LazySingleton(as: ProgressRepository)` annotations)

  **Expected new DI registrations** in `injection.config.dart`:
  ```
  gh.lazySingleton<ProgressLocalDataSource>(...)
  gh.lazySingleton<ProgressRepository>(...)   // as ProgressRepositoryImpl
  gh.lazySingleton<GetSessionHistory>(...)
  gh.lazySingleton<ProgressCubit>(...)
  ```

  If build_runner fails, the most likely cause is a missing import or a `part` declaration mismatch. Check the error output carefully before re-running.

- [x] Run `flutter analyze` — expect 0 issues.
- [x] Run `flutter test` — expect 690+ existing tests passing, plus new ones from Task 13.

---

### Task 13: Write tests (AC1–AC6)

#### 13a: Unit test — `ProgressLocalDataSource`

- [x] CREATE `pulse_coach/test/data/progress/progress_local_data_source_test.dart`

  Use `NativeDatabase.memory()` for Drift — do NOT mock the database.

  ```dart
  void main() {
    group('ProgressLocalDataSource', () {
      late AppDatabase db;
      late SessionLogsDao sessionLogsDao;
      late DailyPlansDao dailyPlansDao;
      late RpeFeedbackDao rpeFeedbackDao;
      late ProgressLocalDataSource dataSource;

      setUp(() {
        db = AppDatabase.forTesting(NativeDatabase.memory());
        sessionLogsDao = SessionLogsDao(db);
        dailyPlansDao = DailyPlansDao(db);
        rpeFeedbackDao = RpeFeedbackDao(db);
        dataSource = ProgressLocalDataSource(sessionLogsDao, dailyPlansDao, rpeFeedbackDao);
      });

      tearDown(() => db.close());

      test('10.1-DATA-001: returns empty list when no session logs exist', () async {
        final result = await dataSource.getSessionHistory();
        expect(result, isEmpty);
      });

      test('10.1-DATA-002: returns one entry for a completed session with RPE', () async {
        // insert a DailyPlan row with a valid planJson containing one PlannedSession
        // insert a SessionLog row referencing that plan at index 0, not abandoned
        // insert a RpeFeedback row with sessionLogId = that log's id
        // assert the returned entry has correct sessionType, durationMinutes, abandoned=false, rpeValue
        // (write the full test body — see Dev Notes "Test Data Helpers")
      });

      test('10.1-DATA-003: returns entry with abandoned=true and elapsedSeconds for abandoned session', () async {
        // insert plan + abandoned session log; no rpe feedback
        // assert entry.abandoned == true && entry.rpeValue == null && entry.elapsedSeconds != null
      });

      test('10.1-DATA-004: skips session log whose planId references a missing plan', () async {
        // insert a SessionLog with dailyPlanId = 9999 (no corresponding DailyPlan row)
        // assert getSessionHistory() returns an empty list (not a throw)
      });

      test('10.1-DATA-005: orders entries most-recent-first', () async {
        // insert two session logs with different completedAt dates
        // assert result[0].completedAt > result[1].completedAt
      });
    });
  }
  ```

  **Note**: Fill in the full test bodies (see Dev Notes for helper pattern). The test IDs shown above are the canonical regression tags.

#### 13b: Cubit test — `ProgressCubit`

- [x] CREATE `pulse_coach/test/bloc/progress_cubit_test.dart`

  Use `mockito` with `@GenerateMocks([GetSessionHistory])`. Generate mocks via build_runner.

  ```dart
  @GenerateMocks([GetSessionHistory])
  void main() {
    group('ProgressCubit', () {
      late MockGetSessionHistory mockGetSessionHistory;
      late ProgressCubit cubit;

      setUp(() {
        mockGetSessionHistory = MockGetSessionHistory();
        cubit = ProgressCubit(mockGetSessionHistory);
      });

      tearDown(() => cubit.close());

      test('10.1-CUBIT-001: initial state is ProgressInitial', () {
        expect(cubit.state, isA<ProgressInitial>());
      });

      blocTest<ProgressCubit, ProgressState>(
        '10.1-CUBIT-002: load() emits [ProgressHistoryLoading, ProgressHistoryLoaded] on success',
        build: () {
          when(mockGetSessionHistory()).thenAnswer(
            (_) async => const Right(<SessionHistoryEntry>[]),
          );
          return ProgressCubit(mockGetSessionHistory);
        },
        act: (c) => c.load(),
        expect: () => [
          isA<ProgressHistoryLoading>(),
          isA<ProgressHistoryLoaded>(),
        ],
      );

      blocTest<ProgressCubit, ProgressState>(
        '10.1-CUBIT-003: load() emits [ProgressHistoryLoading, ProgressHistoryError] on failure',
        build: () {
          when(mockGetSessionHistory()).thenAnswer(
            (_) async => Left(const CacheFailure('progress_history_load_failed')),
          );
          return ProgressCubit(mockGetSessionHistory);
        },
        act: (c) => c.load(),
        expect: () => [
          isA<ProgressHistoryLoading>(),
          isA<ProgressHistoryError>(),
        ],
      );

      blocTest<ProgressCubit, ProgressState>(
        '10.1-CUBIT-004: ProgressHistoryLoaded carries the entries returned by use case',
        build: () {
          final entry = SessionHistoryEntry(
            sessionLogId: 1,
            completedAt: DateTime(2026, 5, 24),
            sessionType: 'cardio',
            durationMinutes: 20,
            abandoned: false,
            rpeValue: 7,
          );
          when(mockGetSessionHistory()).thenAnswer(
            (_) async => Right([entry]),
          );
          return ProgressCubit(mockGetSessionHistory);
        },
        act: (c) => c.load(),
        expect: () => [
          isA<ProgressHistoryLoading>(),
          isA<ProgressHistoryLoaded>().having(
            (s) => (s as ProgressHistoryLoaded).entries.length,
            'entries count',
            1,
          ),
        ],
      );
    });
  }
  ```

#### 13c: Widget test — `ProgressPage` states

- [x] CREATE `pulse_coach/test/widget/progress/progress_page_test.dart`

  ```dart
  void main() {
    group('ProgressPage', () {
      testWidgets('10.1-WIDGET-001: shows shimmer when loading', (tester) async {
        // Provide ProgressCubit in ProgressHistoryLoading state
        // Pump ProgressPage
        // Expect ShimmerPlaceholder x3 to be visible
        // (use BlocProvider with a cubit pre-seeded to ProgressHistoryLoading)
      });

      testWidgets('10.1-WIDGET-002: shows empty state when no entries', (tester) async {
        // Pre-seed ProgressHistoryLoaded(entries: [])
        // Expect "Nessuna sessione ancora" text visible
      });

      testWidgets('10.1-WIDGET-003: shows session tiles for loaded entries', (tester) async {
        // Pre-seed ProgressHistoryLoaded(entries: [cardio entry])
        // Expect SessionHistoryTile visible
        // Expect "Cardio" text or icon visible
      });

      testWidgets('10.1-WIDGET-004: error state shows error message', (tester) async {
        // Pre-seed ProgressHistoryError(CacheFailure('...'))
        // Expect "Impossibile caricare la cronologia" text
      });

      testWidgets('10.1-WIDGET-005: abandoned tile rendered at reduced opacity', (tester) async {
        // Pre-seed ProgressHistoryLoaded(entries: [abandoned entry])
        // Find Opacity widget and assert opacity <= 0.5
      });
    });
  }
  ```

---

### Task 14: Verification

- [x] Run `flutter analyze` from `pulse_coach/` — expect 0 issues.
- [x] Run `flutter test` from `pulse_coach/` — expect all 690 prior tests still passing, plus the new tests from Task 13.
- [x] Confirm `lib/core/di/injection.config.dart` contains registrations for `ProgressLocalDataSource`, `ProgressRepository`, `GetSessionHistory`, `ProgressCubit`.
- [x] Confirm `lib/features/progress/domain/entities/session_history_entry.freezed.dart` was generated.

---

## Dev Notes

### Why the data join happens in `ProgressLocalDataSource`, not SQL

The `SessionLog` table stores `dailyPlanId + sessionIndex`. The session name, type, and duration live in `daily_plans.planJson` (a JSON blob). There is no dedicated `sessions` row per `session_log` (the `sessions` table is a legacy/separate concern from the `session_logs` + `daily_plans` flow used since Story 8.0). The correct source of session metadata is `DailyPlan.sessions[sessionIndex]`, parsed from `planJson`. This join is intentionally done in Dart (not SQL) because `planJson` is opaque to SQLite.

### `DailyPlan.fromJson` import

Use `package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart`. The class is freezed+json_serializable. `DailyPlan.fromJson(map)` returns a domain entity containing `List<PlannedSession> sessions`.

### `jsonDecode` returns `dynamic`

When calling `jsonDecode(planRow.planJson)`, cast immediately: `as Map<String, dynamic>`. If the cast fails (corrupt JSON), the `try/catch` in Task 6 will catch the `TypeError` and log the error + skip the entry.

### `sessions` table vs `session_logs` table

The `sessions` table (`lib/core/database/tables/sessions_table.dart`) is from an earlier epic and tracks sessions independently. **Do NOT use it for Story 10.1.** The authoritative source of completed/abandoned session records since Story 8.0 is `session_logs` (linked to `daily_plans` via `dailyPlanId`).

### No schema migration in this story

Epic 10 is explicitly read-only (noted in Epic 10 Kickoff Prep: "No new schema bump expected in Epic 10"). Do NOT add new Drift tables, columns, or migrations. Do not modify `app_database.dart` beyond what `build_runner` auto-updates in `injection.config.dart`.

### `@LazySingleton(as: ProgressRepository)` annotation

The DI framework needs to know that `ProgressRepositoryImpl` satisfies the `ProgressRepository` interface. Use `@LazySingleton(as: ProgressRepository)` on the impl class (not `@lazySingleton`). This is the same pattern used by other repository implementations in this codebase.

### `BlocProvider` creates then loads

In `ProgressPage.build()`:
```dart
create: (_) => getIt<ProgressCubit>()..load(),
```
This pattern (cascade `..load()` on the cubit returned by `create`) ensures `load()` fires immediately when the page mounts, before `BlocBuilder` renders. It is identical to how `DailyPlanBloc` is wired in `app_router.dart`.

### E7-T2 (viewport/golden at 360dp) is NOT required for Story 10.1

`E7-T2` must be unblocked **before Story 10.2** (per Epic 9 retro action E9R-2). Story 10.1 only introduces a scrollable `ListView` of tiles — overflow risk is low since tiles use standard `ListTile` height. The 360dp infra is required for Story 10.2's 4 chart widgets. **Do not block Story 10.1 on E7-T2.**

### E7-P2: Architect pre-flight for Cubit with collection-index state

`E7-P2` (Category B ongoing process) flags architect review for "Cubit/BLoC stories with collection-index state". Story 10.1 uses a `List<SessionHistoryEntry>` — no index manipulation, no heroIndex, no completedIndices set. The risk E7-P2 guards against (off-by-one index drift across concurrent operations) does not apply here. Record this non-triggering in the Dev Agent Record.

### Test Data Helpers for `10.1-DATA-002` through `10.1-DATA-005`

To create a valid `DailyPlan` row in the in-memory DB:
```dart
import 'dart:convert';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

final plan = DailyPlan(
  date: '2026-05-24',
  sessions: [
    const PlannedSession(
      sessionType: 'cardio',
      intensity: 5,
      durationMinutes: 20,
      isIndoor: true,
    ),
  ],
  aiExplanation: 'test',
);

final planId = await dailyPlansDao.insertPlan(
  DailyPlansCompanion.insert(
    planDate: plan.date,
    planJson: jsonEncode(plan.toJson()),
    generatedAt: DateTime.now(),
    createdAt: DateTime.now(),
  ),
);
```

Then insert a `SessionLog` referencing `planId` at `sessionIndex: 0`.

**Important**: `DailyPlan` may have required fields beyond `date`, `sessions`, `aiExplanation`. Run `dart analyze` to catch any missing fields and check the actual class before finalising test data.

### `isClosed` guard pattern (E8-P1 invariant)

Every `emit` in `ProgressCubit.load()` is guarded by `if (!isClosed)`. This is the standard cubit-lifecycle invariant enforced since Epic 8 (see `in_session_cubit.dart` as reference). The `fold` callback is synchronous after the `await`, so there is one guard per branch.

### No `progressStats` entity or use case in this story

The architecture spec shows `progress_stats.dart` and `get_progress_stats.dart` in the directory. Do NOT create them in Story 10.1 — they belong to Story 10.2 (Progress Charts). Create the `domain/entities/` and `domain/usecases/` placeholder `.gitkeep` files or leave the directories empty; do not introduce stub classes.

### `_HistoryList.entries` type annotation correction

In Task 11's `_HistoryList`, set the field type to:
```dart
final List<SessionHistoryEntry> entries;
```
Import `session_history_entry.dart` at the top of `progress_page.dart`. The generic `List` in the inline code above is a placeholder to prevent copy-paste truncation — always use the typed version.

### Italian labels

The app is locale-locked to `it` (`locale: const Locale('it')` in `lib/app.dart`). All user-visible text in this story uses Italian directly:
- `'Mobilità'`, `'Cardio'`, `'Respirazione'`
- `'(abbandonata)'` suffix in subtitle
- Empty-state text: `'Nessuna sessione ancora. Inizia la tua prima oggi!'`
- Error text: `'Impossibile caricare la cronologia'`

ARB key wiring (like Story 7.5) is deferred — do NOT create new ARB keys in this story.

### Import convention reminder

Always use **project-relative imports**:
```dart
import 'package:pulse_coach/features/progress/...';
```
Never use relative `../../` imports, except within the same feature folder (and even then, project-relative is preferred).

### `app_logger.dart` is already shipped

`AppLogger` (static, no DI, import directly) is in `lib/core/logging/app_logger.dart` — created in Story 10.0. Use `AppLogger.error(...)`, `AppLogger.warning(...)` where needed. Do NOT use `debugPrint` or `developer.log`.

### References

- Epics.md Story 10.1: `_bmad-output/planning-artifacts/epics.md`
- Architecture spec: `_bmad-output/planning-artifacts/architecture.md` (progress feature directory structure)
- UX spec (empty-state rule): `_bmad-output/planning-artifacts/ux-design-specification.md` ("No empty states with illustrations")
- UX spec (shimmer): `_bmad-output/planning-artifacts/ux-design-specification.md` ("Progress screen: chart area shimmer + stat card shimmer placeholders")
- Previous story (10.0): `_bmad-output/implementation-artifacts/10-0-centralized-logger-and-error-path-convergence.md`
- `SessionLogsDao`: `pulse_coach/lib/core/database/daos/session_logs_dao.dart`
- `DailyPlansDao`: `pulse_coach/lib/core/database/daos/daily_plans_dao.dart` (already has `getPlanById`)
- `RpeFeedbackDao`: `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart`
- `PlannedSession`: `pulse_coach/lib/features/daily_plan/domain/entities/planned_session.dart`
- `DailyPlan`: `pulse_coach/lib/features/daily_plan/domain/entities/daily_plan.dart`
- `ShimmerPlaceholder`: `pulse_coach/lib/shared/widgets/shimmer_placeholder.dart`
- `AppLogger`: `pulse_coach/lib/core/logging/app_logger.dart`
- `Failure`, `CacheFailure`: `pulse_coach/lib/core/error/failures.dart`
- DI config: `pulse_coach/lib/core/di/injection.config.dart` (auto-generated; do NOT edit manually)
- DI module: `pulse_coach/lib/core/di/injection.dart`
- Sprint status: `_bmad-output/implementation-artifacts/sprint-status.yaml`
- Action item ledger: `_bmad-output/implementation-artifacts/action-item-ledger.md`
- Project context (rules): `_bmad-output/project-context.md`

## Review Findings

_Code review 2026-05-24 (adversarial: Blind Hunter + Edge Case Hunter + Acceptance Auditor). All AC1–AC6 verified SATISFIED by the Acceptance Auditor; findings below are quality/robustness issues, not AC violations._

### Decision needed

- [x] [Review][Decision] **RESOLVED → patch applied (`@injectable`).** `ProgressCubit` lifecycle: `@lazySingleton` is closed by `BlocProvider` on tab exit — `lib/features/progress/presentation/bloc/progress_cubit.dart:7`, `lib/features/progress/presentation/pages/progress_page.dart:16`. `ProgressCubit` is `@lazySingleton`, but `ProgressPage` provides it via `BlocProvider(create: (_) => getIt<ProgressCubit>()..load())`. `BlocProvider` closes the cubit it creates on dispose. The shell uses `const ProgressPage()` (no `IndexedStack` keep-alive), so leaving the Progress tab disposes the provider and `close()`s the singleton; the next visit reuses the **closed** singleton, every `emit` is swallowed by the `if (!isClosed)` guards, and the page is stuck on the shimmer/initial frame forever. Sibling cubits (`DailyPlanBloc`, `TodaySessionCubit`) are `@injectable` (factory), so they don't hit this. The spec's stated rationale ("Progress tab persists in the bottom nav shell; a single shared instance is correct") is incorrect for the current go_router shell. Two legitimate fixes — see decision options. Found by blind+edge.

### Patches

- [x] [Review][Patch] Abandoned-session subtitle misreports duration [`lib/features/progress/presentation/widgets/session_history_tile.dart:_subtitleText`]. Two cases: (a) abandoned with `elapsedSeconds` 1–59 renders `0min (abbandonata)` (integer truncation); (b) abandoned with `elapsedSeconds == null` falls through to `${durationMinutes}min` — showing the **planned** full duration with no "(abbandonata)" marker, mislabeling an abandoned session as completed-length. Fix: branch on `abandoned` first; show `<1 min` for sub-minute elapsed; always append the abandoned marker when `abandoned == true`. Found by blind+edge.
- [x] [Review][Patch] Non-deterministic tie-break in history ordering [`lib/core/database/daos/session_logs_dao.dart:getAllLogsOrderedByDate`]. `orderBy([desc(completedAt)])` only — two rows with an identical `completedAt` reorder unpredictably between loads. Fix: add a secondary `OrderingTerm.desc(t.id)`. Found by edge.
- [x] [Review][Patch] Two defensive skip branches untested [`lib/features/progress/data/datasources/progress_local_data_source.dart`]. The most fragile branches — `sessionIndex` out-of-range skip and `planJson` parse-failure skip — have zero test coverage (only the missing-plan case `10.1-DATA-004` exists). A regression flipping skip→throw would pass CI. Fix: add `10.1-DATA-006/007` for out-of-range index and corrupt JSON. Found by blind.

### Deferred (pre-existing pattern / out of scope)

- [x] [Review][Defer] N+1 query pattern in `getSessionHistory` [`lib/features/progress/data/datasources/progress_local_data_source.dart`] — per-log `getPlanById` + `jsonDecode` + `getBySessionLogId`, no memoization by `dailyPlanId`, no `LIMIT`/pagination. Performance only; history is small at this milestone. Deferred — optimize alongside Story 10.2 charts if it surfaces. Found by blind+edge.
- [x] [Review][Defer] `completedAt` rendered with local `.day/.month/.year` without `.toLocal()` [`lib/features/progress/presentation/widgets/session_history_tile.dart:_formatDate`] — sessions near midnight may show the wrong calendar date depending on TZ. Deferred — systemic: no widget in the app uses `toLocal()`/`intl` yet; fix app-wide when `intl` date formatting lands. Found by edge.
- [x] [Review][Defer] No retry affordance on `ProgressHistoryError` [`lib/features/progress/presentation/pages/progress_page.dart:_ErrorState`] — user is stuck on the error text with no in-tab reload. UX enhancement, not in AC5. Deferred. Found by edge.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `flutter test test/data/progress/progress_local_data_source_test.dart` — RED failed as expected before implementation because `ProgressLocalDataSource` did not exist.
- `dart run build_runner build --delete-conflicting-outputs` — generated Freezed, Mockito mocks, Drift DAO updates, and injectable config.
- `flutter test test/data/progress/progress_local_data_source_test.dart test/bloc/progress_cubit_test.dart test/widget/progress/progress_page_test.dart` — passed `15/15`.
- `flutter analyze` — passed with `No issues found!`.
- `flutter test test/widget/app_shell_test.dart test/widget/pages_smoke_test.dart` — passed after registering a Progress test dependency.
- `flutter test` — passed `705/705`.

### Completion Notes List

- Added read-only Progress history domain, data, repository, use case, cubit, state, and timeline UI.
- Added DAO lookups for all session logs in reverse chronological order and RPE by `sessionLogId`.
- Implemented defensive history assembly from `session_logs` + `daily_plans.planJson` + `rpe_feedback`, skipping corrupt/missing plan rows with `AppLogger` warnings/errors.
- Replaced the Progress placeholder with shimmer loading rows, empty state text, error state text, and session timeline tiles.
- Chose the AC2 visual distinction approach of reduced opacity (`0.45`) for abandoned sessions.
- Added data, cubit, and widget tests covering AC1-AC6, including no emit after `close()`.
- Updated shell/smoke tests to register a fake Progress dependency now that ProgressPage is DI-backed.
- E7-P2 non-triggering recorded: Story 10.1 stores a list of history entries but performs no collection-index mutation or concurrent index tracking.

### File List

**New files:**
- `pulse_coach/lib/features/progress/domain/entities/session_history_entry.dart`
- `pulse_coach/lib/features/progress/domain/entities/session_history_entry.freezed.dart` (generated)
- `pulse_coach/lib/features/progress/domain/repositories/progress_repository.dart`
- `pulse_coach/lib/features/progress/domain/usecases/get_session_history.dart`
- `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart`
- `pulse_coach/lib/features/progress/data/repositories/progress_repository_impl.dart`
- `pulse_coach/lib/features/progress/presentation/bloc/progress_state.dart`
- `pulse_coach/lib/features/progress/presentation/bloc/progress_cubit.dart`
- `pulse_coach/lib/features/progress/presentation/widgets/session_history_tile.dart`
- `pulse_coach/test/data/progress/progress_local_data_source_test.dart`
- `pulse_coach/test/bloc/progress_cubit_test.dart`
- `pulse_coach/test/bloc/progress_cubit_test.mocks.dart` (generated)
- `pulse_coach/test/widget/progress/progress_page_test.dart`

**Updated files:**
- `pulse_coach/lib/core/database/daos/session_logs_dao.dart` (add `getAllLogsOrderedByDate`)
- `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart` (add `getBySessionLogId`)
- `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart` (replace stub)
- `pulse_coach/lib/core/di/injection.config.dart` (auto-regenerated by build_runner)
- `pulse_coach/test/bloc/today_session_cubit_test.mocks.dart` (auto-regenerated mock for `SessionLogsDao`)
- `pulse_coach/test/widget/today_page_test.mocks.dart` (auto-regenerated mock for `SessionLogsDao`)
- `pulse_coach/test/widget/app_shell_test.dart` (register Progress test dependency)
- `pulse_coach/test/widget/pages_smoke_test.dart` (update Progress smoke baseline)
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/10-1-session-history-timeline.md`

### Change Log

- 2026-05-24: Implemented Story 10.1 session history timeline and moved story to review.
