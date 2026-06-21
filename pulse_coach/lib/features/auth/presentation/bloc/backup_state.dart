part of 'backup_bloc.dart';

@freezed
sealed class BackupState with _$BackupState {
  const factory BackupState.initial() = BackupInitial;
  const factory BackupState.loading() = BackupLoading;
  const factory BackupState.awaitingPhraseAck({required String phrase}) =
      BackupAwaitingPhraseAck;
  const factory BackupState.backupEnabled() = BackupEnabled;
  const factory BackupState.backupComplete({required DateTime lastBackup}) =
      BackupComplete;
  const factory BackupState.queued() = BackupQueued;
  const factory BackupState.restoreSuccess() = BackupRestoreSuccess;
  const factory BackupState.error({required BackupFailure failure}) = BackupError;
}
