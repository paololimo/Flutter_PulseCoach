// [18.3-BLOC-001..006] FeedBloc tests
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';
import 'package:pulse_coach/features/social/feed/domain/repositories/feed_repository.dart';
import 'package:pulse_coach/features/social/feed/domain/usecases/get_feed_use_case.dart';
import 'package:pulse_coach/features/social/feed/domain/usecases/react_to_entry_use_case.dart';
import 'package:pulse_coach/features/social/feed/domain/usecases/revoke_feed_entry_use_case.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_bloc.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_event.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_state.dart';

import 'feed_bloc_test.mocks.dart';

@GenerateMocks([FeedRepository])
void main() {
  late MockFeedRepository mockRepo;
  late GetFeedUseCase getFeed;
  late ReactToEntryUseCase reactToEntry;
  late RevokeFeedEntryUseCase revokeEntry;

  final tNow = DateTime.utc(2026, 6, 24, 10, 0);

  final tEntry = FeedEntry(
    id: 'feed-1',
    ownerHandle: 'paolol',
    ownerId: 'user-abc',
    sessionType: 'cardio',
    durationMinutes: 25,
    completedAt: tNow,
    createdAt: tNow,
  );

  const tFailure = SocialFailure('network error');

  setUp(() {
    mockRepo = MockFeedRepository();
    getFeed = GetFeedUseCase(mockRepo);
    reactToEntry = ReactToEntryUseCase(mockRepo);
    revokeEntry = RevokeFeedEntryUseCase(mockRepo);
  });

  FeedBloc buildBloc() => FeedBloc(getFeed, reactToEntry, revokeEntry);

  group('FeedLoaded', () {
    blocTest<FeedBloc, FeedState>(
      '18.3-BLOC-001: FeedLoaded — success → [loading, loaded(entries)]',
      build: () {
        when(mockRepo.getFeed()).thenAnswer((_) async => Right([tEntry]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const FeedLoaded()),
      expect: () => [
        const FeedState.loading(),
        FeedState.loaded(entries: [tEntry]),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      '18.3-BLOC-002: FeedLoaded — getFeed error → [loading, error]',
      build: () {
        when(mockRepo.getFeed())
            .thenAnswer((_) async => const Left(tFailure));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const FeedLoaded()),
      expect: () => [
        const FeedState.loading(),
        const FeedState.error(failure: tFailure),
      ],
    );
  });

  group('FeedReactionSent', () {
    blocTest<FeedBloc, FeedState>(
      '18.3-BLOC-003: FeedReactionSent — adds to reactingIds optimistically, then removes on success',
      build: () {
        when(mockRepo.getFeed()).thenAnswer((_) async => Right([tEntry]));
        when(mockRepo.reactToEntry('feed-1'))
            .thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () => FeedState.loaded(entries: [tEntry]),
      act: (bloc) => bloc.add(const FeedReactionSent('feed-1')),
      expect: () => [
        FeedState.loaded(entries: [tEntry], reactingIds: {'feed-1'}),
        FeedState.loaded(entries: [tEntry]),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      '18.3-BLOC-004: FeedReactionSent — reactToEntry error → feed preserved, flag dropped (no error state)',
      build: () {
        when(mockRepo.reactToEntry('feed-1'))
            .thenAnswer((_) async => const Left(tFailure));
        return buildBloc();
      },
      seed: () => FeedState.loaded(entries: [tEntry]),
      act: (bloc) => bloc.add(const FeedReactionSent('feed-1')),
      // A light reaction is best-effort: a transient failure must NOT collapse
      // the loaded feed into an error/shimmer — it only drops the optimistic flag.
      expect: () => [
        FeedState.loaded(entries: [tEntry], reactingIds: {'feed-1'}),
        FeedState.loaded(entries: [tEntry]),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      '18.3-BLOC-004b: FeedReactionSent — duplicate tap while reacting is ignored (no second RPC)',
      build: () {
        when(mockRepo.reactToEntry('feed-1'))
            .thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () => FeedState.loaded(entries: [tEntry], reactingIds: {'feed-1'}),
      act: (bloc) => bloc.add(const FeedReactionSent('feed-1')),
      expect: () => const <FeedState>[],
      verify: (_) => verifyNever(mockRepo.reactToEntry('feed-1')),
    );
  });

  group('FeedEntryRevoked', () {
    blocTest<FeedBloc, FeedState>(
      '18.3-BLOC-005: FeedEntryRevoked — success → re-loads via FeedLoaded',
      build: () {
        when(mockRepo.revokeEntry('feed-1'))
            .thenAnswer((_) async => const Right(unit));
        when(mockRepo.getFeed()).thenAnswer((_) async => const Right([]));
        return buildBloc();
      },
      seed: () => FeedState.loaded(entries: [tEntry]),
      act: (bloc) => bloc.add(const FeedEntryRevoked('feed-1')),
      expect: () => [
        const FeedState.loading(),
        const FeedState.loaded(entries: []),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      '18.3-BLOC-006: FeedEntryRevoked — error → error state',
      build: () {
        when(mockRepo.revokeEntry('feed-1'))
            .thenAnswer((_) async => const Left(tFailure));
        return buildBloc();
      },
      seed: () => FeedState.loaded(entries: [tEntry]),
      act: (bloc) => bloc.add(const FeedEntryRevoked('feed-1')),
      expect: () => [
        const FeedState.error(failure: tFailure),
      ],
    );
  });
}
