import 'dart:async';

import 'package:health/health.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';

/// Abstracts live HR polling so InSessionCubit can be tested without
/// platform-channel noise.
abstract interface class LiveHrService {
  /// Must be called once before [fetchLiveHr]. Fire-and-forget safe.
  Future<void> init();

  /// Returns the most recent heart-rate reading, or null if unavailable.
  /// Never throws; Health permission and sensor failures degrade silently.
  Future<int?> fetchLiveHr();
}

/// Polls activity heart rate through the `health` package.
class HealthLiveHrService implements LiveHrService {
  HealthLiveHrService(this._health);

  static const int _minBpm = 30;
  static const int _maxBpm = 240;

  final Health _health;
  bool _permissionsGranted = false;
  bool _initialized = false;
  Future<void>? _initFuture;

  @override
  Future<void> init() {
    if (_initialized) return Future<void>.value();
    return _initFuture ??= _runInit();
  }

  Future<void> _runInit() async {
    try {
      await _health.configure();
      _permissionsGranted = await _health.requestAuthorization(
        [HealthDataType.HEART_RATE],
        permissions: [HealthDataAccess.READ],
      );
      _initialized = true;
    } catch (e, st) {
      AppLogger.warning(
        'init failed',
        name: 'HealthLiveHrService',
        error: e,
        stackTrace: st,
      );
      _permissionsGranted = false;
      // Allow retry: do NOT latch _initialized=true on failure.
      _initFuture = null;
    }
  }

  @override
  Future<int?> fetchLiveHr() async {
    if (!_permissionsGranted) return null;

    try {
      final now = DateTime.now();
      final since = now.subtract(const Duration(seconds: 30));
      final points = await _health.getHealthDataFromTypes(
        startTime: since,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );
      // Skip non-numeric subtypes defensively; pick the latest numeric point.
      final numeric = points
          .where((p) => p.value is NumericHealthValue)
          .toList(growable: false);
      if (numeric.isEmpty) return null;
      final raw = (numeric.last.value as NumericHealthValue).numericValue;
      if (!raw.isFinite) return null;
      final bpm = raw.round();
      if (bpm < _minBpm || bpm > _maxBpm) return null;
      return bpm;
    } catch (e, st) {
      AppLogger.warning(
        'fetchLiveHr failed',
        name: 'HealthLiveHrService',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
