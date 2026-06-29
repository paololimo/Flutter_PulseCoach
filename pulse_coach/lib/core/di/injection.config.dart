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
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:health/health.dart' as _i237;
import 'package:injectable/injectable.dart' as _i526;
import 'package:pulse_coach/ai/engine/ai_engine.dart' as _i122;
import 'package:pulse_coach/ai/engine/ai_engine_isolate.dart' as _i157;
import 'package:pulse_coach/core/cloud/crypto/e2e_backup_codec.dart' as _i684;
import 'package:pulse_coach/core/cloud/entitlement_gate.dart' as _i499;
import 'package:pulse_coach/core/cloud/realtime_gateway.dart' as _i281;
import 'package:pulse_coach/core/cloud/supabase_client.dart' as _i42;
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
import 'package:pulse_coach/core/di/secure_storage_module.dart' as _i621;
import 'package:pulse_coach/core/di/settings_module.dart' as _i389;
import 'package:pulse_coach/core/sync/sync_manager.dart' as _i780;
import 'package:pulse_coach/core/utils/geolocator_wrapper.dart' as _i973;
import 'package:pulse_coach/core/utils/location_service.dart' as _i160;
import 'package:pulse_coach/features/auth/data/datasources/auth_remote_data_source.dart'
    as _i284;
import 'package:pulse_coach/features/auth/data/datasources/backup_local_data_source.dart'
    as _i761;
import 'package:pulse_coach/features/auth/data/datasources/backup_remote_data_source.dart'
    as _i757;
import 'package:pulse_coach/features/auth/data/repositories/auth_repository_impl.dart'
    as _i50;
import 'package:pulse_coach/features/auth/data/repositories/backup_repository_impl.dart'
    as _i44;
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart'
    as _i213;
import 'package:pulse_coach/features/auth/domain/repositories/backup_repository.dart'
    as _i271;
import 'package:pulse_coach/features/auth/domain/usecases/backup_now_use_case.dart'
    as _i544;
import 'package:pulse_coach/features/auth/domain/usecases/delete_account_use_case.dart'
    as _i623;
import 'package:pulse_coach/features/auth/domain/usecases/disable_backup_use_case.dart'
    as _i609;
import 'package:pulse_coach/features/auth/domain/usecases/enable_backup_use_case.dart'
    as _i285;
import 'package:pulse_coach/features/auth/domain/usecases/export_data_use_case.dart'
    as _i1032;
import 'package:pulse_coach/features/auth/domain/usecases/get_signed_in_user_use_case.dart'
    as _i330;
import 'package:pulse_coach/features/auth/domain/usecases/is_backup_enabled_use_case.dart'
    as _i134;
import 'package:pulse_coach/features/auth/domain/usecases/restore_backup_use_case.dart'
    as _i122;
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_apple_use_case.dart'
    as _i200;
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_email_use_case.dart'
    as _i114;
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_google_use_case.dart'
    as _i56;
import 'package:pulse_coach/features/auth/domain/usecases/sign_out_use_case.dart'
    as _i455;
import 'package:pulse_coach/features/auth/domain/usecases/sign_up_with_email_use_case.dart'
    as _i986;
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart'
    as _i412;
import 'package:pulse_coach/features/auth/presentation/bloc/backup_bloc.dart'
    as _i57;
import 'package:pulse_coach/features/auth/presentation/bloc/export_data_cubit.dart'
    as _i627;
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
import 'package:pulse_coach/features/progress/presentation/bloc/progress_gating_cubit.dart'
    as _i439;
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
import 'package:pulse_coach/features/settings/data/repositories/ai_decision_log_repository.dart'
    as _i646;
import 'package:pulse_coach/features/settings/data/services/data_export_service.dart'
    as _i748;
import 'package:pulse_coach/features/settings/presentation/bloc/ai_decision_log_cubit.dart'
    as _i364;
import 'package:pulse_coach/features/settings/presentation/bloc/data_export_cubit.dart'
    as _i705;
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_cubit.dart'
    as _i168;
import 'package:pulse_coach/features/settings/presentation/bloc/locale_cubit.dart'
    as _i288;
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart'
    as _i291;
