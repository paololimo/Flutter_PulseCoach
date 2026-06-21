part of 'backup_bloc.dart';

@freezed
sealed class BackupEvent with _$BackupEvent {
  const factory BackupEvent.started() = BackupStarted;
  const factory BackupEvent.toggled() = BackupToggled;
  const factory BackupEvent.disabled() = BackupDisabled;
  const factory BackupEvent.phraseAcknowledged() = BackupPhraseAcknowledged;
  const factory BackupEvent.backupNowRequested() = BackupNowRequested;
  const factory BackupEvent.restoreRequested({required String phrase}) =
      RestoreRequested;
}
