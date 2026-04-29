import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/bandit_state_dao.dart';
import 'package:pulse_coach/core/database/daos/behavioral_state_dao.dart';
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/core/database/daos/weather_cache_dao.dart';

@module
abstract class HealthModule {
  @singleton
  Health get health => Health();

  @singleton
  BehavioralStateDao behavioralStateDao(AppDatabase db) => db.behavioralStateDao;

  @singleton
  WeatherCacheDao weatherCacheDao(AppDatabase db) => db.weatherCacheDao;

  @singleton
  BanditStateDao banditStateDao(AppDatabase db) => db.banditStateDao;

  @singleton
  DailyPlansDao dailyPlansDao(AppDatabase db) => db.dailyPlansDao;

  @singleton
  RpeFeedbackDao rpeFeedbackDao(AppDatabase db) => db.rpeFeedbackDao;
}
