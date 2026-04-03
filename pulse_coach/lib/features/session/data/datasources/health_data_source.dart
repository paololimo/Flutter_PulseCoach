import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/session/domain/entities/health_data.dart';

@injectable
class HealthDataSource {
  final Health _health;
  HealthDataSource(this._health);

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
}
