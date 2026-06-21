import 'dart:convert';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/crypto/backup_envelope.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show FileOptions, SupabaseClientProvider;
import 'package:pulse_coach/core/error/failures.dart';

@injectable
class BackupRemoteDataSource {
  final SupabaseClientProvider _supabase;
  BackupRemoteDataSource(this._supabase);

  Future<void> uploadBackup({
    required String userId,
    required BackupEnvelope envelope,
  }) async {
    final bytes = Uint8List.fromList(
      utf8.encode(jsonEncode(envelope.toJson())),
    );
    await _supabase.client.storage
        .from('backups')
        .uploadBinary(
          '$userId/backup_v1.enc',
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
  }

  Future<BackupEnvelope> downloadBackup({required String userId}) async {
    final Uint8List bytes;
    try {
      bytes = await _supabase.client.storage
          .from('backups')
          .download('$userId/backup_v1.enc');
    } catch (_) {
      // Do not leak raw storage/network detail into a user-facing failure.
      throw const BackupFailure('Backup not found or could not be downloaded');
    }
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final envelope = BackupEnvelope.fromJson(json);
      if (envelope.schemaVersion != BackupEnvelope.supportedSchemaVersion) {
        throw const BackupFailure('Unsupported backup version');
      }
      return envelope;
    } on BackupFailure {
      rethrow;
    } catch (_) {
      throw const BackupFailure('Backup file is corrupt');
    }
  }
}
