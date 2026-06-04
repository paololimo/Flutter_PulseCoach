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

  Future<void> insertPlan(String date) async {
    final now = DateTime.utc(2026, 5, 20, 9);
    await db.dailyPlansDao.insertPlan(
      DailyPlansCompanion.insert(
        planDate: date,
        planJson: '{"sessions":[]}',
        generatedAt: now,
        createdAt: now,
      ),
    );
  }

  group('DailyPlansDao', () {
    test(
      '7.1b-DAO-001: getPlansInDateRange includes bounds and excludes outside window',
      () async {
        await insertPlan('2026-05-12');
        await insertPlan('2026-05-13');
        await insertPlan('2026-05-16');
        await insertPlan('2026-05-19');
        await insertPlan('2026-05-20');

        final plans = await db.dailyPlansDao.getPlansInDateRange(
          '2026-05-13',
          '2026-05-19',
        );

        final dates = plans.map((plan) => plan.planDate).toList();
        expect(dates, hasLength(3));
        expect(dates, containsAll(['2026-05-13', '2026-05-16', '2026-05-19']));
        expect(dates, isNot(contains('2026-05-12')));
        expect(dates, isNot(contains('2026-05-20')));
      },
    );
  });
}
