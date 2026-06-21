import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/usecases/backup_now_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/disable_backup_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/enable_backup_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/is_backup_enabled_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/restore_backup_use_case.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';

part 'backup_bloc.freezed.dart';
part 'backup_event.dart';
part 'backup_state.dart';

@injectable
class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final EnableBackupUseCase _enableBackup;
  final DisableBackupUseCase _disableBackup;
  final BackupNowUseCase _backupNow;
  final RestoreBackupUseCase _restoreBackup;
  final IsBackupEnabledUseCase _isBackupEnabled;
  final AuthBloc _authBloc;

  BackupBloc(
    this._enableBackup,
    this._disableBackup,
    this._backupNow,
    this._restoreBackup,
    this._isBackupEnabled,
    this._authBloc,
  ) : super(const BackupState.initial()) {
    on<BackupStarted>(_onStarted);
    on<BackupToggled>(_onToggled);
    on<BackupDisabled>(_onDisabled);
    on<BackupPhraseAcknowledged>(_onPhraseAcknowledged);
    on<BackupNowRequested>(_onBackupNow);
    on<RestoreRequested>(_onRestoreRequested);
  }

  Future<void> _onStarted(
    BackupStarted event,
    Emitter<BackupState> emit,
  ) async {
    // Reflect persisted enabled-state when the page (re)opens.
    if (await _isBackupEnabled.call()) {
      emit(const BackupState.backupEnabled());
    }
  }

  Future<void> _onToggled(
    BackupToggled event,
    Emitter<BackupState> emit,
  ) async {
    if (state is BackupLoading) return;
    emit(const BackupState.loading());
    final result = await _enableBackup.call();
    result.fold(
      (failure) => emit(BackupState.error(failure: failure)),
      (phrase) => emit(BackupState.awaitingPhraseAck(phrase: phrase)),
    );
  }

  Future<void> _onDisabled(
    BackupDisabled event,
    Emitter<BackupState> emit,
  ) async {
    if (state is BackupLoading) return;
    final result = await _disableBackup.call();
    result.fold(
      (failure) => emit(BackupState.error(failure: failure)),
      (_) => emit(const BackupState.initial()),
    );
  }

  void _onPhraseAcknowledged(
    BackupPhraseAcknowledged event,
    Emitter<BackupState> emit,
  ) {
    emit(const BackupState.backupEnabled());
  }

  Future<void> _onBackupNow(
    BackupNowRequested event,
    Emitter<BackupState> emit,
  ) async {
    if (state is BackupLoading) return;
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      emit(const BackupState.error(failure: BackupFailure('Not authenticated')));
      return;
    }
    emit(const BackupState.loading());
    final result = await _backupNow.call(userId: authState.user.id);
    result.fold(
      (failure) => emit(BackupState.error(failure: failure)),
      (createdAt) => createdAt == null
          ? emit(const BackupState.queued())
          : emit(BackupState.backupComplete(lastBackup: createdAt)),
    );
  }

  Future<void> _onRestoreRequested(
    RestoreRequested event,
    Emitter<BackupState> emit,
  ) async {
    if (state is BackupLoading) return;
    final authState = _authBloc.state;
    if (authState is! AuthAuthenticated) {
      emit(const BackupState.error(failure: BackupFailure('Not authenticated')));
      return;
    }
    emit(const BackupState.loading());
    final result = await _restoreBackup.call(
      userId: authState.user.id,
      phrase: event.phrase,
    );
    result.fold(
      (failure) => emit(BackupState.error(failure: failure)),
      (_) => emit(const BackupState.restoreSuccess()),
    );
  }
}