import 'package:pulse_coach/features/social/comparison/data/datasources/progress_comparison_remote_data_source.dart'
    as _i1003;
import 'package:pulse_coach/features/social/comparison/data/repositories/progress_comparison_repository_impl.dart'
    as _i718;
import 'package:pulse_coach/features/social/comparison/domain/repositories/progress_comparison_repository.dart'
    as _i180;
import 'package:pulse_coach/features/social/comparison/domain/usecases/get_friends_comparison_use_case.dart'
    as _i1033;
import 'package:pulse_coach/features/social/comparison/domain/usecases/get_own_weekly_summary_use_case.dart'
    as _i1038;
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_bloc.dart'
    as _i418;
import 'package:pulse_coach/features/social/feed/data/datasources/feed_remote_data_source.dart'
    as _i539;
import 'package:pulse_coach/features/social/feed/data/repositories/feed_repository_impl.dart'
    as _i213;
import 'package:pulse_coach/features/social/feed/domain/repositories/feed_repository.dart'
    as _i351;
import 'package:pulse_coach/features/social/feed/domain/usecases/get_feed_use_case.dart'
    as _i618;
import 'package:pulse_coach/features/social/feed/domain/usecases/react_to_entry_use_case.dart'
    as _i332;
import 'package:pulse_coach/features/social/feed/domain/usecases/revoke_feed_entry_use_case.dart'
    as _i731;
import 'package:pulse_coach/features/social/feed/domain/usecases/share_feed_entry_use_case.dart'
    as _i615;
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_bloc.dart'
    as _i111;
import 'package:pulse_coach/features/social/friends/data/datasources/friends_remote_data_source.dart'
    as _i27;
import 'package:pulse_coach/features/social/friends/data/datasources/social_profile_remote_data_source.dart'
    as _i165;
import 'package:pulse_coach/features/social/friends/data/repositories/friends_repository_impl.dart'
    as _i500;
import 'package:pulse_coach/features/social/friends/data/repositories/social_profile_repository_impl.dart'
    as _i810;
import 'package:pulse_coach/features/social/friends/domain/repositories/friends_repository.dart'
    as _i401;
import 'package:pulse_coach/features/social/friends/domain/repositories/social_profile_repository.dart'
    as _i502;
import 'package:pulse_coach/features/social/friends/domain/usecases/accept_request_use_case.dart'
    as _i563;
import 'package:pulse_coach/features/social/friends/domain/usecases/decline_request_use_case.dart'
    as _i662;
import 'package:pulse_coach/features/social/friends/domain/usecases/get_friends_use_case.dart'
    as _i879;
import 'package:pulse_coach/features/social/friends/domain/usecases/get_pending_requests_use_case.dart'
    as _i282;
import 'package:pulse_coach/features/social/friends/domain/usecases/get_social_profile_use_case.dart'
    as _i1023;
import 'package:pulse_coach/features/social/friends/domain/usecases/remove_friend_use_case.dart'
    as _i816;
import 'package:pulse_coach/features/social/friends/domain/usecases/search_by_handle_use_case.dart'
    as _i482;
import 'package:pulse_coach/features/social/friends/domain/usecases/send_friend_request_use_case.dart'
    as _i623;
import 'package:pulse_coach/features/social/friends/domain/usecases/update_handle_use_case.dart'
    as _i846;
import 'package:pulse_coach/features/social/friends/domain/usecases/update_visibility_tier_use_case.dart'
    as _i586;
import 'package:pulse_coach/features/social/friends/presentation/bloc/friends_bloc.dart'
    as _i829;
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart'
    as _i477;
import 'package:pulse_coach/features/social/friends/presentation/bloc/visibility_cubit.dart'
    as _i613;
import 'package:pulse_coach/features/social/shared_session/data/datasources/shared_session_remote_data_source.dart'
    as _i473;
import 'package:pulse_coach/features/social/shared_session/data/repositories/shared_session_repository_impl.dart'
    as _i195;
import 'package:pulse_coach/features/social/shared_session/domain/repositories/shared_session_repository.dart'
    as _i123;
