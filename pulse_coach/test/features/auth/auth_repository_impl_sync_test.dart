// [17.2-SYNC-001..003] AuthRepositoryImpl._syncInstallCohort tests
// Uses in-memory Drift DB for local persistence.
// The Supabase cloud interaction is tested via the @visibleForTesting seams
// (cloudCohortReader / cloudCohortWriter) that AuthRepositoryImpl exposes,
// following the same pattern as EntitlementGate.isProFetcher.
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pulse_coach/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart';

import 'auth_repository_impl_sync_test.mocks.dart';

@GenerateMocks([AuthRemoteDataSource, SupabaseClientProvider])
void main() {
  late AppDatabase db;
  late MockAuthRemoteDataSource mockDataSource;
  late MockSupabaseClientProvider mockSupabase;
  late AuthRepositoryImpl sut;

  const tUser = AuthUser(
    id: 'uid-sync',
    email: 'sync@example.com',
    isEmailConfirmed: true,
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockDataSource = MockAuthRemoteDataSource();
    mockSupabase = MockSupabaseClientProvider();
  });

  tearDown(() async {
    await db.close();
  });

  AuthRepositoryImpl buildSut({
    required Future<String?> Function(String userId) cloudReader,
    required Future<void> Function(String userId, String cohort) cloudWriter,
  }) {
    final repo = AuthRepositoryImpl(mockDataSource, db, mockSupabase);
    repo.cloudCohortReader = cloudReader;
    repo.cloudCohortWriter = cloudWriter;
    return repo;
  }

  // ── 17.2-SYNC-001 ──────────────────────────────────────────────────────────
  group('_syncInstallCohort via signInWithEmail', () {
    test(
      '17.2-SYNC-001: local pre_v2 + cloud post_v2 → local unchanged, cloud written with pre_v2',
      () async {
        // Seed DB with pre_v2
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            installCohort: const Value('pre_v2'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        when(
          mockDataSource.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => tUser);

        final cloudWrites = <String>[];
        sut = buildSut(
          cloudReader: (_) async => 'post_v2',
          cloudWriter: (_, cohort) async => cloudWrites.add(cohort),
        );

        final result = await sut.signInWithEmail(
          email: 'sync@example.com',
          password: 'pw',
        );

        // Allow unawaited sync to complete
        await Future<void>.delayed(Duration.zero);

        expect(result.isRight(), isTrue);
        // Cloud was written with canonical = pre_v2
        expect(cloudWrites, contains('pre_v2'));
        // Local still pre_v2 (no update needed)
        final profile = await db.userProfileDao.getProfile();
        expect(profile?.installCohort, equals('pre_v2'));
      },
    );

    // ── 17.2-SYNC-002 ────────────────────────────────────────────────────────
    test(
      '17.2-SYNC-002: local post_v2 + cloud pre_v2 → local updated to pre_v2',
      () async {
        // Seed DB with post_v2
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            installCohort: const Value('post_v2'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        when(
          mockDataSource.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => tUser);

        final cloudWrites = <String>[];
        sut = buildSut(
          cloudReader: (_) async => 'pre_v2',
          cloudWriter: (_, cohort) async => cloudWrites.add(cohort),
        );

        final result = await sut.signInWithEmail(
          email: 'sync@example.com',
          password: 'pw',
        );

        await Future<void>.delayed(Duration.zero);

        expect(result.isRight(), isTrue);
        // Cloud written with canonical = pre_v2
        expect(cloudWrites, contains('pre_v2'));
        // Local updated to pre_v2
        final profile = await db.userProfileDao.getProfile();
        expect(profile?.installCohort, equals('pre_v2'));
      },
    );

    // ── 17.2-SYNC-003 ────────────────────────────────────────────────────────
    test(
      '17.2-SYNC-003: cloud reader throws → sync swallowed, sign-in returns Right (NFR34)',
      () async {
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            installCohort: const Value('post_v2'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        when(
          mockDataSource.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => tUser);

        sut = buildSut(
          cloudReader: (_) async => throw Exception('network error'),
          cloudWriter: (_, cohort) async {},
        );

        final result = await sut.signInWithEmail(
          email: 'sync@example.com',
          password: 'pw',
        );

        await Future<void>.delayed(Duration.zero);

        expect(result, isA<Right<AuthFailure, AuthUser>>());
      },
    );
  });
}
