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

  group('RpeFeedbackDao', () {
    test(
      '[P1] 3.3-UNIT-009: getLastN returns newest feedback first and applies limit',
      () async {
        final baseTime = DateTime.utc(2026, 5, 15, 8);

        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: 1,
            rpeValue: 4,
            recordedAt: baseTime,
          ),
        );
        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: 2,
            rpeValue: 7,
            recordedAt: baseTime.add(const Duration(minutes: 10)),
          ),
        );
        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: 3,
            rpeValue: 9,
            recordedAt: baseTime.add(const Duration(minutes: 20)),
          ),
        );

        final lastTwo = await db.rpeFeedbackDao.getLastN(2);

        expect(lastTwo, hasLength(2));
        expect(lastTwo.map((entry) => entry.sessionId), [3, 2]);
        expect(lastTwo.map((entry) => entry.rpeValue), [9, 7]);
      },
    );
  });
}
