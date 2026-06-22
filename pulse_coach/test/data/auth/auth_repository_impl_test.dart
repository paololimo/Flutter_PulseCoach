// [16.1-REPO-001..009] AuthRepositoryImpl unit tests
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pulse_coach/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([AuthRemoteDataSource])
void main() {
  late MockAuthRemoteDataSource mockDataSource;
  late AuthRepositoryImpl sut;

  const tUser = AuthUser(
    id: 'uid-1',
    email: 'user@example.com',
    isEmailConfirmed: true,
  );

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    sut = AuthRepositoryImpl(mockDataSource);
  });

  // ── 16.1-REPO-001 ─────────────────────────────────────────────────────────
  group('signInWithApple', () {
    test(
      '16.1-REPO-001: datasource success → Right(AuthUser)',
      () async {
        when(mockDataSource.signInWithApple()).thenAnswer((_) async => tUser);

        final result = await sut.signInWithApple();

        expect(result, equals(const Right<AuthFailure, AuthUser>(tUser)));
        verify(mockDataSource.signInWithApple()).called(1);
      },
    );

    test(
      '16.1-REPO-002: datasource throws → Left(AuthFailure)',
      () async {
        when(
          mockDataSource.signInWithApple(),
        ).thenThrow(Exception('apple error'));

        final result = await sut.signInWithApple();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );
  });

  // ── 16.1-REPO-003 ─────────────────────────────────────────────────────────
  group('signInWithGoogle', () {
    test(
      '16.1-REPO-003: datasource success → Right(AuthUser)',
      () async {
        when(mockDataSource.signInWithGoogle()).thenAnswer((_) async => tUser);

        final result = await sut.signInWithGoogle();

        expect(result, equals(const Right<AuthFailure, AuthUser>(tUser)));
      },
    );

    test(
      '16.1-REPO-004: datasource throws → Left(AuthFailure)',
      () async {
        when(
          mockDataSource.signInWithGoogle(),
        ).thenThrow(const AuthCancelledException());

        final result = await sut.signInWithGoogle();

        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ── 16.1-REPO-005 ─────────────────────────────────────────────────────────
  group('signInWithEmail', () {
    test(
      '16.1-REPO-005: datasource success → Right(AuthUser)',
      () async {
        when(
          mockDataSource.signInWithEmail(
            email: 'user@example.com',
            password: 'pw',
          ),
        ).thenAnswer((_) async => tUser);

        final result = await sut.signInWithEmail(
          email: 'user@example.com',
          password: 'pw',
        );

        expect(result, equals(const Right<AuthFailure, AuthUser>(tUser)));
      },
    );

    test(
      '16.1-REPO-006: datasource throws → Left(AuthFailure)',
      () async {
        when(
          mockDataSource.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(Exception('bad credentials'));

        final result = await sut.signInWithEmail(
          email: 'x@y.com',
          password: 'bad',
        );

        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ── 16.1-REPO-007 ─────────────────────────────────────────────────────────
  group('signUp', () {
    test(
      '16.1-REPO-007: datasource returns user → Right(AuthUser)',
      () async {
        when(
          mockDataSource.signUp(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => tUser);

        final result = await sut.signUp(
          email: 'new@example.com',
          password: 'pass',
        );

        expect(result, equals(const Right<AuthFailure, AuthUser?>(tUser)));
      },
    );

    test(
      '16.1-REPO-007b: datasource returns null (email confirmation pending) → Right(null)',
      () async {
        when(
          mockDataSource.signUp(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => null);

        final result = await sut.signUp(
          email: 'new@example.com',
          password: 'pass',
        );

        expect(result, equals(const Right<AuthFailure, AuthUser?>(null)));
      },
    );

    test(
      '16.1-REPO-007c: datasource throws → Left(AuthFailure)',
      () async {
        when(
          mockDataSource.signUp(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(Exception('email taken'));

        final result = await sut.signUp(
          email: 'taken@example.com',
          password: 'pass',
        );

        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ── 16.1-REPO-008 ─────────────────────────────────────────────────────────
  group('signOut', () {
    test(
      '16.1-REPO-008: datasource success → Right(unit)',
      () async {
        when(mockDataSource.signOut()).thenAnswer((_) async {});

        final result = await sut.signOut();

        expect(result, equals(const Right<AuthFailure, Unit>(unit)));
      },
    );

    test(
      '16.1-REPO-008b: datasource throws → Left(AuthFailure)',
      () async {
        when(mockDataSource.signOut()).thenThrow(Exception('network error'));

        final result = await sut.signOut();

        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ── 16.1-REPO-009 ─────────────────────────────────────────────────────────
  group('getSignedInUser', () {
    test(
      '16.1-REPO-009: datasource returns user → AuthUser',
      () async {
        when(mockDataSource.getSignedInUser()).thenReturn(tUser);

        final result = await sut.getSignedInUser();

        expect(result, equals(tUser));
      },
    );

    test(
      '16.1-REPO-009b: datasource returns null → null',
      () async {
        when(mockDataSource.getSignedInUser()).thenReturn(null);

        final result = await sut.getSignedInUser();

        expect(result, isNull);
      },
    );

    test(
      '16.1-REPO-009c: datasource throws → null (exception swallowed)',
      () async {
        when(mockDataSource.getSignedInUser()).thenThrow(Exception('sdk not initialised'));

        final result = await sut.getSignedInUser();

        expect(result, isNull);
      },
    );
  });

  // ── 16.4-REPO-001 ─────────────────────────────────────────────────────────
  group('deleteAccount', () {
    test(
      '16.4-REPO-001: datasource success → Right(unit)',
      () async {
        when(mockDataSource.deleteAccount()).thenAnswer((_) async {});

        final result = await sut.deleteAccount();

        expect(result, equals(const Right<AuthFailure, Unit>(unit)));
      },
    );

    test(
      '16.4-REPO-002: datasource throws → Left(AuthFailure)',
      () async {
        when(
          mockDataSource.deleteAccount(),
        ).thenThrow(Exception('function error'));

        final result = await sut.deleteAccount();

        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ── 16.4-REPO-003 ─────────────────────────────────────────────────────────
  group('exportData', () {
    test(
      '16.4-REPO-003: datasource success → Right(json string)',
      () async {
        when(
          mockDataSource.exportData(),
        ).thenAnswer((_) async => '{"sessions":[]}');

        final result = await sut.exportData();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (json) => expect(json, contains('sessions')),
        );
      },
    );

    test(
      '16.4-REPO-004: datasource throws → Left(AuthFailure)',
      () async {
        when(
          mockDataSource.exportData(),
        ).thenThrow(Exception('edge function error'));

        final result = await sut.exportData();

        expect(result.isLeft(), isTrue);
      },
    );
  });
}
