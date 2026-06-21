import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';

abstract interface class BackupRepository {
  Future<Either<BackupFailure, String>> enableBackupAndGetPhrase();
  Future<Either<BackupFailure, Unit>> disableBackup();

  /// Performs a backup. Returns `Right(null)` when the operation was queued
  /// for later (offline), or `Right(createdAt)` with the upload timestamp on
  /// success.
  Future<Either<BackupFailure, DateTime?>> backup({required String userId});
  Future<Either<BackupFailure, Unit>> restore({
    required String userId,
    required String phrase,
  });
  Future<bool> isBackupEnabled();
}
