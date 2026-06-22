import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final AppDatabase _db;
  final SupabaseClientProvider _supabase;

  AuthRepositoryImpl(this._dataSource, this._db, this._supabase) {
    cloudCohortReader = _defaultCloudCohortReader;
    cloudCohortWriter = _defaultCloudCohortWriter;
  }

  /// Overridable in tests to avoid real Supabase calls (EntitlementGate pattern).
  @visibleForTesting
  late Future<String?> Function(String userId) cloudCohortReader;

  /// Overridable in tests to avoid real Supabase calls.
  @visibleForTesting
  late Future<void> Function(String userId, String cohort) cloudCohortWriter;

  Future<String?> _defaultCloudCohortReader(String userId) async {
    final row = await _supabase.client
        .from('profiles')
        .select('install_cohort')
        .eq('id', userId)
        .maybeSingle();
    return row?['install_cohort'] as String?;
  }

  Future<void> _defaultCloudCohortWriter(String userId, String cohort) async {
    await _supabase.client.from('profiles').upsert(
      {'id': userId, 'install_cohort': cohort},
      onConflict: 'id',
    );
  }

  /// Best-effort cloud sync for installCohort on sign-in (NFR34).
  /// merge rule: pre_v2 wins; never downgrade.
  Future<void> _syncInstallCohort(String userId) async {
    try {
      final profile = await _db.userProfileDao.getProfile();
      final localCohort = profile?.installCohort;

      final cloudCohort = await cloudCohortReader(userId);

      final canonical =
          (cloudCohort == 'pre_v2' || localCohort == 'pre_v2')
              ? 'pre_v2'
              : 'post_v2';

      await cloudCohortWriter(userId, canonical);

      if (localCohort != canonical) {
        await _db.userProfileDao.updateInstallCohort(canonical);
      }
    } catch (e) {
      // Best-effort sync (NFR34): never block sign-in, but surface the
      // failure in debug builds so a broken grandfathering sync is diagnosable.
      debugPrint('installCohort sync failed: $e — sign-in unaffected');
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithApple() async {
    try {
      final user = await _dataSource.signInWithApple();
      unawaited(_syncInstallCohort(user.id));
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      unawaited(_syncInstallCohort(user.id));
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user =
          await _dataSource.signInWithEmail(email: email, password: password);
      unawaited(_syncInstallCohort(user.id));
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser?>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signUp(email: email, password: password);
      return Right(user); // null means unconfirmed
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<AuthUser?> getSignedInUser() async {
    try {
      return _dataSource.getSignedInUser();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> deleteAccount() async {
    try {
      await _dataSource.deleteAccount();
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, String>> exportData() async {
    try {
      final json = await _dataSource.exportData();
      return Right(json);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
