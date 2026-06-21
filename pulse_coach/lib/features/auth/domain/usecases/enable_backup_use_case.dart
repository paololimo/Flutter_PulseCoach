import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/repositories/backup_repository.dart';

@injectable
class EnableBackupUseCase {
  final BackupRepository _repository;
  EnableBackupUseCase(this._repository);

  Future<Either<BackupFailure, String>> call() =>
      _repository.enableBackupAndGetPhrase();
}
