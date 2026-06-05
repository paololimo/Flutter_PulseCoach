// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:health/health.dart' as _i237;
import 'package:injectable/injectable.dart' as _i526;
import 'package:pulse_coach/ai/engine/ai_engine.dart' as _i122;
import 'package:pulse_coach/ai/engine/ai_engine_isolate.dart' as _i157;
import 'package:pulse_coach/core/database/app_database.dart' as _i79;
import 'package:pulse_coach/core/database/daos/bandit_state_dao.dart' as _i10;
import 'package:pulse_coach/core/database/daos/behavioral_state_dao.dart'
    as _i227;
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart' as _i562;
import 'package:pulse_coach/core/database/daos/exercise_cache_dao.dart'
    as _i224;
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart' as _i224;
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart' as _i30;
import 'package:pulse_coach/core/database/daos/sync_queue_dao.dart' as _i694;
import 'package:pulse_coach/core/database/daos/weather_cache_dao.dart' as _i194;
import 'package:pulse_coach/core/di/health_module.dart' as _i294;
import 'package:pulse_coach/core/di/network_module.dart' as _i731;
import 'package:pulse_coach/core/di/settings_module.dart' as _i389;
import 'package:pulse_coach/core/sync/sync_manager.dart' as _i780;
import 'package:pulse_coach/core/utils/geolocator_wrapper.dart' as _i973;
import 'package:pulse_coach/core/utils/location_service.dart' as _i160;
import 'package:pulse_coach/features/daily_plan/data/repositories/daily_plan_repository_impl.dart'
    as _i432;
import 'package:pulse_coach/features/daily_plan/domain/repositories/daily_plan_repository.dart'
    as _i78;
import 'package:pulse_coach/features/daily_plan/domain/usecases/generate_daily_plan.dart'
    as _i992;
import 'package:pulse_coach/features/daily_plan/domain/usecases/regenerate_daily_plan.dart'
    as _i183;
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart'
    as _i372;
import 'package:pulse_coach/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i462;
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i338;
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart'
    as _i944;
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart'
    as _i145;
import 'package:pulse_coach/features/onboarding/domain/usecases/get_profile.dart'
    as _i529;
import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart'
    as _i280;
import 'package:pulse_coach/features/onboarding/domain/usecases/update_profile.dart'
    as _i926;
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart'
    as _i472;
import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_cubit.dart'
    as _i901;
import 'package:pulse_coach/features/progress/data/datasources/progress_local_data_source.dart'
    as _i272;
import 'package:pulse_coach/features/progress/data/repositories/progress_repository_impl.dart'
    as _i1027;
import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart'
    as _i73;
import 'package:pulse_coach/features/progress/domain/usecases/get_progress_stats.dart'
    as _i303;
import 'package:pulse_coach/features/progress/domain/usecases/get_session_history.dart'
    as _i727;
import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart'
    as _i111;
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_cubit.dart'
    as _i56;
import 'package:pulse_coach/features/session/data/datasources/accelerometer_data_source.dart'
    as _i253;
import 'package:pulse_coach/features/session/data/datasources/health_data_source.dart'
    as _i311;
import 'package:pulse_coach/features/session/data/repositories/health_repository_impl.dart'
    as _i1067;
import 'package:pulse_coach/features/session/data/repositories/sensor_repository_impl.dart'
    as _i700;
import 'package:pulse_coach/features/session/domain/repositories/health_repository.dart'
    as _i1070;
import 'package:pulse_coach/features/session/domain/repositories/sensor_repository.dart'
    as _i628;
import 'package:pulse_coach/features/session/domain/usecases/get_activity_level.dart'
    as _i1;
import 'package:pulse_coach/features/session/domain/usecases/get_health_data.dart'
    as _i746;
import 'package:pulse_coach/features/session/domain/usecases/get_sensor_context.dart'
    as _i984;
import 'package:pulse_coach/features/session/domain/usecases/update_bandit_reward.dart'
    as _i359;
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_local_data_source.dart'
    as _i91;
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_remote_data_source.dart'
    as _i635;
import 'package:pulse_coach/features/sessions_catalog/data/repositories/exercise_repository_impl.dart'
    as _i396;
import 'package:pulse_coach/features/sessions_catalog/domain/repositories/exercise_repository.dart'
    as _i207;
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart'
    as _i342;
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/sync_exercise_catalog.dart'
    as _i574;
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart'
    as _i916;
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart'
    as _i291;
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart'
    as _i491;
import 'package:pulse_coach/features/weather/data/datasources/weather_local_data_source.dart'
    as _i206;
