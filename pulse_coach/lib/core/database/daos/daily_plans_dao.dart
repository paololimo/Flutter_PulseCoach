import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/tables/daily_plans_table.dart';

part 'daily_plans_dao.g.dart';

@DriftAccessor(tables: [DailyPlans])
class DailyPlansDao extends DatabaseAccessor<AppDatabase>
    with _$DailyPlansDaoMixin {
  DailyPlansDao(super.db);

  Future<DailyPlan?> getPlanForDate(String date) => (select(
    dailyPlans,
  )..where((t) => t.planDate.equals(date))).getSingleOrNull();

  /// Returns the raw DB row for [id], or null when not found.
  Future<DailyPlan?> getPlanById(int id) =>
      (select(dailyPlans)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<DailyPlan>> getPlansInDateRange(
    String startDate,
    String endDate,
  ) => (select(
    dailyPlans,
  )..where((t) => t.planDate.isBetweenValues(startDate, endDate))).get();

  Future<int> insertPlan(DailyPlansCompanion entry) =>
      into(dailyPlans).insert(entry);

  Future<int> deletePlan(int id) =>
      (delete(dailyPlans)..where((t) => t.id.equals(id))).go();

  /// Sets `is_completed = true` for the plan matching [date] (`'YYYY-MM-DD'`).
  ///
  /// Returns `true` when a row was updated (either flipped from `false` to
  /// `true`, or already `true` — SQLite reports `rowsAffected = 1` in both
  /// cases, so calls are idempotent from the database's perspective).
  /// Returns `false` only when no plan exists for [date]; callers can treat
  /// `false` as "no plan to mark", not as a failure.
  Future<bool> markCompleted(String date) async {
    final rowsAffected =
        await (update(dailyPlans)..where((t) => t.planDate.equals(date))).write(
          const DailyPlansCompanion(isCompleted: Value(true)),
        );
    return rowsAffected > 0;
  }
}
