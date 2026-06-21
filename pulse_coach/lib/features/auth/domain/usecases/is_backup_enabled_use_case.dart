import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/auth/domain/repositories/backup_repository.dart';

@injectable
class IsBackupEnabledUseCase {
  final BackupRepository _repository;
  IsBackupEnabledUseCase(this._repository);

  Future<bool> call() => _repository.isBackupEnabled();
}
