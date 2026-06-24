// [18.2-BLOC-001..009] FriendsBloc tests
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/friend_item.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/pending_requests.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/friends_repository.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/accept_request_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/decline_request_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/get_friends_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/get_pending_requests_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/remove_friend_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/search_by_handle_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/send_friend_request_use_case.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/friends_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/friends_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/friends_state.dart';

import 'friends_bloc_test.mocks.dart';

@GenerateMocks([FriendsRepository])
void main() {
  late MockFriendsRepository mockRepo;
  late GetFriendsUseCase getFriends;
  late GetPendingRequestsUseCase getPendingRequests;
  late SearchByHandleUseCase searchByHandle;
  late SendFriendRequestUseCase sendRequest;
  late AcceptRequestUseCase acceptRequest;
  late DeclineRequestUseCase declineRequest;
  late RemoveFriendUseCase removeFriend;

  final tNow = DateTime(2026, 6, 1);

  final tFriend = FriendItem(
    friendshipId: 'fs-1',
    userId: 'user-a',
    displayHandle: 'ahandle',
    createdAt: tNow,
  );

  const tPending = PendingRequests(received: [], sent: []);

  const tSocialFailure = SocialFailure('network error');

  const tSearchProfile = SocialProfile(
    userId: 'user-b',
    displayHandle: 'bhandle',
    visibilityTier: VisibilityTier.friendsOnly,
  );

  setUp(() {
    mockRepo = MockFriendsRepository();
    getFriends = GetFriendsUseCase(mockRepo);
    getPendingRequests = GetPendingRequestsUseCase(mockRepo);
    searchByHandle = SearchByHandleUseCase(mockRepo);
    sendRequest = SendFriendRequestUseCase(mockRepo);
    acceptRequest = AcceptRequestUseCase(mockRepo);
    declineRequest = DeclineRequestUseCase(mockRepo);
    removeFriend = RemoveFriendUseCase(mockRepo);
  });

  FriendsBloc buildBloc() => FriendsBloc(
        getFriends,
        getPendingRequests,
        searchByHandle,
        sendRequest,
        acceptRequest,
        declineRequest,
        removeFriend,
      );

  void stubLoad({List<FriendItem>? friends, PendingRequests? pending}) {
    when(mockRepo.getFriends())
        .thenAnswer((_) async => Right(friends ?? [tFriend]));
    when(mockRepo.getPendingRequests())
        .thenAnswer((_) async => Right(pending ?? tPending));
  }

  group('FriendsLoaded', () {
    blocTest<FriendsBloc, FriendsState>(
      '18.2-BLOC-001: success → emits [loading, loaded]',
      build: () {
        stubLoad();
        return buildBloc();
      },
      act: (b) => b.add(const FriendsLoaded()),
      expect: () => [
        const FriendsState.loading(),
        FriendsState.loaded(friends: [tFriend], pendingRequests: tPending),
      ],
    );

    blocTest<FriendsBloc, FriendsState>(
      '18.2-BLOC-002: getFriends error → emits [loading, error]',
      build: () {
        when(mockRepo.getFriends())
            .thenAnswer((_) async => const Left(tSocialFailure));
        when(mockRepo.getPendingRequests())
            .thenAnswer((_) async => const Right(tPending));
        return buildBloc();
      },
      act: (b) => b.add(const FriendsLoaded()),
      expect: () => [
        const FriendsState.loading(),
        const FriendsState.error(failure: tSocialFailure),
      ],
    );
  });

  group('FriendSearchRequested', () {
    blocTest<FriendsBloc, FriendsState>(
      '18.2-BLOC-003: found → loaded with searchResult set',
      build: () {
        stubLoad();
        when(mockRepo.searchByHandle(any))
            .thenAnswer((_) async => const Right(tSearchProfile));
        return buildBloc();
      },
      seed: () => FriendsState.loaded(
        friends: [tFriend],
        pendingRequests: tPending,
      ),
      act: (b) => b.add(const FriendSearchRequested('bhandle')),
      // BLoC deduplicates equal states. The clear step emits loaded(searchResult=null)
      // which equals the seeded state, so it is swallowed. Only the final
      // loaded(searchResult=bhandle) is a new distinct state.
      expect: () => [
        FriendsState.loaded(
          friends: [tFriend],
          pendingRequests: tPending,
          searchResult: tSearchProfile,
          requestSent: false,
        ),
      ],
    );

    blocTest<FriendsBloc, FriendsState>(
      '18.2-BLOC-004: not found → loaded with searchResult null (no new states)',
      build: () {
        stubLoad();
        when(mockRepo.searchByHandle(any))
            .thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      seed: () => FriendsState.loaded(
        friends: [tFriend],
        pendingRequests: tPending,
      ),
      act: (b) => b.add(const FriendSearchRequested('nobody')),
      // BLoC deduplicates: both the clear step and the null result produce
      // the same state as the seed — neither is emitted.
      expect: () => const [],
    );
  });

  group('FriendRequestSent', () {
    blocTest<FriendsBloc, FriendsState>(
      '18.2-BLOC-005: success → loaded with requestSent=true',
      build: () {
        when(mockRepo.sendFriendRequest(any))
            .thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () => FriendsState.loaded(
        friends: [tFriend],
        pendingRequests: tPending,
        searchResult: tSearchProfile,
      ),
      act: (b) => b.add(const FriendRequestSent('user-b')),
      expect: () => [
        FriendsState.loaded(
          friends: [tFriend],
          pendingRequests: tPending,
          searchResult: tSearchProfile,
          requestSent: true,
        ),
      ],
    );

    blocTest<FriendsBloc, FriendsState>(
      '18.2-BLOC-006: failure → error emitted',
      build: () {
        when(mockRepo.sendFriendRequest(any))
            .thenAnswer((_) async => const Left(tSocialFailure));
        return buildBloc();
      },
      seed: () => FriendsState.loaded(
        friends: [tFriend],
        pendingRequests: tPending,
        searchResult: tSearchProfile,
      ),
      act: (b) => b.add(const FriendRequestSent('user-b')),
      expect: () => [
        const FriendsState.error(failure: tSocialFailure),
      ],
    );
  });

  group('FriendRequestAccepted', () {
    blocTest<FriendsBloc, FriendsState>(
      '18.2-BLOC-007: success → re-emits via FriendsLoaded (loading then loaded)',
      build: () {
        stubLoad();
        when(mockRepo.acceptRequest(any))
            .thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () =>
          FriendsState.loaded(friends: [tFriend], pendingRequests: tPending),
      act: (b) => b.add(const FriendRequestAccepted('fs-2')),
      expect: () => [
        const FriendsState.loading(),
        FriendsState.loaded(friends: [tFriend], pendingRequests: tPending),
      ],
    );
  });

  group('FriendRequestDeclined', () {
    blocTest<FriendsBloc, FriendsState>(
      '18.2-BLOC-008: success → re-emits via FriendsLoaded',
      build: () {
        stubLoad();
        when(mockRepo.declineRequest(any))
            .thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () =>
          FriendsState.loaded(friends: [tFriend], pendingRequests: tPending),
      act: (b) => b.add(const FriendRequestDeclined('fs-2')),
      expect: () => [
        const FriendsState.loading(),
        FriendsState.loaded(friends: [tFriend], pendingRequests: tPending),
      ],
    );
  });

  group('FriendRemoved', () {
    blocTest<FriendsBloc, FriendsState>(
      '18.2-BLOC-009: success → re-emits via FriendsLoaded',
      build: () {
        stubLoad();
        when(mockRepo.removeFriend(any))
            .thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () =>
          FriendsState.loaded(friends: [tFriend], pendingRequests: tPending),
      act: (b) => b.add(const FriendRemoved('fs-1')),
      expect: () => [
        const FriendsState.loading(),
        FriendsState.loaded(friends: [tFriend], pendingRequests: tPending),
      ],
    );
  });
}
