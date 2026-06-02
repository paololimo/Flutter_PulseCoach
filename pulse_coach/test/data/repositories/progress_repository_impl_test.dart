import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/data/datasources/progress_local_data_source.dart';
import 'package:pulse_coach/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

void main() {
  group('ProgressRepositoryImpl', () {
    late _FakeProgressLocalDataSource dataSource;
    late ProgressRepositoryImpl repository;

    setUp(() {
      dataSource = _FakeProgressLocalDataSource();
      repository = ProgressRepositoryImpl(dataSource);
    });

    test(
      '10.1-REPO-001: getSessionHistory returns Right(entries) on datasource success',
      () async {
        final completedAt = DateTime.utc(2026, 6, 2, 8);
        final entries = [
          SessionHistoryEntry(
            sessionLogId: 42,
            completedAt: completedAt,
            sessionType: 'cardio',
            durationMinutes: 12,
            abandoned: false,
            rpeValue: 6,
          ),
        ];
        dataSource.historyResult = entries;

        final result = await repository.getSessionHistory();

        expect(
          result,
          equals(Right<Failure, List<SessionHistoryEntry>>(entries)),
        );
        expect(dataSource.getSessionHistoryCalls, 1);
      },
    );

    test(
      '10.1-REPO-002: getSessionHistory returns CacheFailure on datasource exception',
      () async {
        dataSource.historyException = StateError('history unavailable');

        final result = await repository.getSessionHistory();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            const CacheFailure('progress_history_load_failed'),
          ),
          (_) => fail('Expected Left(CacheFailure)'),
        );
        expect(dataSource.getSessionHistoryCalls, 1);
      },
    );

    test(
      '10.2-REPO-001: getProgressStats returns Right(stats) on datasource success',
      () async {
        const stats = ProgressStats(
          completedCount: 3,
          abandonedCount: 1,
          minutesPerWeek: [WeeklyMinutes(weekLabel: '01/06', totalMinutes: 36)],
          rpeTrend: [],
          sessionTypeCounts: {'cardio': 2, 'mobility': 1},
          completedThisWeek: 2,
          weeklyTarget: 3,
        );
        dataSource.statsResult = stats;

        final result = await repository.getProgressStats();

        expect(result, equals(const Right<Failure, ProgressStats>(stats)));
        expect(dataSource.getProgressStatsCalls, 1);
      },
    );

    test(
      '10.2-REPO-002: getProgressStats returns CacheFailure on datasource exception',
      () async {
        dataSource.statsException = StateError('stats unavailable');

        final result = await repository.getProgressStats();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) =>
              expect(failure, const CacheFailure('progress_stats_load_failed')),
          (_) => fail('Expected Left(CacheFailure)'),
        );
        expect(dataSource.getProgressStatsCalls, 1);
      },
    );
  });
}

class _FakeProgressLocalDataSource implements ProgressLocalDataSource {
  List<SessionHistoryEntry> historyResult = const [];
  ProgressStats statsResult = const ProgressStats(
    completedCount: 0,
    abandonedCount: 0,
    minutesPerWeek: [],
    rpeTrend: [],
    sessionTypeCounts: {},
    completedThisWeek: 0,
    weeklyTarget: 3,
  );
  Object? historyException;
  Object? statsException;
  int getSessionHistoryCalls = 0;
  int getProgressStatsCalls = 0;

  @override
  Future<List<SessionHistoryEntry>> getSessionHistory() async {
    getSessionHistoryCalls++;
    final exception = historyException;
    if (exception != null) throw exception;
    return historyResult;
  }

  @override
  Future<ProgressStats> getProgressStats() async {
    getProgressStatsCalls++;
    final exception = statsException;
    if (exception != null) throw exception;
    return statsResult;
  }
}
