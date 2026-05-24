import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_session_history.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_state.dart';

import 'progress_cubit_test.mocks.dart';

@GenerateMocks([GetSessionHistory])
void main() {
  group('ProgressCubit', () {
    late MockGetSessionHistory mockGetSessionHistory;
    late ProgressCubit cubit;

    setUp(() {
      mockGetSessionHistory = MockGetSessionHistory();
      cubit = ProgressCubit(mockGetSessionHistory);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('10.1-CUBIT-001: initial state is ProgressInitial', () {
      expect(cubit.state, isA<ProgressInitial>());
    });

    blocTest<ProgressCubit, ProgressState>(
      '10.1-CUBIT-002: load() emits [ProgressHistoryLoading, ProgressHistoryLoaded] on success',
      build: () {
        when(
          mockGetSessionHistory(),
        ).thenAnswer((_) async => const Right(<SessionHistoryEntry>[]));
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
          (_) async => const Left(CacheFailure('progress_history_load_failed')),
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
        when(mockGetSessionHistory()).thenAnswer((_) async => Right([entry]));
        return ProgressCubit(mockGetSessionHistory);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<ProgressHistoryLoading>(),
        isA<ProgressHistoryLoaded>().having(
          (state) => state.entries.length,
          'entries count',
          1,
        ),
      ],
    );

    test('10.1-CUBIT-005: load() does not emit after close', () async {
      final completer = Completer<Either<Failure, List<SessionHistoryEntry>>>();
      when(mockGetSessionHistory()).thenAnswer((_) => completer.future);
      final states = <ProgressState>[];
      final subscription = cubit.stream.listen(states.add);

      unawaited(cubit.load());
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      completer.complete(const Right(<SessionHistoryEntry>[]));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(states.whereType<ProgressHistoryLoaded>(), isEmpty);
      expect(states.whereType<ProgressHistoryError>(), isEmpty);
    });
  });
}
