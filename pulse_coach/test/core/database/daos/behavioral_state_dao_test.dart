import 'package:drift/drift.dart' hide isNotNull;
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

  group('BehavioralStateDao', () {
    test(
      '[P1] 5.2-UNIT-014: getLatestState returns behavioral state with newest updatedAt',
      () async {
        final baseTime = DateTime.utc(2026, 5, 15, 8);

        await db.behavioralStateDao.insertState(
          BehavioralStateCompanion.insert(
            currentState: 'Recovering',
            restingHr: const Value(66),
            stepCount: const Value(4200),
            streakCount: const Value(2),
            recordedAt: baseTime,
            updatedAt: baseTime,
          ),
        );
        await db.behavioralStateDao.insertState(
          BehavioralStateCompanion.insert(
            currentState: 'Active',
            restingHr: const Value(58),
            stepCount: const Value(9800),
            streakCount: const Value(5),
            recordedAt: baseTime.add(const Duration(minutes: 5)),
            updatedAt: baseTime.add(const Duration(minutes: 10)),
          ),
        );

        final latest = await db.behavioralStateDao.getLatestState();

        expect(latest, isNotNull);
        expect(latest!.currentState, 'Active');
        expect(latest.restingHr, 58);
        expect(latest.stepCount, 9800);
        expect(latest.streakCount, 5);
      },
    );
  });
}
