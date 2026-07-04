import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/usecases/get_friends_leaderboard_use_case.dart';

import 'get_friends_leaderboard_use_case_test.mocks.dart';

@GenerateMocks([LeaderboardRepository])
void main() {
  late MockLeaderboardRepository mockRepository;
  late GetFriendsLeaderboardUseCase sut;

  setUp(() {
    mockRepository = MockLeaderboardRepository();
    sut = GetFriendsLeaderboardUseCase(mockRepository);
  });

  test(
    '[21.2-USECASE-001] delegates to repository.getFriendsLeaderboard() and returns its result verbatim',
    () async {
      const expected = Right<
        Never,
        List<
          ({String userId, String displayHandle, int totalPoints, bool isOwn})
        >
      >([
        (userId: 'u1', displayHandle: 'alice', totalPoints: 30, isOwn: true),
      ]);
      when(mockRepository.getFriendsLeaderboard()).thenAnswer((_) async => expected);

      final result = await sut();

      expect(result, expected);
      verify(mockRepository.getFriendsLeaderboard()).called(1);
    },
  );
}
