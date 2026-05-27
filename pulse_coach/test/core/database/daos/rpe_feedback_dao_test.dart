import 'package:drift/drift.dart' show Value;
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

    test(
      '9.1-DAO-001: insertFeedbackIdempotent dedupes by sessionLogId',
      () async {
        final recordedAt = DateTime.utc(2026, 5, 15, 9);
        final firstId = await db.rpeFeedbackDao.insertFeedbackIdempotent(
          RpeFeedbackCompanion.insert(
            sessionId: 10,
            sessionLogId: const Value(42),
            rpeValue: 7,
            recordedAt: recordedAt,
          ),
        );

        final secondId = await db.rpeFeedbackDao.insertFeedbackIdempotent(
          RpeFeedbackCompanion.insert(
            sessionId: 11,
            sessionLogId: const Value(42),
            rpeValue: 9,
            recordedAt: recordedAt.add(const Duration(minutes: 5)),
          ),
        );

        final rows = await db.rpeFeedbackDao.getAllFeedback();
        expect(secondId, firstId);
        expect(rows, hasLength(1));
        expect(rows.single.sessionLogId, 42);
        expect(rows.single.rpeValue, 7);
      },
    );

    test(
      '9.1-DAO-002: insertFeedbackIdempotent dedupes legacy sessionId and recordedAt rows',
      () async {
        final recordedAt = DateTime.utc(2026, 5, 15, 9, 30);
        final firstId = await db.rpeFeedbackDao.insertFeedbackIdempotent(
          RpeFeedbackCompanion.insert(
            sessionId: 20,
            rpeValue: 5,
            recordedAt: recordedAt,
          ),
        );

        final secondId = await db.rpeFeedbackDao.insertFeedbackIdempotent(
          RpeFeedbackCompanion.insert(
            sessionId: 20,
            rpeValue: 8,
            recordedAt: recordedAt,
          ),
        );

        final rows = await db.rpeFeedbackDao.getAllFeedback();
        expect(secondId, firstId);
        expect(rows, hasLength(1));
        expect(rows.single.sessionId, 20);
        expect(rows.single.sessionLogId, isNull);
        expect(rows.single.rpeValue, 5);
      },
    );

    test(
      '9.1-DAO-003: getBySessionLogId returns matching row or null',
      () async {
        final recordedAt = DateTime.utc(2026, 5, 15, 10);
        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: 30,
            sessionLogId: const Value(77),
            rpeValue: 6,
            recordedAt: recordedAt,
          ),
        );
        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: 31,
            rpeValue: 8,
            recordedAt: recordedAt.add(const Duration(minutes: 10)),
          ),
        );

        final match = await db.rpeFeedbackDao.getBySessionLogId(77);
        final miss = await db.rpeFeedbackDao.getBySessionLogId(404);

        expect(match, isNotNull);
        expect(match!.sessionId, 30);
        expect(match.rpeValue, 6);
        expect(miss, isNull);
      },
    );
  });
}
