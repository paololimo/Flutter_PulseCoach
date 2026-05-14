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

  test(
    '6.1-UNIT-001: insertOrReplaceBatch + getAll returns all cached rows',
    () async {
      final cachedAt = DateTime.utc(2026, 5, 14, 10);
      await db.exerciseCacheDao.insertOrReplaceBatch([
        ExerciseCacheCompanion.insert(
          exerciseId: 'mobility-1',
          exerciseJson: '{"id":"mobility-1","sessionType":"mobility"}',
          cachedAt: cachedAt,
        ),
        ExerciseCacheCompanion.insert(
          exerciseId: 'cardio-1',
          exerciseJson: '{"id":"cardio-1","sessionType":"cardio"}',
          cachedAt: cachedAt,
        ),
      ]);

      final rows = await db.exerciseCacheDao.getAll();

      expect(rows, hasLength(2));
      expect(
        rows.map((row) => row.exerciseId),
        containsAll(['mobility-1', 'cardio-1']),
      );
      expect(
        rows.every((row) => row.cachedAt.toUtc().isAtSameMomentAs(cachedAt)),
        isTrue,
      );
    },
  );
}
