import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/behavioral_state_dao.dart';

@module
abstract class HealthModule {
  @singleton
  Health get health => Health();

  @singleton
  BehavioralStateDao behavioralStateDao(AppDatabase db) => db.behavioralStateDao;
}
