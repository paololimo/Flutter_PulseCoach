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

  /// Completion-path insert: uses [InsertMode.insertOrReplace] so a previous
  /// abandoned row for the same `(dailyPlanId, sessionIndex)` is overwritten
  /// when the user restarts and finishes the session. Without this, the
  /// UNIQUE constraint + `insertOrIgnore` would silently drop the completion
  /// and leave the abandoned row as the source of truth (review BLOCKER #1).
  Future<int> upsertCompletion(SessionLogsCompanion entry) =>
      into(sessionLogs).insert(entry, mode: InsertMode.insertOrReplace);

  Future<List<SessionLog>> getLogsForPlan(int planId) =>
      (select(sessionLogs)..where((t) => t.dailyPlanId.equals(planId))).get();

  /// Drift-native live query. Emits the current rows immediately and re-emits
  /// after every insert/update/delete touching `sessionLogs`. TodaySessionCubit
  /// subscribes to this so InSessionCubit's persistence flow surfaces in the
  /// Today UI without an explicit signal.
  Stream<List<SessionLog>> watchLogsForPlan(int planId) =>
      (select(sessionLogs)..where((t) => t.dailyPlanId.equals(planId))).watch();

  Future<int> deleteLogsForPlan(int planId) =>
      (delete(sessionLogs)..where((t) => t.dailyPlanId.equals(planId))).go();
}
