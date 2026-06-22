// [16.3-REPO-001..008] BackupRepositoryImpl unit tests
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/cloud/crypto/backup_envelope.dart';
import 'package:pulse_coach/core/cloud/crypto/e2e_backup_codec.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/data/datasources/backup_local_data_source.dart';
import 'package:pulse_coach/features/auth/data/datasources/backup_remote_data_source.dart';
import 'package:pulse_coach/features/auth/data/repositories/backup_repository_impl.dart';

import 'backup_repository_impl_test.mocks.dart';

@GenerateMocks([
  BackupRemoteDataSource,
  BackupLocalDataSource,
  E2eBackupCodec,
  Connectivity,
])
void main() {
  late MockBackupRemoteDataSource mockRemote;
  late MockBackupLocalDataSource mockLocal;
  late MockE2eBackupCodec mockCodec;
  late MockConnectivity mockConnectivity;
  late BackupRepositoryImpl sut;

  const tUserId = 'user-123';
  const tPhrase = 'a1b2-c3d4-e5f6-a7b8-c9d0-e1f2';
  final tEnvelope = BackupEnvelope(
    schemaVersion: 1,
    createdAt: DateTime.utc(2026, 6, 22, 10),
    argon2Salt: 'dGVzdA==',
    iv: 'aXY=',
    ciphertext: 'Y2lwaGVy',
  );
  final tSnapshot = <String, dynamic>{
    'userProfile': <dynamic>[],
    'sessions': <dynamic>[],
    'sessionLogs': <dynamic>[],
    'rpeFeedback': <dynamic>[],
    'banditState': <dynamic>[],
    'behavioralState': <dynamic>[],
    'dailyPlans': <dynamic>[],
  };

  void stubOnline() {
    when(
      mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
  }

  void stubOffline() {
    when(
      mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
  }

  setUp(() {
    mockRemote = MockBackupRemoteDataSource();
    mockLocal = MockBackupLocalDataSource();
    mockCodec = MockE2eBackupCodec();
    mockConnectivity = MockConnectivity();
    sut = BackupRepositoryImpl(mockRemote, mockLocal, mockCodec, mockConnectivity);
  });

  // ── 16.3-REPO-001 ─────────────────────────────────────────────────────────
  group('enableBackupAndGetPhrase', () {
    test(
      '16.3-REPO-001: no existing key → generates phrase, stores it, enables backup, returns Right(phrase)',
      () async {
        when(mockLocal.loadEncryptionKey()).thenAnswer((_) async => null);
        when(
          mockLocal.storeEncryptionKey(any),
        ).thenAnswer((_) async {});
        when(mockLocal.setBackupEnabled(true)).thenAnswer((_) async {});

        final result = await sut.enableBackupAndGetPhrase();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (phrase) {
            expect(phrase, isNotEmpty);
            // Generated phrase has 6 groups of 4 hex chars separated by '-'
            expect(phrase.split('-'), hasLength(6));
          },
        );
        verify(mockLocal.storeEncryptionKey(any)).called(1);
        verify(mockLocal.setBackupEnabled(true)).called(1);
      },
    );

    test(
      '16.3-REPO-002: existing key → reuses stored phrase without regenerating',
      () async {
        when(
          mockLocal.loadEncryptionKey(),
        ).thenAnswer((_) async => tPhrase);
        when(mockLocal.setBackupEnabled(true)).thenAnswer((_) async {});

        final result = await sut.enableBackupAndGetPhrase();

        expect(result, equals(const Right<BackupFailure, String>(tPhrase)));
        verifyNever(mockLocal.storeEncryptionKey(any));
        verify(mockLocal.setBackupEnabled(true)).called(1);
      },
    );

    test(
      '16.3-REPO-003: exception → Left(BackupFailure)',
      () async {
        when(
          mockLocal.loadEncryptionKey(),
        ).thenThrow(Exception('secure storage error'));

        final result = await sut.enableBackupAndGetPhrase();

        expect(result.isLeft(), isTrue);
        result.fold((f) => expect(f, isA<BackupFailure>()), (_) => fail('Expected Left'));
      },
    );
  });

  // ── 16.3-REPO-004 ─────────────────────────────────────────────────────────
  group('disableBackup', () {
    test(
      '16.3-REPO-004: disables backup flag, keeps key intact → Right(unit)',
      () async {
        when(mockLocal.setBackupEnabled(false)).thenAnswer((_) async {});

        final result = await sut.disableBackup();

        expect(result, equals(const Right<BackupFailure, Unit>(unit)));
        verify(mockLocal.setBackupEnabled(false)).called(1);
        verifyNever(mockLocal.storeEncryptionKey(any));
      },
    );

    test(
      '16.3-REPO-004b: exception → Left(BackupFailure)',
      () async {
        when(
          mockLocal.setBackupEnabled(false),
        ).thenThrow(Exception('io error'));

        final result = await sut.disableBackup();

        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ── 16.3-REPO-005 ─────────────────────────────────────────────────────────
  group('backup', () {
    test(
      '16.3-REPO-005: offline → queues task and returns Right(null)',
      () async {
        stubOffline();
        when(
          mockLocal.queueBackupTask(userId: tUserId),
        ).thenAnswer((_) async {});

        final result = await sut.backup(userId: tUserId);

        expect(result, equals(const Right<BackupFailure, DateTime?>(null)));
        verify(mockLocal.queueBackupTask(userId: tUserId)).called(1);
        verifyNever(mockLocal.loadEncryptionKey());
      },
    );

    test(
      '16.3-REPO-006: online, no key → Left(BackupFailure "Backup not enabled")',
      () async {
        stubOnline();
        when(mockLocal.loadEncryptionKey()).thenAnswer((_) async => null);

        final result = await sut.backup(userId: tUserId);

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f.message, contains('not enabled')),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      '16.3-REPO-007: online, key present → encrypts, uploads, returns Right(createdAt)',
      () async {
        stubOnline();
        when(
          mockLocal.loadEncryptionKey(),
        ).thenAnswer((_) async => tPhrase);
        when(
          mockLocal.exportDriftSnapshot(),
        ).thenAnswer((_) async => tSnapshot);
        when(
          mockCodec.encrypt(passphrase: tPhrase, payload: tSnapshot),
        ).thenAnswer((_) async => tEnvelope);
        when(
          mockRemote.uploadBackup(userId: tUserId, envelope: tEnvelope),
        ).thenAnswer((_) async {});

        final result = await sut.backup(userId: tUserId);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (dt) => expect(dt, equals(tEnvelope.createdAt)),
        );
        verify(mockRemote.uploadBackup(userId: tUserId, envelope: tEnvelope)).called(1);
      },
    );

    test(
      '16.3-REPO-007b: online, upload throws generic exception → Left(BackupFailure)',
      () async {
        stubOnline();
        when(
          mockLocal.loadEncryptionKey(),
        ).thenAnswer((_) async => tPhrase);
        when(
          mockLocal.exportDriftSnapshot(),
        ).thenAnswer((_) async => tSnapshot);
        when(
          mockCodec.encrypt(passphrase: tPhrase, payload: tSnapshot),
        ).thenAnswer((_) async => tEnvelope);
        when(
          mockRemote.uploadBackup(userId: tUserId, envelope: tEnvelope),
        ).thenThrow(Exception('upload error'));

        final result = await sut.backup(userId: tUserId);

        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ── 16.3-REPO-008 ─────────────────────────────────────────────────────────
  group('restore', () {
    test(
      '16.3-REPO-008: offline → Left(BackupFailure "No connection")',
      () async {
        stubOffline();

        final result = await sut.restore(userId: tUserId, phrase: tPhrase);

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f.message, contains('No connection')),
          (_) => fail('Expected Left'),
        );
        verifyNever(mockRemote.downloadBackup(userId: anyNamed('userId')));
      },
    );

    test(
      '16.3-REPO-008b: online, correct phrase → downloads, decrypts, restores → Right(unit)',
      () async {
        stubOnline();
        when(
          mockRemote.downloadBackup(userId: tUserId),
        ).thenAnswer((_) async => tEnvelope);
        when(
          mockCodec.decrypt(passphrase: tPhrase, envelope: tEnvelope),
        ).thenAnswer((_) async => tSnapshot);
        when(
          mockLocal.restoreDriftSnapshot(tSnapshot),
        ).thenAnswer((_) async {});

        final result = await sut.restore(userId: tUserId, phrase: tPhrase);

        expect(result, equals(const Right<BackupFailure, Unit>(unit)));
        verify(mockLocal.restoreDriftSnapshot(tSnapshot)).called(1);
      },
    );

    test(
      '16.3-REPO-008c: online, wrong phrase → Left(BackupDecryptionFailure)',
      () async {
        stubOnline();
        when(
          mockRemote.downloadBackup(userId: tUserId),
        ).thenAnswer((_) async => tEnvelope);
        when(
          mockCodec.decrypt(passphrase: 'wrong-phrase', envelope: tEnvelope),
        ).thenThrow(
          const BackupDecryptionFailure('Wrong recovery phrase or corrupt backup'),
        );

        final result = await sut.restore(userId: tUserId, phrase: 'wrong-phrase');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<BackupDecryptionFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      '16.3-REPO-008d: online, download throws BackupFailure → propagated as Left',
      () async {
        stubOnline();
        when(
          mockRemote.downloadBackup(userId: tUserId),
        ).thenThrow(const BackupFailure('Backup not found or could not be downloaded'));

        final result = await sut.restore(userId: tUserId, phrase: tPhrase);

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<BackupFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );
  });

  // ── 16.3-REPO-009 ─────────────────────────────────────────────────────────
  group('isBackupEnabled', () {
    test(
      '16.3-REPO-009: delegates to local data source',
      () async {
        when(mockLocal.loadBackupEnabled()).thenAnswer((_) async => true);

        final result = await sut.isBackupEnabled();

        expect(result, isTrue);
        verify(mockLocal.loadBackupEnabled()).called(1);
      },
    );
  });
}
