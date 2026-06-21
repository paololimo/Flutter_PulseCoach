import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/repositories/backup_repository.dart';

@injectable
class DisableBackupUseCase {
  final BackupRepository _repository;
  DisableBackupUseCase(this._repository);

  Future<Either<BackupFailure, Unit>> call() => _repository.disableBackup();
}
