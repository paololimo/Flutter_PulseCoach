import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/daos/bandit_state_dao.dart';
import 'package:pulse_coach/core/database/daos/behavioral_state_dao.dart';
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/exercise_cache_dao.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/core/database/daos/sessions_dao.dart';
import 'package:pulse_coach/core/database/daos/sync_queue_dao.dart';
import 'package:pulse_coach/core/database/daos/user_profile_dao.dart';
import 'package:pulse_coach/core/database/daos/weather_cache_dao.dart';
import 'package:pulse_coach/core/database/tables/bandit_state_table.dart';
import 'package:pulse_coach/core/database/tables/behavioral_state_table.dart';
import 'package:pulse_coach/core/database/tables/daily_plans_table.dart';
import 'package:pulse_coach/core/database/tables/exercise_cache_table.dart';
import 'package:pulse_coach/core/database/tables/rpe_feedback_table.dart';
import 'package:pulse_coach/core/database/tables/sessions_table.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'pulse_coach_db'));

  /// Named constructor for unit tests — uses in-memory SQLite
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

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
    },
  );
}
