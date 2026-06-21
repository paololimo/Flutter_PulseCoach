import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/crypto/e2e_backup_codec.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/data/datasources/backup_local_data_source.dart';
import 'package:pulse_coach/features/auth/data/datasources/backup_remote_data_source.dart';
import 'package:pulse_coach/features/auth/domain/repositories/backup_repository.dart';

@Injectable(as: BackupRepository)
class BackupRepositoryImpl implements BackupRepository {
  final BackupRemoteDataSource _remote;
  final BackupLocalDataSource _local;
  final E2eBackupCodec _codec;
  final Connectivity _connectivity;

  BackupRepositoryImpl(
    this._remote,
    this._local,
    this._codec,
    this._connectivity,
  );

  @override
  Future<Either<BackupFailure, String>> enableBackupAndGetPhrase() async {
    try {
      // Re-enabling must NOT regenerate the phrase/key: doing so would orphan
      // any existing cloud backup. Reuse the stored key when present.
      final existing = await _local.loadEncryptionKey();
      final phrase = existing ?? _generatePhrase();
      if (existing == null) {
        await _local.storeEncryptionKey(phrase);
      }
      await _local.setBackupEnabled(true);
      return Right(phrase);
    } catch (e) {
      return Left(BackupFailure(e.toString()));
    }
  }

  @override
  Future<Either<BackupFailure, Unit>> disableBackup() async {
    try {
      // Disabling stops future backups but keeps the local key and the cloud
      // copy intact (cloud deletion is handled by account deletion, Story 16.4).
      await _local.setBackupEnabled(false);
      return const Right(unit);
    } catch (e) {
      return Left(BackupFailure(e.toString()));
    }
  }

  @override
  Future<Either<BackupFailure, DateTime?>> backup({
    required String userId,
  }) async {
    try {
      if (await _isOffline()) {
        await _local.queueBackupTask(userId: userId);
        return const Right(null);
      }

      final phrase = await _local.loadEncryptionKey();
      if (phrase == null) {
        return const Left(BackupFailure('Backup not enabled'));
      }

      final payload = await _local.exportDriftSnapshot();
      final envelope = await _codec.encrypt(
        passphrase: phrase,
        payload: payload,
      );
      await _remote.uploadBackup(userId: userId, envelope: envelope);
      return Right(envelope.createdAt);
    } on BackupFailure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(BackupFailure(e.toString()));
    }
  }

  @override
  Future<Either<BackupFailure, Unit>> restore({
    required String userId,
    required String phrase,
  }) async {
    try {
      if (await _isOffline()) {
        return const Left(BackupFailure('No connection'));
      }
      final envelope = await _remote.downloadBackup(userId: userId);
      final payload = await _codec.decrypt(
        passphrase: phrase,
        envelope: envelope,
      );
      await _local.restoreDriftSnapshot(payload);
      return const Right(unit);
    } on BackupDecryptionFailure catch (f) {
      return Left(f);
    } on BackupFailure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(BackupFailure(e.toString()));
    }
  }

  @override
  Future<bool> isBackupEnabled() => _local.loadBackupEnabled();

  Future<bool> _isOffline() async {
    final connectivity = await _connectivity.checkConnectivity();
    return connectivity.contains(ConnectivityResult.none) &&
        connectivity.length == 1;
  }

  // Generates a recovery phrase as 6 groups of 4 hex chars: XXXX-XXXX-...-XXXX
  String _generatePhrase() {
    final rng = Random.secure();
    final bytes = Uint8List.fromList(List.generate(12, (_) => rng.nextInt(256)));
    final raw = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final groups = <String>[];
    for (var i = 0; i < raw.length; i += 4) {
      groups.add(raw.substring(i, i + 4));
    }
    return groups.join('-');
  }
}