import 'package:pulse_coach/features/weather/data/datasources/weather_remote_data_source.dart'
    as _i209;
import 'package:pulse_coach/features/weather/data/repositories/weather_repository_impl.dart'
    as _i61;
import 'package:pulse_coach/features/weather/domain/repositories/weather_repository.dart'
    as _i748;
import 'package:pulse_coach/features/weather/domain/usecases/get_weather_context.dart'
    as _i664;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final healthModule = _$HealthModule();
    final networkModule = _$NetworkModule();
    final settingsModule = _$SettingsModule();
    gh.factory<_i253.AccelerometerDataSource>(
      () => _i253.AccelerometerDataSource(),
    );
    gh.singleton<_i79.AppDatabase>(() => _i79.AppDatabase());
    gh.singleton<_i237.Health>(() => healthModule.health);
    gh.singleton<_i895.Connectivity>(() => networkModule.connectivity);
    gh.singleton<_i361.Dio>(() => networkModule.dio);
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => settingsModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i338.OnboardingRepository>(
      () => _i462.OnboardingRepositoryImpl(gh<_i79.AppDatabase>()),
    );
    gh.factory<_i311.HealthDataSource>(
      () => _i311.HealthDataSource(gh<_i237.Health>()),
    );
    gh.factory<_i973.GeolocatorWrapper>(() => _i973.GeolocatorWrapperImpl());
    gh.factory<_i628.SensorRepository>(
      () => _i700.SensorRepositoryImpl(gh<_i253.AccelerometerDataSource>()),
    );
    gh.factory<_i78.DailyPlanRepository>(
      () => _i432.DailyPlanRepositoryImpl(gh<_i79.AppDatabase>()),
    );
    gh.factory<_i122.AiEngine>(() => _i157.AiEngineIsolate());
    gh.factory<_i359.UpdateBanditReward>(
      () => _i359.UpdateBanditReward(gh<_i79.AppDatabase>()),
    );
    gh.singleton<_i227.BehavioralStateDao>(
      () => healthModule.behavioralStateDao(gh<_i79.AppDatabase>()),
    );
    gh.singleton<_i194.WeatherCacheDao>(
      () => healthModule.weatherCacheDao(gh<_i79.AppDatabase>()),
    );
    gh.singleton<_i10.BanditStateDao>(
      () => healthModule.banditStateDao(gh<_i79.AppDatabase>()),
    );
    gh.singleton<_i562.DailyPlansDao>(
      () => healthModule.dailyPlansDao(gh<_i79.AppDatabase>()),
    );
    gh.singleton<_i224.ExerciseCacheDao>(
      () => healthModule.exerciseCacheDao(gh<_i79.AppDatabase>()),
    );
    gh.singleton<_i224.RpeFeedbackDao>(
      () => healthModule.rpeFeedbackDao(gh<_i79.AppDatabase>()),
    );
    gh.singleton<_i30.SessionLogsDao>(
      () => healthModule.sessionLogsDao(gh<_i79.AppDatabase>()),
    );
    gh.singleton<_i694.SyncQueueDao>(
      () => healthModule.syncQueueDao(gh<_i79.AppDatabase>()),
    );
    gh.factory<_i635.ExerciseRemoteDataSource>(
      () => _i635.ExerciseRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.factory<_i209.WeatherRemoteDataSource>(
      () => _i209.WeatherRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.factory<_i1.GetActivityLevel>(
      () => _i1.GetActivityLevel(gh<_i628.SensorRepository>()),
    );
    gh.lazySingleton<_i291.ThemeCubit>(
      () => _i291.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i780.SyncManager>(
      () =>
          _i780.SyncManager(gh<_i694.SyncQueueDao>(), gh<_i895.Connectivity>()),
    );
    gh.factory<_i1070.HealthRepository>(
      () => _i1067.HealthRepositoryImpl(
        gh<_i311.HealthDataSource>(),
        gh<_i227.BehavioralStateDao>(),
      ),
    );
    gh.factory<_i491.TodaySessionCubit>(
      () => _i491.TodaySessionCubit(gh<_i30.SessionLogsDao>()),
    );
    gh.factory<_i160.LocationService>(
      () => _i160.LocationService(gh<_i973.GeolocatorWrapper>()),
    );
    gh.factory<_i944.AcceptDisclaimer>(
      () => _i944.AcceptDisclaimer(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i145.CheckDisclaimerStatus>(
      () => _i145.CheckDisclaimerStatus(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i529.GetProfile>(
      () => _i529.GetProfile(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i280.SaveProfile>(
      () => _i280.SaveProfile(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i926.UpdateProfile>(
      () => _i926.UpdateProfile(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i746.GetHealthData>(
      () => _i746.GetHealthData(gh<_i1070.HealthRepository>()),
    );
    gh.factory<_i91.ExerciseLocalDataSource>(
      () => _i91.ExerciseLocalDataSource(gh<_i224.ExerciseCacheDao>()),
    );
    gh.factory<_i901.ProfileCubit>(
      () =>
          _i901.ProfileCubit(gh<_i529.GetProfile>(), gh<_i926.UpdateProfile>()),
    );
    gh.factory<_i207.ExerciseRepository>(
      () => _i396.ExerciseRepositoryImpl(
        gh<_i635.ExerciseRemoteDataSource>(),
        gh<_i91.ExerciseLocalDataSource>(),
      ),
    );
    gh.factory<_i472.OnboardingCubit>(
      () => _i472.OnboardingCubit(
        gh<_i944.AcceptDisclaimer>(),
        gh<_i145.CheckDisclaimerStatus>(),
        gh<_i280.SaveProfile>(),
      ),
    );
    gh.lazySingleton<_i272.ProgressLocalDataSource>(
      () => _i272.ProgressLocalDataSource(
        gh<_i30.SessionLogsDao>(),
        gh<_i562.DailyPlansDao>(),
        gh<_i224.RpeFeedbackDao>(),
      ),
    );
    gh.factory<_i206.WeatherLocalDataSource>(
      () => _i206.WeatherLocalDataSource(gh<_i194.WeatherCacheDao>()),
    );
    gh.factory<_i342.GetExercisesByType>(
      () => _i342.GetExercisesByType(gh<_i207.ExerciseRepository>()),
    );
    gh.factory<_i574.SyncExerciseCatalog>(
      () => _i574.SyncExerciseCatalog(gh<_i207.ExerciseRepository>()),
    );
    gh.factory<_i984.GetSensorContext>(
      () => _i984.GetSensorContext(
        gh<_i746.GetHealthData>(),
        gh<_i1.GetActivityLevel>(),
      ),
    );
    gh.factory<_i748.WeatherRepository>(
      () => _i61.WeatherRepositoryImpl(
        gh<_i209.WeatherRemoteDataSource>(),
        gh<_i206.WeatherLocalDataSource>(),
        gh<_i160.LocationService>(),
      ),
    );
    gh.lazySingleton<_i73.ProgressRepository>(
      () => _i1027.ProgressRepositoryImpl(gh<_i272.ProgressLocalDataSource>()),
    );
    gh.lazySingleton<_i303.GetProgressStats>(
      () => _i303.GetProgressStats(gh<_i73.ProgressRepository>()),
    );
    gh.lazySingleton<_i727.GetSessionHistory>(
      () => _i727.GetSessionHistory(gh<_i73.ProgressRepository>()),
    );
    gh.lazySingleton<_i916.SessionsCatalogCubit>(
      () => _i916.SessionsCatalogCubit(gh<_i342.GetExercisesByType>()),
    );
    gh.factory<_i992.GenerateDailyPlan>(
      () => _i992.GenerateDailyPlan(
        gh<_i78.DailyPlanRepository>(),
        gh<_i122.AiEngine>(),
        gh<_i1070.HealthRepository>(),
        gh<_i628.SensorRepository>(),
        gh<_i748.WeatherRepository>(),
        gh<_i338.OnboardingRepository>(),
        gh<_i207.ExerciseRepository>(),
        gh<_i79.AppDatabase>(),
      ),
    );
    gh.factory<_i111.ProgressCubit>(
      () => _i111.ProgressCubit(gh<_i727.GetSessionHistory>()),
    );
    gh.factory<_i664.GetWeatherContext>(
      () => _i664.GetWeatherContext(gh<_i748.WeatherRepository>()),
    );
    gh.factory<_i183.RegenerateDailyPlan>(
      () => _i183.RegenerateDailyPlan(
        gh<_i78.DailyPlanRepository>(),
        gh<_i992.GenerateDailyPlan>(),
      ),
    );
    gh.factory<_i372.DailyPlanBloc>(
      () => _i372.DailyPlanBloc(
        gh<_i992.GenerateDailyPlan>(),
        gh<_i183.RegenerateDailyPlan>(),
        gh<_i79.AppDatabase>(),
      ),
    );
    gh.factory<_i56.ProgressStatsCubit>(
      () => _i56.ProgressStatsCubit(gh<_i303.GetProgressStats>()),
    );
    return this;
  }
}

class _$HealthModule extends _i294.HealthModule {}

class _$NetworkModule extends _i731.NetworkModule {}

class _$SettingsModule extends _i389.SettingsModule {}
