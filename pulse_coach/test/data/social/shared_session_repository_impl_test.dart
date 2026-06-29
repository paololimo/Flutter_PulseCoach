// [20.1-REPO-001..009] SharedSessionRepositoryImpl — error-mapping unit tests.
// Exercises all four repository methods: createSharedSession, refreshJoinCode,
// deleteSharedSession, and joinSharedSession including the
// SessionAlreadyStartedFailure pass-through path.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/data/datasources/shared_session_remote_data_source.dart';
import 'package:pulse_coach/features/social/shared_session/data/models/shared_session_dto.dart';
import 'package:pulse_coach/features/social/shared_session/data/repositories/shared_session_repository_impl.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session.dart';

import 'shared_session_repository_impl_test.mocks.dart';

@GenerateMocks([SharedSessionRemoteDataSource])
void main() {
  late MockSharedSessionRemoteDataSource mockDataSource;
  late SharedSessionRepositoryImpl sut;

  const tDto = SharedSessionDto(
    id: 'sess-abc',
    hostUserId: 'user-123',
    joinCode: 'ABCXYZ',
    status: 'waiting',
    createdAt: '2026-06-29T10:00:00.000Z',
  );

  final tDomain = SharedSession(
    id: 'sess-abc',
    hostUserId: 'user-123',
    joinCode: 'ABCXYZ',
    status: 'waiting',
    createdAt: DateTime.parse('2026-06-29T10:00:00.000Z'),
  );

  setUp(() {
    mockDataSource = MockSharedSessionRemoteDataSource();
    sut = SharedSessionRepositoryImpl(mockDataSource);
  });

  group('createSharedSession', () {
    test('20.1-REPO-001: success → Right(SharedSession) with DTO mapped to domain',
        () async {
      when(mockDataSource.createSharedSession(hostUserId: anyNamed('hostUserId')))
          .thenAnswer((_) async => tDto);

      final result = await sut.createSharedSession(hostUserId: 'user-123');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (session) {
          expect(session.id, tDomain.id);
          expect(session.joinCode, tDomain.joinCode);
          expect(session.hostUserId, tDomain.hostUserId);
        },
      );
    });

    test('20.1-REPO-002: datasource throws → Left(ServerFailure)', () async {
      when(mockDataSource.createSharedSession(hostUserId: anyNamed('hostUserId')))
          .thenThrow(Exception('network error'));

      final result = await sut.createSharedSession(hostUserId: 'user-123');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('refreshJoinCode', () {
    test('20.1-REPO-003: success → Right(newCode)', () async {
      when(mockDataSource.refreshJoinCode(sessionId: anyNamed('sessionId')))
          .thenAnswer((_) async => 'NEWCOD');

      final result = await sut.refreshJoinCode(sessionId: 'sess-abc');

      expect(result, const Right<Failure, String>('NEWCOD'));
    });

    test('20.1-REPO-004: datasource throws → Left(ServerFailure)', () async {
      when(mockDataSource.refreshJoinCode(sessionId: anyNamed('sessionId')))
          .thenThrow(Exception('rls deny'));

      final result = await sut.refreshJoinCode(sessionId: 'sess-abc');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('deleteSharedSession', () {
    test('20.3-REPO-005: success → Right(unit)', () async {
      when(mockDataSource.deleteSharedSession(sessionId: anyNamed('sessionId')))
          .thenAnswer((_) async {});

      final result = await sut.deleteSharedSession(sessionId: 'sess-abc');

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('20.3-REPO-006: datasource throws → Left(ServerFailure)', () async {
      when(mockDataSource.deleteSharedSession(sessionId: anyNamed('sessionId')))
          .thenThrow(Exception('timeout'));

      final result = await sut.deleteSharedSession(sessionId: 'sess-abc');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('joinSharedSession', () {
    test('20.3-REPO-007: success → Right(SharedSession) with DTO mapped to domain',
        () async {
      when(mockDataSource.joinSharedSession(
        joinCode: anyNamed('joinCode'),
        userId: anyNamed('userId'),
      )).thenAnswer((_) async => tDto);

      final result = await sut.joinSharedSession(
        joinCode: 'ABCXYZ',
        userId: 'user-456',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (session) => expect(session.id, 'sess-abc'),
      );
    });

    test(
        '20.3-REPO-008: generic exception → Left(ServerFailure)',
        () async {
      when(mockDataSource.joinSharedSession(
        joinCode: anyNamed('joinCode'),
        userId: anyNamed('userId'),
      )).thenThrow(Exception('code not found'));

      final result = await sut.joinSharedSession(
        joinCode: 'BADCOD',
        userId: 'user-456',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test(
        '20.3-REPO-009: SessionAlreadyStartedFailure thrown by datasource → Left pass-through',
        () async {
      when(mockDataSource.joinSharedSession(
        joinCode: anyNamed('joinCode'),
        userId: anyNamed('userId'),
      )).thenThrow(const SessionAlreadyStartedFailure());

      final result = await sut.joinSharedSession(
        joinCode: 'STARTED',
        userId: 'user-456',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SessionAlreadyStartedFailure>()),
        (_) => fail('expected Left(SessionAlreadyStartedFailure)'),
      );
    });
  });
}
