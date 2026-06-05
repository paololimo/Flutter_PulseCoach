import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/exercise_cache_dao.dart';
import 'package:pulse_coach/core/database/daos/sync_queue_dao.dart';
import 'package:pulse_coach/core/database/daos/weather_cache_dao.dart';
import 'package:pulse_coach/core/sync/sync_manager.dart';
import 'package:pulse_coach/features/session/data/datasources/health_data_source.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_state.dart';

import 'device_settings_cubit_test.mocks.dart';

@GenerateMocks([
  HealthDataSource,
  SyncQueueDao,
  WeatherCacheDao,
  ExerciseCacheDao,
  SyncManager,
  Connectivity,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const watchChannel = MethodChannel('watch_connectivity/methods');

  late MockHealthDataSource health;
  late MockSyncQueueDao syncQueueDao;
  late MockWeatherCacheDao weatherCacheDao;
  late MockExerciseCacheDao exerciseCacheDao;
  late MockSyncManager syncManager;
  late MockConnectivity connectivity;
  late DeviceSettingsCubit cubit;

  final weatherCachedAt = DateTime.utc(2026, 6, 5, 8);
  final olderExerciseCachedAt = DateTime.utc(2026, 6, 4, 8);
  final exerciseCachedAt = DateTime.utc(2026, 6, 5, 9);

  setUp(() {
    health = MockHealthDataSource();
    syncQueueDao = MockSyncQueueDao();
    weatherCacheDao = MockWeatherCacheDao();
    exerciseCacheDao = MockExerciseCacheDao();
    syncManager = MockSyncManager();
    connectivity = MockConnectivity();
    cubit = DeviceSettingsCubit(
      health,
      syncQueueDao,
      weatherCacheDao,
      exerciseCacheDao,
      syncManager,
      connectivity,
    );

    _stubLoadDefaults(
      health: health,
      syncQueueDao: syncQueueDao,
      weatherCacheDao: weatherCacheDao,
      exerciseCacheDao: exerciseCacheDao,
      connectivity: connectivity,
      weatherCachedAt: weatherCachedAt,
      olderExerciseCachedAt: olderExerciseCachedAt,
      exerciseCachedAt: exerciseCachedAt,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(watchChannel, (call) async {
          if (call.method == 'isReachable') return true;
          return null;
        });
  });

  tearDown(() async {
    await cubit.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(watchChannel, null);
  });

  test(
    '14.3-CUBIT-001: load() emits loaded state with healthPermission from hasPermissions',
    () async {
      when(health.checkPermissions()).thenAnswer((_) async => false);

      await cubit.load();

      expect(
        cubit.state,
        DeviceSettingsState(
          isLoading: false,
          healthPermissionGranted: false,
          isWearConnected: true,
          pendingSyncCount: 2,
          weatherCachedAt: weatherCachedAt,
          exerciseCachedAt: exerciseCachedAt,
          isOnline: true,
        ),
      );
    },
  );

  test(
    '14.3-CUBIT-002: load() emits isWearConnected from WatchConnectivity.isReachable',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(watchChannel, (call) async {
            if (call.method == 'isReachable') return false;
            return null;
          });

      await cubit.load();

      expect(cubit.state.isWearConnected, false);
    },
  );

  test(
    '14.3-CUBIT-003: load() emits pendingSyncCount = count of entries in queue',
    () async {
      when(
        syncQueueDao.getPendingEntries(),
      ).thenAnswer((_) async => [_syncEntry(1), _syncEntry(2), _syncEntry(3)]);

      await cubit.load();

      expect(cubit.state.pendingSyncCount, 3);
    },
  );

  test(
    '14.3-CUBIT-004: load() emits weatherCachedAt from WeatherCacheDao.getLatestCache()',
    () async {
      final latest = DateTime.utc(2026, 6, 5, 11);
      when(
        weatherCacheDao.getLatestCache(),
      ).thenAnswer((_) async => _weatherCache(latest));

      await cubit.load();

      expect(cubit.state.weatherCachedAt, latest);
    },
  );

  test(
    '14.3-CUBIT-005: requestHealthPermission() calls requestAuthorization then reloads',
    () async {
      when(health.requestPermissions()).thenAnswer((_) async => true);

      await cubit.requestHealthPermission();

      verify(health.requestPermissions()).called(1);
      verify(health.checkPermissions()).called(1);
      expect(cubit.state.isLoading, false);
    },
  );

  test(
    '14.3-CUBIT-006: syncNow() calls SyncManager.processQueue() then reloads',
    () async {
      when(syncManager.processQueue()).thenAnswer((_) async {});

      await cubit.syncNow();

      verify(syncManager.processQueue()).called(1);
      verify(syncQueueDao.getPendingEntries()).called(1);
      expect(cubit.state.isLoading, false);
    },
  );
}

void _stubLoadDefaults({
  required MockHealthDataSource health,
  required MockSyncQueueDao syncQueueDao,
  required MockWeatherCacheDao weatherCacheDao,
  required MockExerciseCacheDao exerciseCacheDao,
  required MockConnectivity connectivity,
  required DateTime weatherCachedAt,
  required DateTime olderExerciseCachedAt,
  required DateTime exerciseCachedAt,
}) {
  when(health.checkPermissions()).thenAnswer((_) async => true);
  when(
    syncQueueDao.getPendingEntries(),
  ).thenAnswer((_) async => [_syncEntry(1), _syncEntry(2)]);
  when(
    weatherCacheDao.getLatestCache(),
  ).thenAnswer((_) async => _weatherCache(weatherCachedAt));
  when(exerciseCacheDao.getAll()).thenAnswer(
    (_) async => [
      _exerciseCache(1, olderExerciseCachedAt),
      _exerciseCache(2, exerciseCachedAt),
    ],
  );
  when(
    connectivity.checkConnectivity(),
  ).thenAnswer((_) async => [ConnectivityResult.wifi]);
}

SyncQueueEntry _syncEntry(int id) {
  return SyncQueueEntry(
    id: id,
    eventType: 'session_completed',
    payload: '{}',
    retryCount: 0,
    createdAt: DateTime.utc(2026, 6, 5, 8),
  );
}

WeatherCacheData _weatherCache(DateTime cachedAt) {
  return WeatherCacheData(
    id: 1,
    latitude: 45.46,
    longitude: 9.19,
    temperature: 22,
    precipitationProbability: 0,
    aqiValue: 20,
    cachedAt: cachedAt,
  );
}

ExerciseCacheData _exerciseCache(int id, DateTime cachedAt) {
  return ExerciseCacheData(
    id: id,
    exerciseId: 'exercise-$id',
    exerciseJson: '{}',
    cachedAt: cachedAt,
  );
}
