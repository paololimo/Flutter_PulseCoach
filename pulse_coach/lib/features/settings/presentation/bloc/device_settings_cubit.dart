import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/daos/exercise_cache_dao.dart';
import 'package:pulse_coach/core/database/daos/sync_queue_dao.dart';
import 'package:pulse_coach/core/database/daos/weather_cache_dao.dart';
import 'package:pulse_coach/core/sync/sync_manager.dart';
import 'package:pulse_coach/features/session/data/datasources/health_data_source.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_state.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

@injectable
class DeviceSettingsCubit extends Cubit<DeviceSettingsState> {
  DeviceSettingsCubit(
    this._healthDataSource,
    this._syncQueueDao,
    this._weatherCacheDao,
    this._exerciseCacheDao,
    this._syncManager,
    this._connectivity,
  ) : super(const DeviceSettingsState());

  final HealthDataSource _healthDataSource;
  final SyncQueueDao _syncQueueDao;
  final WeatherCacheDao _weatherCacheDao;
  final ExerciseCacheDao _exerciseCacheDao;
  final SyncManager _syncManager;
  final Connectivity _connectivity;

  Future<void> load() async {
    final results = await Future.wait<Object?>([
      _fetchHealthPermission(),
      _fetchWearStatus(),
      _fetchSyncCount(),
      _fetchWeatherCacheDate(),
      _fetchExerciseCacheDate(),
      _fetchOnlineStatus(),
    ]);

    emit(
      DeviceSettingsState(
        isLoading: false,
        healthPermissionGranted: results[0] as bool?,
        isWearConnected: results[1] as bool?,
        pendingSyncCount: results[2] as int,
        weatherCachedAt: results[3] as DateTime?,
        exerciseCachedAt: results[4] as DateTime?,
        isOnline: results[5] as bool,
      ),
    );
  }

  Future<void> requestHealthPermission() async {
    try {
      await _healthDataSource.requestPermissions();
    } catch (_) {
      // The follow-up load reflects the actual platform permission state.
    }
    await load();
  }

  Future<void> openHealthConnectSettings() async {
    await _healthDataSource.openHealthConnectSettings();
  }

  Future<void> syncNow() async {
    await _syncManager.processQueue();
    await load();
  }

  Future<bool?> _fetchHealthPermission() async {
    try {
      return await _healthDataSource.checkPermissions();
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _fetchWearStatus() async {
    try {
      return await WatchConnectivity().isReachable;
    } catch (_) {
      return null;
    }
  }

  Future<int> _fetchSyncCount() async {
    try {
      return (await _syncQueueDao.getPendingEntries()).length;
    } catch (_) {
      return 0;
    }
  }

  Future<DateTime?> _fetchWeatherCacheDate() async {
    try {
      return (await _weatherCacheDao.getLatestCache())?.cachedAt;
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> _fetchExerciseCacheDate() async {
    try {
      final cachedExercises = await _exerciseCacheDao.getAll();
      if (cachedExercises.isEmpty) return null;
      return cachedExercises
          .map((exercise) => exercise.cachedAt)
          .reduce((latest, next) => latest.isAfter(next) ? latest : next);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _fetchOnlineStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}
