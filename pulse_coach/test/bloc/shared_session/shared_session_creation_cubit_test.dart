// [20.1-CUBIT-001..005] SharedSessionCreationCubit tests
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/create_shared_session_use_case.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_creation_cubit.dart';

@GenerateMocks([CreateSharedSessionUseCase])
import 'shared_session_creation_cubit_test.mocks.dart';

final _kSession = SharedSession(
  id: 'sess-uuid',
  hostUserId: 'user-uuid',
  joinCode: 'ABC123',
  status: 'waiting',
  createdAt: DateTime(2026, 6, 25),
);

void main() {
  late MockCreateSharedSessionUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockCreateSharedSessionUseCase();
  });

  group('SharedSessionCreationCubit (20.1)', () {
    blocTest<SharedSessionCreationCubit, SharedSessionCreationState>(
      '20.1-CUBIT-001: initial state is initial',
      build: () => SharedSessionCreationCubit(mockUseCase),
      expect: () => [],
    );

    blocTest<SharedSessionCreationCubit, SharedSessionCreationState>(
      '20.1-CUBIT-002: create() → creating → created on success (AC1)',
      build: () => SharedSessionCreationCubit(mockUseCase),
      setUp: () {
        when(mockUseCase.call(hostUserId: anyNamed('hostUserId')))
            .thenAnswer((_) async => Right(_kSession));
      },
      act: (c) => c.create(hostUserId: 'user-uuid'),
      expect: () => [
        const SharedSessionCreationState.creating(),
        const SharedSessionCreationState.created(
          sessionId: 'sess-uuid',
          joinCode: 'ABC123',
        ),
      ],
    );

    blocTest<SharedSessionCreationCubit, SharedSessionCreationState>(
      '20.1-CUBIT-003: create() → creating → error on failure (E18R-CB2)',
      build: () => SharedSessionCreationCubit(mockUseCase),
      setUp: () {
        when(mockUseCase.call(hostUserId: anyNamed('hostUserId')))
            .thenAnswer((_) async =>
                const Left(ServerFailure('create_failed')));
      },
      act: (c) => c.create(hostUserId: 'user-uuid'),
      expect: () => [
        const SharedSessionCreationState.creating(),
        isA<SharedSessionCreationState>().having(
          (s) => s,
          'is error',
          isA<dynamic>().having(
            (s) => s.runtimeType.toString(),
            'type',
            contains('Error'),
          ),
        ),
      ],
    );

    blocTest<SharedSessionCreationCubit, SharedSessionCreationState>(
      '20.1-CUBIT-004: create() passes hostUserId to use case',
      build: () => SharedSessionCreationCubit(mockUseCase),
      setUp: () {
        when(mockUseCase.call(hostUserId: anyNamed('hostUserId')))
            .thenAnswer((_) async => Right(_kSession));
      },
      act: (c) => c.create(hostUserId: 'specific-user-id'),
      verify: (_) {
        verify(mockUseCase.call(hostUserId: 'specific-user-id')).called(1);
      },
    );

    test(
      '20.1-CUBIT-005: second create() while one is in-flight is ignored (guard)',
      () async {
        final completer = Completer<Either<Failure, SharedSession>>();
        when(mockUseCase.call(hostUserId: anyNamed('hostUserId')))
            .thenAnswer((_) => completer.future);
        final cubit = SharedSessionCreationCubit(mockUseCase);

        // First call enters `creating` and awaits the (still pending) insert.
        unawaited(cubit.create(hostUserId: 'user-uuid'));
        await Future<void>.delayed(Duration.zero);
        // Second call while `creating` must be a no-op.
        unawaited(cubit.create(hostUserId: 'user-uuid'));
        await Future<void>.delayed(Duration.zero);

        completer.complete(Right(_kSession));
        await Future<void>.delayed(Duration.zero);

        verify(mockUseCase.call(hostUserId: anyNamed('hostUserId'))).called(1);
        await cubit.close();
      },
    );
  });
}
