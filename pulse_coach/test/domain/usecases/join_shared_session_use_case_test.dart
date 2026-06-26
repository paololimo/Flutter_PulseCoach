// [20.3-JOIN-001..003] JoinSharedSessionUseCase tests
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session.dart';
import 'package:pulse_coach/features/social/shared_session/domain/repositories/shared_session_repository.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/join_shared_session_use_case.dart';

@GenerateMocks([SharedSessionRepository])
import 'join_shared_session_use_case_test.mocks.dart';

final _kSession = SharedSession(
  id: 'sess-uuid',
  hostUserId: 'host-uuid',
  joinCode: 'ABC123',
  status: 'waiting',
  createdAt: DateTime(2026, 6, 26),
);

void main() {
  late MockSharedSessionRepository mockRepo;
  late JoinSharedSessionUseCase useCase;

  setUp(() {
    mockRepo = MockSharedSessionRepository();
    useCase = JoinSharedSessionUseCase(mockRepo);
  });

  group('JoinSharedSessionUseCase (20.3)', () {
    test(
      '20.3-JOIN-001: success path returns Right(session) (AC2)',
      () async {
        when(mockRepo.joinSharedSession(
          joinCode: anyNamed('joinCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => Right(_kSession));

        final result = await useCase.call(
          joinCode: 'ABC123',
          userId: 'user-uuid',
        );

        expect(result, Right<Failure, SharedSession>(_kSession));
        verify(mockRepo.joinSharedSession(
          joinCode: 'ABC123',
          userId: 'user-uuid',
        )).called(1);
      },
    );

    test(
      '20.3-JOIN-002: already started — passes Left(SessionAlreadyStartedFailure) through (AC3)',
      () async {
        when(mockRepo.joinSharedSession(
          joinCode: anyNamed('joinCode'),
          userId: anyNamed('userId'),
        )).thenAnswer(
            (_) async => const Left(SessionAlreadyStartedFailure()));

        final result = await useCase.call(
          joinCode: 'ABC123',
          userId: 'user-uuid',
        );

        expect(result, const Left<Failure, SharedSession>(
          SessionAlreadyStartedFailure(),
        ));
      },
    );

    test(
      '20.3-JOIN-003: not found — passes Left(ServerFailure) through (AC4)',
      () async {
        when(mockRepo.joinSharedSession(
          joinCode: anyNamed('joinCode'),
          userId: anyNamed('userId'),
        )).thenAnswer(
            (_) async => const Left(ServerFailure('join_code_not_found')));

        final result = await useCase.call(
          joinCode: 'XXXXXX',
          userId: 'user-uuid',
        );

        expect(result, const Left<Failure, SharedSession>(
          ServerFailure('join_code_not_found'),
        ));
      },
    );
  });
}