import 'package:pulse_coach/features/social/shared_session/domain/usecases/create_shared_session_use_case.dart'
    as _i532;
import 'package:pulse_coach/features/social/shared_session/domain/usecases/delete_shared_session_use_case.dart'
    as _i102;
import 'package:pulse_coach/features/social/shared_session/domain/usecases/join_shared_session_use_case.dart'
    as _i31;
import 'package:pulse_coach/features/social/shared_session/domain/usecases/refresh_join_code_use_case.dart'
    as _i1039;
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart'
    as _i596;
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_creation_cubit.dart'
    as _i606;
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_join_cubit.dart'
    as _i385;
import 'package:pulse_coach/features/subscription/data/repositories/entitlement_repository_impl.dart'
    as _i705;
import 'package:pulse_coach/features/subscription/data/services/upsell_cooldown_service.dart'
    as _i540;
import 'package:pulse_coach/features/subscription/domain/repositories/entitlement_repository.dart'
    as _i811;
import 'package:pulse_coach/features/subscription/domain/usecases/check_entitlement_use_case.dart'
    as _i303;
import 'package:pulse_coach/features/subscription/domain/usecases/get_install_cohort_use_case.dart'
    as _i589;
import 'package:pulse_coach/features/subscription/domain/usecases/get_offerings_use_case.dart'
    as _i326;
import 'package:pulse_coach/features/subscription/domain/usecases/purchase_pro_use_case.dart'
    as _i421;
import 'package:pulse_coach/features/subscription/domain/usecases/restore_purchases_use_case.dart'
    as _i487;
