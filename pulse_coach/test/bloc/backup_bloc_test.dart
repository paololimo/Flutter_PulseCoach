import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/usecases/backup_now_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/disable_backup_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/enable_backup_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/is_backup_enabled_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/restore_backup_use_case.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/backup_bloc.dart';

import 'backup_bloc_test.mocks.dart';

@GenerateMocks([
  EnableBackupUseCase,
  DisableBackupUseCase,
  BackupNowUseCase,
  RestoreBackupUseCase,
  IsBackupEnabledUseCase,
  AuthBloc,
])
void main() {
  late MockEnableBackupUseCase mockEnableBackup;
  late MockDisableBackupUseCase mockDisableBackup;
  late MockBackupNowUseCase mockBackupNow;
  late MockRestoreBackupUseCase mockRestoreBackup;
  late MockIsBackupEnabledUseCase mockIsBackupEnabled;
  late MockAuthBloc mockAuthBloc;

  const tUser = AuthUser(
    id: 'user-123',
    email: 'test@example.com',
    isEmailConfirmed: true,
  );
  const tPhrase = 'a1b2-c3d4-e5f6-a7b8-c9d0-e1f2';
  final tBackupTime = DateTime.utc(2026, 6, 21, 10, 30);
  const tDecryptionFailure =
      BackupDecryptionFailure('Wrong recovery phrase or corrupt backup');

  setUp(() {
    mockEnableBackup = MockEnableBackupUseCase();
    mockDisableBackup = MockDisableBackupUseCase();
    mockBackupNow = MockBackupNowUseCase();
    mockRestoreBackup = MockRestoreBackupUseCase();
    mockIsBackupEnabled = MockIsBackupEnabledUseCase();
    mockAuthBloc = MockAuthBloc();

    // Provide dummy for sealed AuthState so Mockito can initialise the mock.
    provideDummy<AuthState>(const AuthState.initial());

    // Default: authenticated
    when(mockAuthBloc.state).thenReturn(
      const AuthState.authenticated(user: tUser),
    );
    // Default: not enabled (so the started event does not emit unexpectedly)
    when(mockIsBackupEnabled.call()).thenAnswer((_) async => false);
  });

  BackupBloc makeBloc() => BackupBloc(
    mockEnableBackup,
    mockDisableBackup,
    mockBackupNow,
    mockRestoreBackup,
    mockIsBackupEnabled,
    mockAuthBloc,
  );

  group('BackupStarted', () {
    blocTest<BackupBloc, BackupState>(
      'emits [backupEnabled] when backup is already enabled',
      build: makeBloc,
      setUp: () {
        when(mockIsBackupEnabled.call()).thenAnswer((_) async => true);
      },
      act: (bloc) => bloc.add(const BackupEvent.started()),
      expect: () => [const BackupState.backupEnabled()],
    );

    blocTest<BackupBloc, BackupState>(
      'emits nothing when backup is not enabled',
      build: makeBloc,
      act: (bloc) => bloc.add(const BackupEvent.started()),
      expect: () => <BackupState>[],
    );
  });

  group('BackupToggled', () {
    blocTest<BackupBloc, BackupState>(
      'emits [loading, awaitingPhraseAck] when enableBackup succeeds',
      build: makeBloc,
      setUp: () {
        when(mockEnableBackup.call()).thenAnswer(
          (_) async => const Right(tPhrase),
        );
      },
      act: (bloc) => bloc.add(const BackupEvent.toggled()),
      expect: () => [
        const BackupState.loading(),
        const BackupState.awaitingPhraseAck(phrase: tPhrase),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'emits [loading, error] when enableBackup fails',
      build: makeBloc,
      setUp: () {
        when(mockEnableBackup.call()).thenAnswer(
          (_) async => const Left(BackupFailure('storage error')),
        );
      },
      act: (bloc) => bloc.add(const BackupEvent.toggled()),
      expect: () => [
        const BackupState.loading(),
        const BackupState.error(failure: BackupFailure('storage error')),
      ],
    );
  });

  group('BackupDisabled', () {
    blocTest<BackupBloc, BackupState>(
      'emits [initial] when disableBackup succeeds',
      build: makeBloc,
      setUp: () {
        when(mockDisableBackup.call()).thenAnswer(
          (_) async => const Right(unit),
        );
      },
      act: (bloc) => bloc.add(const BackupEvent.disabled()),
      expect: () => [const BackupState.initial()],
    );
  });

  group('BackupPhraseAcknowledged', () {
    blocTest<BackupBloc, BackupState>(
      'emits [backupEnabled]',
      build: makeBloc,
      act: (bloc) => bloc.add(const BackupEvent.phraseAcknowledged()),
      expect: () => [const BackupState.backupEnabled()],
    );
  });

  group('BackupNowRequested', () {
    blocTest<BackupBloc, BackupState>(
      'emits [loading, backupComplete] when upload succeeds',
      build: makeBloc,
      setUp: () {
        when(mockBackupNow.call(userId: 'user-123')).thenAnswer(
          (_) async => Right(tBackupTime),
        );
      },
      act: (bloc) => bloc.add(const BackupEvent.backupNowRequested()),
      expect: () => [
        const BackupState.loading(),
        BackupState.backupComplete(lastBackup: tBackupTime),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'emits [loading, queued] when the backup was queued (offline)',
      build: makeBloc,
      setUp: () {
        when(mockBackupNow.call(userId: 'user-123')).thenAnswer(
          (_) async => const Right(null),
        );
      },
      act: (bloc) => bloc.add(const BackupEvent.backupNowRequested()),
      expect: () => [
        const BackupState.loading(),
        const BackupState.queued(),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'emits error when not authenticated',
      build: makeBloc,
      setUp: () {
        when(mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());
      },
      act: (bloc) => bloc.add(const BackupEvent.backupNowRequested()),
      expect: () => [
        const BackupState.error(failure: BackupFailure('Not authenticated')),
      ],
    );
  });

  group('RestoreRequested', () {
    blocTest<BackupBloc, BackupState>(
      'emits [loading, restoreSuccess] when phrase is correct',
      build: makeBloc,
      setUp: () {
        when(
          mockRestoreBackup.call(userId: 'user-123', phrase: tPhrase),
        ).thenAnswer((_) async => const Right(unit));
      },
      act: (bloc) =>
          bloc.add(const BackupEvent.restoreRequested(phrase: tPhrase)),
      expect: () => [
        const BackupState.loading(),
        const BackupState.restoreSuccess(),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'emits [loading, error(BackupDecryptionFailure)] when phrase is wrong',
      build: makeBloc,
      setUp: () {
        when(
          mockRestoreBackup.call(userId: 'user-123', phrase: 'wrong'),
        ).thenAnswer(
          (_) async => const Left(tDecryptionFailure),
        );
      },
      act: (bloc) =>
          bloc.add(const BackupEvent.restoreRequested(phrase: 'wrong')),
      expect: () => [
        const BackupState.loading(),
        const BackupState.error(failure: tDecryptionFailure),
      ],
    );
  });
}
