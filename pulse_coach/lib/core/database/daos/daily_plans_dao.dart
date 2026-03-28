import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/tables/daily_plans_table.dart';

part 'daily_plans_dao.g.dart';

@DriftAccessor(tables: [DailyPlans])
class DailyPlansDao extends DatabaseAccessor<AppDatabase>
    with _$DailyPlansDaoMixin {
  DailyPlansDao(super.db);

  Future<DailyPlan?> getPlanForDate(String date) =>
      (select(dailyPlans)..where((t) => t.planDate.equals(date)))
          .getSingleOrNull();

  Future<int> insertPlan(DailyPlansCompanion entry) =>
      into(dailyPlans).insert(entry);

  Future<int> deletePlan(int id) =>
      (delete(dailyPlans)..where((t) => t.id.equals(id))).go();
}
