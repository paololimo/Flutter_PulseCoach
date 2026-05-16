import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/tables/session_logs_table.dart';

part 'session_logs_dao.g.dart';

@DriftAccessor(tables: [SessionLogs])
class SessionLogsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionLogsDaoMixin {
  SessionLogsDao(super.db);

  /// Uses [InsertMode.insertOrIgnore] so the UNIQUE(dailyPlanId, sessionIndex)
  /// constraint silently swallows duplicate-completion attempts (e.g. a
  /// double-tap on the hero card or a retried insert after a transient error).
  /// Returns the inserted row id, or `0` when the insert was ignored.
  Future<int> insertLog(SessionLogsCompanion entry) =>
      into(sessionLogs).insert(entry, mode: InsertMode.insertOrIgnore);

  Future<List<SessionLog>> getLogsForPlan(int planId) =>
      (select(sessionLogs)..where((t) => t.dailyPlanId.equals(planId))).get();

  Future<int> deleteLogsForPlan(int planId) =>
      (delete(sessionLogs)..where((t) => t.dailyPlanId.equals(planId))).go();
}
