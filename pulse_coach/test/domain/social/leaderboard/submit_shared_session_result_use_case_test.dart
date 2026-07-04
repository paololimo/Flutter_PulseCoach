import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/usecases/submit_shared_session_result_use_case.dart';

import 'submit_shared_session_result_use_case_test.mocks.dart';

@GenerateMocks([LeaderboardRepository])
void main() {
  late MockLeaderboardRepository mockRepository;
  late SubmitSharedSessionResultUseCase sut;

  setUp(() {
    mockRepository = MockLeaderboardRepository();
    sut = SubmitSharedSessionResultUseCase(mockRepository);
    when(
      mockRepository.submitSharedSessionResult(
        sessionId: anyNamed('sessionId'),
        rpe: anyNamed('rpe'),
        armKey: anyNamed('armKey'),
        durationMinutes: anyNamed('durationMinutes'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  test(
    '[21.3-USECASE-001] delegates to repository.submitSharedSessionResult(...) '
    'with all four args passed through verbatim',
    () async {
      await sut.call(
        sessionId: 'sess-1',
        rpe: 7,
        armKey: 'mobility_medium',
        durationMinutes: 20,
      );

      verify(
        mockRepository.submitSharedSessionResult(
          sessionId: 'sess-1',
          rpe: 7,
          armKey: 'mobility_medium',
          durationMinutes: 20,
        ),
      ).called(1);
    },
  );
}
