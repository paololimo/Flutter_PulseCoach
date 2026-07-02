import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/daos/bandit_state_dao.dart';
import 'package:pulse_coach/core/database/daos/behavioral_state_dao.dart';
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/exercise_cache_dao.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/core/database/daos/sessions_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/database/daos/sync_queue_dao.dart';
import 'package:pulse_coach/core/database/daos/user_profile_dao.dart';
import 'package:pulse_coach/core/database/daos/weather_cache_dao.dart';
import 'package:pulse_coach/core/database/tables/bandit_state_table.dart';
import 'package:pulse_coach/core/database/tables/behavioral_state_table.dart';
import 'package:pulse_coach/core/database/tables/daily_plans_table.dart';
import 'package:pulse_coach/core/database/tables/exercise_cache_table.dart';
import 'package:pulse_coach/core/database/tables/rpe_feedback_table.dart';
import 'package:pulse_coach/core/database/tables/sessions_table.dart';
import 'package:pulse_coach/core/database/tables/session_logs_table.dart';
import 'package:pulse_coach/core/database/tables/sync_queue_table.dart';
import 'package:pulse_coach/core/database/tables/user_profile_table.dart';
import 'package:pulse_coach/core/database/tables/weather_cache_table.dart';

part 'app_database.g.dart';

@singleton
@DriftDatabase(
  tables: [
    Sessions,
    DailyPlans,
    UserProfile,
    RpeFeedback,
    BanditState,
    BehavioralState,
    WeatherCache,
    ExerciseCache,
    SyncQueue,
    SessionLogs,
  ],
  daos: [
    SessionsDao,
    DailyPlansDao,
    UserProfileDao,
    RpeFeedbackDao,
    BanditStateDao,
    BehavioralStateDao,
    WeatherCacheDao,
    ExerciseCacheDao,
    SyncQueueDao,
    SessionLogsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'pulse_coach_db'));

  /// Named constructor for unit tests — uses in-memory SQLite
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(userProfile, userProfile.disclaimerAccepted);
      }
      if (from < 3) {
        await m.addColumn(userProfile, userProfile.availableTime);
        await m.addColumn(userProfile, userProfile.physicalConstraints);
      }
      if (from < 4) {
        await m.addColumn(dailyPlans, dailyPlans.isCompleted);
      }
      if (from < 5) {
        await m.createTable(sessionLogs);
      }
      if (from < 6) {
        // session_logs gained a FK to daily_plans (ON DELETE CASCADE) and a
        // UNIQUE(dailyPlanId, sessionIndex) constraint. SQLite cannot ALTER an
        // existing table to add a FK or UNIQUE, so drop and recreate — the
        // table was introduced in v5 and only carries ephemeral alpha data.
        await m.deleteTable('session_logs');
        await m.createTable(sessionLogs);
      }
      if (from >= 6 && from < 7) {
        await m.addColumn(sessionLogs, sessionLogs.abandoned);
        await m.addColumn(sessionLogs, sessionLogs.elapsedSeconds);
        await m.addColumn(sessionLogs, sessionLogs.currentStepIndex);
      }
      if (from < 8) {
        final rpeFeedbackExists = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'rpe_feedback'",
        ).get();
        if (rpeFeedbackExists.isEmpty) {
          await m.createTable(rpeFeedback);
        } else {
          // Survive a partial v8 (process killed mid-onUpgrade after addColumn
          // but before user_version was bumped) by skipping the column add
          // when it is already there. Without this PRAGMA check the second
          // run throws "duplicate column name" and bricks the DB open.
          final columns = await customSelect(
            'PRAGMA table_info(rpe_feedback)',
          ).get();
          final hasSessionLogId = columns.any(
            (row) => row.data['name'] == 'session_log_id',
          );
          if (!hasSessionLogId) {
            await m.addColumn(rpeFeedback, rpeFeedback.sessionLogId);
          }
        }
      }
      if (from < 9) {
        // Guard against minimal test databases that omit user_profile.
        final userProfileExists = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'user_profile'",
        ).get();
        if (userProfileExists.isNotEmpty) {
          // Survive a partial v9 (process killed mid-onUpgrade after addColumn
          // but before user_version was bumped) by skipping the column add when
          // it is already present — same guard as the v8 block above. Without
          // it the second run throws "duplicate column name" and bricks open.
          final columns = await customSelect(
            'PRAGMA table_info(user_profile)',
          ).get();
          final hasInstallCohort = columns.any(
            (row) => row.data['name'] == 'install_cohort',
          );
          if (!hasInstallCohort) {
            await m.addColumn(userProfile, userProfile.installCohort);
            await customStatement(
              "UPDATE user_profile SET install_cohort = 'pre_v2'",
            );
          }
        }
      }
      if (from < 10) {
        // SQLite cannot ALTER a column's NOT NULL/FK constraint or add it to an
        // existing UNIQUE index in place — the table must be rebuilt. Unlike the
        // v5→v6 migration (which safely dropped session_logs because it only
        // held ephemeral alpha data), this table now holds real user history, so
        // existing rows MUST be preserved via rename + recreate + copy + drop.
        //
        // Guarded for partial-upgrade survival (same pattern as the v8/v9 blocks
        // above): if the process is killed mid-migration, a naive unconditional
        // rename would throw "table session_logs_v9 already exists" on retry.
        // Also guarded against minimal test databases that omit session_logs
        // entirely (same reasoning as the user_profile guard in the v9 block).
        final sessionLogsExists = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'session_logs'",
        ).get();
        final backupExists = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'session_logs_v9'",
        ).get();
        await customStatement('PRAGMA foreign_keys = OFF');
        if (sessionLogsExists.isNotEmpty && backupExists.isEmpty) {
          await customStatement(
            'ALTER TABLE session_logs RENAME TO session_logs_v9',
          );
        }
        final newTableExists = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'session_logs'",
        ).get();
        if (newTableExists.isEmpty) {
          await m.createTable(sessionLogs);
        }
        // Idempotent copy + guarded drop (review P2): onUpgrade is NOT wrapped
        // in a transaction, so a process kill between createTable and this copy
        // would — under the previous code, which skipped the copy whenever
        // session_logs already existed and then dropped the backup
        // unconditionally — leave an empty session_logs while deleting the
        // backup, losing all history. Re-check the backup here (not the earlier
        // snapshot) and copy with INSERT OR IGNORE so a resumed migration
        // re-runs harmlessly (rows whose PK id is already present are skipped);
        // only then drop the backup.
        final backupStillExists = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'session_logs_v9'",
        ).get();
        if (backupStillExists.isNotEmpty) {
          await customStatement('''
            INSERT OR IGNORE INTO session_logs (
              id, daily_plan_id, session_index, completed_at, created_at,
              abandoned, elapsed_seconds, current_step_index
            )
            SELECT
              id, daily_plan_id, session_index, completed_at, created_at,
              abandoned, elapsed_seconds, current_step_index
            FROM session_logs_v9
          ''');
        }
        await customStatement('DROP TABLE IF EXISTS session_logs_v9');
        await customStatement('PRAGMA foreign_keys = ON');
      }
    },
    beforeOpen: (details) async {
      // Required so the new session_logs FK (ON DELETE CASCADE) and the
      // UNIQUE constraint are actually enforced — SQLite leaves FKs off by
      // default per connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
