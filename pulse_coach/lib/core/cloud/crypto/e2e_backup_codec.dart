import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/crypto/backup_envelope.dart';
import 'package:pulse_coach/core/error/failures.dart';

@injectable
class E2eBackupCodec {
  static const _argon2Parallelism = 2;
  static const _argon2Memory = 65536; // 64 MiB
  static const _argon2Iterations = 3;

  Future<BackupEnvelope> encrypt({
    required String passphrase,
    required Map<String, dynamic> payload,
    Uint8List? saltOverride,
  }) async {
    final salt = saltOverride ?? _randomBytes(16);
    final secretKey = await _deriveKey(passphrase, salt);
    final jsonBytes = utf8.encode(jsonEncode(payload));
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(jsonBytes, secretKey: secretKey);
    // Append GCM mac tag to ciphertext for compact storage
    final cipherWithMac = Uint8List.fromList(
      secretBox.cipherText + secretBox.mac.bytes,
    );
    return BackupEnvelope(
      schemaVersion: 1,
      createdAt: DateTime.now().toUtc(),
      argon2Salt: base64.encode(salt),
      iv: base64.encode(secretBox.nonce),
      ciphertext: base64.encode(cipherWithMac),
    );
  }

  Future<Map<String, dynamic>> decrypt({
    required String passphrase,
    required BackupEnvelope envelope,
  }) async {
    try {
      final salt = base64.decode(envelope.argon2Salt);
      final secretKey = await _deriveKey(passphrase, salt);
      final raw = base64.decode(envelope.ciphertext);
      final iv = base64.decode(envelope.iv);
      // Ciphertext must contain at least the 16-byte GCM mac tag; a shorter
      // blob is a corrupt backup, not a wrong passphrase.
      if (raw.length < 16) {
        throw const BackupDecryptionFailure('Corrupt backup');
      }
      // Last 16 bytes = GCM mac tag
      final mac = Mac(raw.sublist(raw.length - 16));
      final cipherText = raw.sublist(0, raw.length - 16);
      final algorithm = AesGcm.with256bits();
      final plaintext = await algorithm.decrypt(
        SecretBox(cipherText, nonce: iv, mac: mac),
        secretKey: secretKey,
      );
      return jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupDecryptionFailure('Wrong recovery phrase or corrupt backup');
    }
  }

  Future<SecretKey> _deriveKey(String passphrase, Uint8List salt) async {
    final argon2 = Argon2id(
      parallelism: _argon2Parallelism,
      memory: _argon2Memory,
      iterations: _argon2Iterations,
      hashLength: 32,
    );
    return argon2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  Uint8List _randomBytes(int count) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(count, (_) => rng.nextInt(256)));
  }
}
