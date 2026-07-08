import 'package:flutter/services.dart' show MethodChannel;
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/session/domain/entities/health_data.dart';

@injectable
class HealthDataSource {
  final Health _health;
  HealthDataSource(this._health);

  static const _healthSettingsChannel = MethodChannel(
    'com.pulsecoach.pulse_coach/health_settings',
  );

  /// Deep-links to this app's permission row inside the Health Connect app
  /// (Android only). Useful when Health Connect has already cached a denied
  /// decision and the in-app request dialog no longer resurfaces.
  Future<void> openHealthConnectSettings() async {
    try {
      await _healthSettingsChannel.invokeMethod('openHealthConnectSettings');
    } catch (_) {
      // Best-effort deep link (e.g. iOS has no such channel handler); nothing
      // actionable if it fails.
    }
  }

  static const _readTypes = [
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.STEPS,
  ];

  static const _readPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<HealthData> fetchHealthData() async {
    try {
      await _health.configure();
      final granted = await _health.requestAuthorization(
        _readTypes,
        permissions: _readPermissions,
      );
      if (!granted) {
        throw const SensorException('Health permissions denied');
      }

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final midnight = DateTime(now.year, now.month, now.day);

      // Resting HR: last 24h window (iOS HealthKit only; Android returns empty)
      final hrPoints = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.RESTING_HEART_RATE],
      );

      // Steps: today midnight → now
      final stepsPoints = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      final restingHr = hrPoints.isEmpty
          ? null
          : (hrPoints.last.value as NumericHealthValue).numericValue.round();

      final stepCount = stepsPoints.isEmpty
          ? null
          : stepsPoints.fold<int>(
              0,
              (sum, p) =>
                  sum + (p.value as NumericHealthValue).numericValue.round(),
            );

      return HealthData(restingHr: restingHr, stepCount: stepCount);
    } on SensorException {
      rethrow;
    } catch (e) {
      throw SensorException(e.toString());
    }
  }

  /// Returns the current Health permission state without fetching data.
  /// Returns null if the permission state is unknown or unavailable.
  Future<bool?> checkPermissions() async {
    try {
      await _health.configure();
      return _health.hasPermissions(_readTypes, permissions: _readPermissions);
    } catch (_) {
      return null;
    }
  }

  /// Triggers the OS Health permission dialog and reports whether access was granted.
  Future<bool> requestPermissions() async {
    try {
      await _health.configure();
      return _health.requestAuthorization(
        _readTypes,
        permissions: _readPermissions,
      );
    } catch (_) {
      return false;
    }
  }
}
