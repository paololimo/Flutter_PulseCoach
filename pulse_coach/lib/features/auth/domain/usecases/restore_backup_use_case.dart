import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/repositories/backup_repository.dart';

@injectable
class RestoreBackupUseCase {
  final BackupRepository _repository;
  RestoreBackupUseCase(this._repository);

  Future<Either<BackupFailure, Unit>> call({
    required String userId,
    required String phrase,
  }) => _repository.restore(userId: userId, phrase: phrase);
}
