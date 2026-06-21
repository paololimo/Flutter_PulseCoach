import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/repositories/backup_repository.dart';

@injectable
class BackupNowUseCase {
  final BackupRepository _repository;
  BackupNowUseCase(this._repository);

  /// Returns `Right(null)` when queued (offline) or `Right(createdAt)` on
  /// a successful upload.
  Future<Either<BackupFailure, DateTime?>> call({required String userId}) =>
      _repository.backup(userId: userId);
}
