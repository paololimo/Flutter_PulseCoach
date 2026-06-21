import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/cloud/crypto/backup_envelope.dart';
import 'package:pulse_coach/core/cloud/crypto/e2e_backup_codec.dart';
import 'package:pulse_coach/core/error/failures.dart';

void main() {
  late E2eBackupCodec codec;

  setUp(() {
    codec = E2eBackupCodec();
  });

  group('BackupEnvelope', () {
    test('toJson / fromJson round-trip preserves all fields', () {
      final original = BackupEnvelope(
        schemaVersion: 1,
        createdAt: DateTime.utc(2026, 1, 15, 10, 30),
        argon2Salt: 'abc123==',
        iv: 'iv_base64==',
        ciphertext: 'cipher==',
      );

      final json = original.toJson();
      final restored = BackupEnvelope.fromJson(json);

      expect(restored.schemaVersion, equals(1));
      expect(restored.createdAt, equals(DateTime.utc(2026, 1, 15, 10, 30)));
      expect(restored.argon2Salt, equals('abc123=='));
      expect(restored.iv, equals('iv_base64=='));
      expect(restored.ciphertext, equals('cipher=='));
    });
  });

  group('E2eBackupCodec', () {
    const passphrase = 'correct-horse-battery-staple-abc123';
    const payload = {
      'userProfile': [
        {'id': 1, 'fitnessGoal': 'cardio'},
      ],
      'sessions': [],
    };

    test('encrypt → decrypt round-trip with correct phrase succeeds', () async {
      final envelope = await codec.encrypt(
        passphrase: passphrase,
        payload: payload,
      );

      expect(envelope.schemaVersion, equals(1));
      expect(envelope.argon2Salt, isNotEmpty);
      expect(envelope.iv, isNotEmpty);
      expect(envelope.ciphertext, isNotEmpty);

      final decrypted = await codec.decrypt(
        passphrase: passphrase,
        envelope: envelope,
      );

      expect(decrypted['userProfile'], isA<List>());
      final profile = (decrypted['userProfile'] as List).first;
      expect((profile as Map<String, dynamic>)['fitnessGoal'], equals('cardio'));
    });

    test('decrypt with wrong phrase throws BackupDecryptionFailure', () async {
      final envelope = await codec.encrypt(
        passphrase: passphrase,
        payload: payload,
      );

      expect(
        () async => codec.decrypt(
          passphrase: 'wrong-passphrase',
          envelope: envelope,
        ),
        throwsA(isA<BackupDecryptionFailure>()),
      );
    });

    test('encrypt with same salt override produces deterministic output', () async {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));

      final e1 = await codec.encrypt(
        passphrase: passphrase,
        payload: payload,
        saltOverride: salt,
      );
      final e2 = await codec.encrypt(
        passphrase: passphrase,
        payload: payload,
        saltOverride: salt,
      );

      // Same salt + same passphrase → same key. Different IVs produce different
      // ciphertexts, but both must decrypt successfully.
      expect(e1.argon2Salt, equals(e2.argon2Salt));
      final d1 = await codec.decrypt(passphrase: passphrase, envelope: e1);
      final d2 = await codec.decrypt(passphrase: passphrase, envelope: e2);
      expect(d1['userProfile'], equals(d2['userProfile']));
    });

    test('no plaintext personal data appears in the envelope JSON', () async {
      final sensitivePayload = {
        'userProfile': [
          {'id': 1, 'fitnessGoal': 'secret_goal_value'},
        ],
      };

      final envelope = await codec.encrypt(
        passphrase: passphrase,
        payload: sensitivePayload,
      );

      final json = envelope.toJson().toString();
      expect(json.contains('secret_goal_value'), isFalse);
    });
  });
}