import 'package:pulse_coach/features/subscription/presentation/bloc/paywall_cubit.dart'
    as _i649;
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart'
    as _i844;
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
    final secureStorageModule = _$SecureStorageModule();
    final settingsModule = _$SettingsModule();
    gh.factory<_i684.E2eBackupCodec>(() => _i684.E2eBackupCodec());
    gh.factory<_i253.AccelerometerDataSource>(
      () => _i253.AccelerometerDataSource(),
    );
    gh.factory<_i613.VisibilityCubit>(() => _i613.VisibilityCubit());
    gh.singleton<_i42.SupabaseClientProvider>(
      () => _i42.SupabaseClientProvider(),
    );
    gh.singleton<_i79.AppDatabase>(() => _i79.AppDatabase());
    gh.singleton<_i237.Health>(() => healthModule.health);
    gh.singleton<_i895.Connectivity>(() => networkModule.connectivity);
    gh.singleton<_i361.Dio>(() => networkModule.dio);
    gh.singleton<_i558.FlutterSecureStorage>(
      () => secureStorageModule.flutterSecureStorage,
    );
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
    gh.factory<_i761.BackupLocalDataSource>(
      () => _i761.BackupLocalDataSource(
        gh<_i79.AppDatabase>(),
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.factory<_i646.AiDecisionLogRepository>(
      () => _i646.AiDecisionLogRepository(
        gh<_i224.RpeFeedbackDao>(),
        gh<_i30.SessionLogsDao>(),
        gh<_i562.DailyPlansDao>(),
      ),
    );
    gh.singleton<_i281.RealtimeGateway>(
      () => _i281.RealtimeGateway(gh<_i42.SupabaseClientProvider>()),
    );
    gh.factory<_i1.GetActivityLevel>(
      () => _i1.GetActivityLevel(gh<_i628.SensorRepository>()),
    );
    gh.singleton<_i540.UpsellCooldownService>(
      () => _i540.UpsellCooldownService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i288.LocaleCubit>(
      () => _i288.LocaleCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i291.ThemeCubit>(
      () => _i291.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i780.SyncManager>(
      () =>
          _i780.SyncManager(gh<_i694.SyncQueueDao>(), gh<_i895.Connectivity>()),
    );
    gh.singleton<_i499.EntitlementGate>(
      () => _i499.EntitlementGate(gh<_i42.SupabaseClientProvider>()),
    );
    gh.factory<_i284.AuthRemoteDataSource>(
      () => _i284.AuthRemoteDataSource(gh<_i42.SupabaseClientProvider>()),
    );
    gh.factory<_i757.BackupRemoteDataSource>(
      () => _i757.BackupRemoteDataSource(gh<_i42.SupabaseClientProvider>()),
    );
    gh.factory<_i1003.ProgressComparisonRemoteDataSource>(
      () => _i1003.ProgressComparisonRemoteDataSource(
        gh<_i42.SupabaseClientProvider>(),
      ),
    );
    gh.factory<_i539.FeedRemoteDataSource>(
      () => _i539.FeedRemoteDataSource(gh<_i42.SupabaseClientProvider>()),
    );
    gh.factory<_i27.FriendsRemoteDataSource>(
      () => _i27.FriendsRemoteDataSource(gh<_i42.SupabaseClientProvider>()),
    );
    gh.factory<_i165.SocialProfileRemoteDataSource>(
      () => _i165.SocialProfileRemoteDataSource(
        gh<_i42.SupabaseClientProvider>(),
      ),
    );
    gh.factory<_i473.SharedSessionRemoteDataSource>(
      () => _i473.SharedSessionRemoteDataSource(
        gh<_i42.SupabaseClientProvider>(),
      ),
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
    gh.factory<_i123.SharedSessionRepository>(
      () => _i195.SharedSessionRepositoryImpl(
        gh<_i473.SharedSessionRemoteDataSource>(),
      ),
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
    gh.factory<_i589.GetInstallCohortUseCase>(
      () => _i589.GetInstallCohortUseCase(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i746.GetHealthData>(
      () => _i746.GetHealthData(gh<_i1070.HealthRepository>()),
    );
    gh.factory<_i91.ExerciseLocalDataSource>(
      () => _i91.ExerciseLocalDataSource(gh<_i224.ExerciseCacheDao>()),
    );
    gh.factory<_i532.CreateSharedSessionUseCase>(
      () =>
          _i532.CreateSharedSessionUseCase(gh<_i123.SharedSessionRepository>()),
    );
    gh.factory<_i102.DeleteSharedSessionUseCase>(
      () =>
          _i102.DeleteSharedSessionUseCase(gh<_i123.SharedSessionRepository>()),
    );
    gh.factory<_i31.JoinSharedSessionUseCase>(
      () => _i31.JoinSharedSessionUseCase(gh<_i123.SharedSessionRepository>()),
    );
    gh.factory<_i1039.RefreshJoinCodeUseCase>(
      () => _i1039.RefreshJoinCodeUseCase(gh<_i123.SharedSessionRepository>()),
    );
    gh.factory<_i351.FeedRepository>(
      () => _i213.FeedRepositoryImpl(gh<_i539.FeedRemoteDataSource>()),
    );
    gh.factory<_i502.SocialProfileRepository>(
      () => _i810.SocialProfileRepositoryImpl(
        gh<_i165.SocialProfileRemoteDataSource>(),
      ),
    );
    gh.factory<_i271.BackupRepository>(
      () => _i44.BackupRepositoryImpl(
        gh<_i757.BackupRemoteDataSource>(),
        gh<_i761.BackupLocalDataSource>(),
        gh<_i684.E2eBackupCodec>(),
        gh<_i895.Connectivity>(),
      ),
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
    gh.factory<_i364.AiDecisionLogCubit>(
      () => _i364.AiDecisionLogCubit(gh<_i646.AiDecisionLogRepository>()),
    );
    gh.factory<_i213.AuthRepository>(
      () => _i50.AuthRepositoryImpl(
        gh<_i284.AuthRemoteDataSource>(),
        gh<_i79.AppDatabase>(),
        gh<_i42.SupabaseClientProvider>(),
      ),
    );
    gh.factory<_i748.DataExportService>(
      () => _i748.DataExportService(
        gh<_i272.ProgressLocalDataSource>(),
        gh<_i646.AiDecisionLogRepository>(),
      ),
    );
    gh.factory<_i544.BackupNowUseCase>(
      () => _i544.BackupNowUseCase(gh<_i271.BackupRepository>()),
    );
    gh.factory<_i609.DisableBackupUseCase>(
      () => _i609.DisableBackupUseCase(gh<_i271.BackupRepository>()),
    );
    gh.factory<_i285.EnableBackupUseCase>(
      () => _i285.EnableBackupUseCase(gh<_i271.BackupRepository>()),
    );
    gh.factory<_i134.IsBackupEnabledUseCase>(
      () => _i134.IsBackupEnabledUseCase(gh<_i271.BackupRepository>()),
    );
    gh.factory<_i122.RestoreBackupUseCase>(
      () => _i122.RestoreBackupUseCase(gh<_i271.BackupRepository>()),
    );
    gh.factory<_i618.GetFeedUseCase>(
      () => _i618.GetFeedUseCase(gh<_i351.FeedRepository>()),
    );
    gh.factory<_i332.ReactToEntryUseCase>(
      () => _i332.ReactToEntryUseCase(gh<_i351.FeedRepository>()),
    );
    gh.factory<_i731.RevokeFeedEntryUseCase>(
      () => _i731.RevokeFeedEntryUseCase(gh<_i351.FeedRepository>()),
    );
    gh.factory<_i615.ShareFeedEntryUseCase>(
      () => _i615.ShareFeedEntryUseCase(gh<_i351.FeedRepository>()),
    );
    gh.factory<_i206.WeatherLocalDataSource>(
      () => _i206.WeatherLocalDataSource(gh<_i194.WeatherCacheDao>()),
    );
    gh.factory<_i1023.GetSocialProfileUseCase>(
      () => _i1023.GetSocialProfileUseCase(gh<_i502.SocialProfileRepository>()),
    );
    gh.factory<_i846.UpdateHandleUseCase>(
      () => _i846.UpdateHandleUseCase(gh<_i502.SocialProfileRepository>()),
    );
    gh.factory<_i586.UpdateVisibilityTierUseCase>(
      () => _i586.UpdateVisibilityTierUseCase(
        gh<_i502.SocialProfileRepository>(),
      ),
    );
    gh.factory<_i168.DeviceSettingsCubit>(
      () => _i168.DeviceSettingsCubit(
        gh<_i311.HealthDataSource>(),
        gh<_i694.SyncQueueDao>(),
        gh<_i194.WeatherCacheDao>(),
        gh<_i224.ExerciseCacheDao>(),
        gh<_i780.SyncManager>(),
        gh<_i895.Connectivity>(),
      ),
    );
    gh.factory<_i342.GetExercisesByType>(
      () => _i342.GetExercisesByType(gh<_i207.ExerciseRepository>()),
    );
    gh.factory<_i574.SyncExerciseCatalog>(
      () => _i574.SyncExerciseCatalog(gh<_i207.ExerciseRepository>()),
    );
    gh.factory<_i606.SharedSessionCreationCubit>(
      () => _i606.SharedSessionCreationCubit(
        gh<_i532.CreateSharedSessionUseCase>(),
      ),
    );
    gh.factory<_i439.ProgressGatingCubit>(
      () => _i439.ProgressGatingCubit(gh<_i589.GetInstallCohortUseCase>()),
    );
    gh.factory<_i401.FriendsRepository>(
      () => _i500.FriendsRepositoryImpl(gh<_i27.FriendsRemoteDataSource>()),
    );
    gh.factory<_i180.ProgressComparisonRepository>(
      () => _i718.ProgressComparisonRepositoryImpl(
        gh<_i1003.ProgressComparisonRemoteDataSource>(),
      ),
    );
    gh.factory<_i811.EntitlementRepository>(
      () => _i705.EntitlementRepositoryImpl(gh<_i499.EntitlementGate>()),
    );
    gh.factory<_i984.GetSensorContext>(
      () => _i984.GetSensorContext(
        gh<_i746.GetHealthData>(),
        gh<_i1.GetActivityLevel>(),
      ),
    );
    gh.factory<_i385.SharedSessionJoinCubit>(
      () => _i385.SharedSessionJoinCubit(gh<_i31.JoinSharedSessionUseCase>()),
    );
    gh.factory<_i705.DataExportCubit>(
      () => _i705.DataExportCubit(gh<_i748.DataExportService>()),
    );
    gh.factory<_i303.CheckEntitlementUseCase>(
      () => _i303.CheckEntitlementUseCase(gh<_i811.EntitlementRepository>()),
    );
    gh.factory<_i326.GetOfferingsUseCase>(
      () => _i326.GetOfferingsUseCase(gh<_i811.EntitlementRepository>()),
    );
    gh.factory<_i421.PurchaseProUseCase>(
      () => _i421.PurchaseProUseCase(gh<_i811.EntitlementRepository>()),
    );
    gh.factory<_i487.RestorePurchasesUseCase>(
      () => _i487.RestorePurchasesUseCase(gh<_i811.EntitlementRepository>()),
    );
    gh.factory<_i748.WeatherRepository>(
      () => _i61.WeatherRepositoryImpl(
        gh<_i209.WeatherRemoteDataSource>(),
        gh<_i206.WeatherLocalDataSource>(),
        gh<_i160.LocationService>(),
      ),
    );
    gh.factory<_i596.SharedSessionBloc>(
      () => _i596.SharedSessionBloc(
        gh<_i281.RealtimeGateway>(),
        gh<_i102.DeleteSharedSessionUseCase>(),
        gh<_i1039.RefreshJoinCodeUseCase>(),
        gh<_i160.LocationService>(),
        gh<_i79.AppDatabase>(),
      ),
    );
    gh.factory<_i1033.GetFriendsComparisonUseCase>(
      () => _i1033.GetFriendsComparisonUseCase(
        gh<_i180.ProgressComparisonRepository>(),
      ),
    );
    gh.factory<_i649.PaywallCubit>(
      () => _i649.PaywallCubit(gh<_i326.GetOfferingsUseCase>()),
    );
    gh.factory<_i111.FeedBloc>(
      () => _i111.FeedBloc(
        gh<_i618.GetFeedUseCase>(),
        gh<_i332.ReactToEntryUseCase>(),
        gh<_i731.RevokeFeedEntryUseCase>(),
      ),
    );
    gh.lazySingleton<_i73.ProgressRepository>(
      () => _i1027.ProgressRepositoryImpl(gh<_i272.ProgressLocalDataSource>()),
    );
    gh.factory<_i623.DeleteAccountUseCase>(
      () => _i623.DeleteAccountUseCase(gh<_i213.AuthRepository>()),
    );
    gh.factory<_i1032.ExportDataUseCase>(
      () => _i1032.ExportDataUseCase(gh<_i213.AuthRepository>()),
    );
    gh.factory<_i330.GetSignedInUserUseCase>(
      () => _i330.GetSignedInUserUseCase(gh<_i213.AuthRepository>()),
    );
    gh.factory<_i200.SignInWithAppleUseCase>(
      () => _i200.SignInWithAppleUseCase(gh<_i213.AuthRepository>()),
    );
    gh.factory<_i114.SignInWithEmailUseCase>(
      () => _i114.SignInWithEmailUseCase(gh<_i213.AuthRepository>()),
    );
    gh.factory<_i56.SignInWithGoogleUseCase>(
      () => _i56.SignInWithGoogleUseCase(gh<_i213.AuthRepository>()),
    );
    gh.factory<_i455.SignOutUseCase>(
      () => _i455.SignOutUseCase(gh<_i213.AuthRepository>()),
    );
    gh.factory<_i986.SignUpWithEmailUseCase>(
      () => _i986.SignUpWithEmailUseCase(gh<_i213.AuthRepository>()),
    );
    gh.factory<_i1038.GetOwnWeeklySummaryUseCase>(
      () => _i1038.GetOwnWeeklySummaryUseCase(gh<_i73.ProgressRepository>()),
    );
    gh.lazySingleton<_i303.GetProgressStats>(
      () => _i303.GetProgressStats(gh<_i73.ProgressRepository>()),
    );
    gh.lazySingleton<_i727.GetSessionHistory>(
      () => _i727.GetSessionHistory(gh<_i73.ProgressRepository>()),
    );
    gh.factory<_i418.ProgressComparisonBloc>(
      () => _i418.ProgressComparisonBloc(
        gh<_i1033.GetFriendsComparisonUseCase>(),
        gh<_i1038.GetOwnWeeklySummaryUseCase>(),
      ),
    );
    gh.factory<_i477.SocialProfileBloc>(
      () => _i477.SocialProfileBloc(
        gh<_i1023.GetSocialProfileUseCase>(),
        gh<_i846.UpdateHandleUseCase>(),
        gh<_i586.UpdateVisibilityTierUseCase>(),
      ),
    );
    gh.lazySingleton<_i916.SessionsCatalogCubit>(
      () => _i916.SessionsCatalogCubit(gh<_i342.GetExercisesByType>()),
    );
    gh.factory<_i563.AcceptRequestUseCase>(
      () => _i563.AcceptRequestUseCase(gh<_i401.FriendsRepository>()),
    );
    gh.factory<_i662.DeclineRequestUseCase>(
      () => _i662.DeclineRequestUseCase(gh<_i401.FriendsRepository>()),
    );
    gh.factory<_i879.GetFriendsUseCase>(
      () => _i879.GetFriendsUseCase(gh<_i401.FriendsRepository>()),
    );
    gh.factory<_i282.GetPendingRequestsUseCase>(
      () => _i282.GetPendingRequestsUseCase(gh<_i401.FriendsRepository>()),
    );
    gh.factory<_i816.RemoveFriendUseCase>(
      () => _i816.RemoveFriendUseCase(gh<_i401.FriendsRepository>()),
    );
    gh.factory<_i482.SearchByHandleUseCase>(
      () => _i482.SearchByHandleUseCase(gh<_i401.FriendsRepository>()),
    );
    gh.factory<_i623.SendFriendRequestUseCase>(
      () => _i623.SendFriendRequestUseCase(gh<_i401.FriendsRepository>()),
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
    gh.factory<_i844.SubscriptionBloc>(
      () => _i844.SubscriptionBloc(
        gh<_i303.CheckEntitlementUseCase>(),
        gh<_i421.PurchaseProUseCase>(),
        gh<_i487.RestorePurchasesUseCase>(),
      ),
    );
    gh.factory<_i664.GetWeatherContext>(
      () => _i664.GetWeatherContext(gh<_i748.WeatherRepository>()),
    );
    gh.factory<_i412.AuthBloc>(
      () => _i412.AuthBloc(
        gh<_i330.GetSignedInUserUseCase>(),
        gh<_i200.SignInWithAppleUseCase>(),
        gh<_i56.SignInWithGoogleUseCase>(),
        gh<_i114.SignInWithEmailUseCase>(),
        gh<_i986.SignUpWithEmailUseCase>(),
        gh<_i455.SignOutUseCase>(),
        gh<_i623.DeleteAccountUseCase>(),
      ),
    );
    gh.factory<_i627.ExportDataCubit>(
      () => _i627.ExportDataCubit(gh<_i1032.ExportDataUseCase>()),
    );
    gh.factory<_i829.FriendsBloc>(
      () => _i829.FriendsBloc(
        gh<_i879.GetFriendsUseCase>(),
        gh<_i282.GetPendingRequestsUseCase>(),
        gh<_i482.SearchByHandleUseCase>(),
        gh<_i623.SendFriendRequestUseCase>(),
        gh<_i563.AcceptRequestUseCase>(),
        gh<_i662.DeclineRequestUseCase>(),
        gh<_i816.RemoveFriendUseCase>(),
      ),
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
    gh.factory<_i57.BackupBloc>(
      () => _i57.BackupBloc(
        gh<_i285.EnableBackupUseCase>(),
        gh<_i609.DisableBackupUseCase>(),
        gh<_i544.BackupNowUseCase>(),
        gh<_i122.RestoreBackupUseCase>(),
        gh<_i134.IsBackupEnabledUseCase>(),
        gh<_i412.AuthBloc>(),
      ),
    );
    return this;
  }
}

class _$HealthModule extends _i294.HealthModule {}

class _$NetworkModule extends _i731.NetworkModule {}

class _$SecureStorageModule extends _i621.SecureStorageModule {}

class _$SettingsModule extends _i389.SettingsModule {}
