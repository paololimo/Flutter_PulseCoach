import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('BanditStateDao', () {
    test(
      '[P1] 5.4-UNIT-020: getLatestState selects newest state and updateState persists replacement',
      () async {
        final baseTime = DateTime.utc(2026, 5, 15, 8);

        await db.banditStateDao.insertState(
          BanditStateCompanion.insert(
            armWeightsJson: '{"mobility_low":1.0}',
            updatedAt: baseTime,
          ),
        );
        await db.banditStateDao.insertState(
          BanditStateCompanion.insert(
            armWeightsJson: '{"cardio_medium":2.0}',
            updatedAt: baseTime.add(const Duration(minutes: 10)),
          ),
        );

        final latest = await db.banditStateDao.getLatestState();

        expect(latest, isNotNull);
        expect(latest!.armWeightsJson, '{"cardio_medium":2.0}');

        final replacementTime = baseTime.add(const Duration(minutes: 20));
        final updated = await db.banditStateDao.updateState(
          latest.copyWith(
            armWeightsJson: '{"cardio_medium":3.0}',
            updatedAt: replacementTime,
          ),
        );
        final afterUpdate = await db.banditStateDao.getLatestState();

        expect(updated, isTrue);
        expect(afterUpdate, isNotNull);
        expect(afterUpdate!.id, latest.id);
        expect(afterUpdate.armWeightsJson, '{"cardio_medium":3.0}');
        expect(afterUpdate.updatedAt.toUtc(), replacementTime);
      },
    );
  });
}
