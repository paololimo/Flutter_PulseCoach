import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef AccelerometerStreamFactory = Stream<AccelerometerEvent> Function();

@injectable
class AccelerometerDataSource {
  static const int _sampleCount = 30;
  static const int _minSampleCount = 10;
  static const Duration _timeout = Duration(seconds: 5);

  // Thresholds for std dev of acceleration magnitude (m/s²)
  static const double _sedentaryThreshold = 0.3;
  static const double _moderateThreshold = 1.5;

  final AccelerometerStreamFactory? _streamOverride;

  /// Production constructor — injectable picks this up, no external dependencies.
  AccelerometerDataSource() : _streamOverride = null;

  /// Testing constructor — injects a custom stream factory; not used by DI.
  @visibleForTesting
  AccelerometerDataSource.withOverride(AccelerometerStreamFactory streamOverride)
      : _streamOverride = streamOverride;

  Stream<AccelerometerEvent> get _stream =>
      _streamOverride?.call() ??
      accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval);

  Future<ActivityLevel> fetchActivityLevel() async {
    try {
      final samples = <double>[];
      await for (final event in _stream.timeout(_timeout)) {
        final magnitude = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        if (magnitude.isNaN || magnitude.isInfinite) continue;
        samples.add(magnitude);
        if (samples.length >= _sampleCount) break;
      }

      if (samples.length < _minSampleCount) {
        throw SensorException(
          'Insufficient samples: ${samples.length}',
        );
      }

      // Classify by std dev of magnitudes (orientation-invariant)
      final mean = samples.reduce((a, b) => a + b) / samples.length;
      final variance = samples
              .map((m) => (m - mean) * (m - mean))
              .reduce((a, b) => a + b) /
          samples.length;
      final stdDev = sqrt(variance);

      if (stdDev < _sedentaryThreshold) return ActivityLevel.sedentary;
      if (stdDev < _moderateThreshold) return ActivityLevel.moderate;
      return ActivityLevel.active;
    } on SensorException {
      rethrow;
    } catch (e) {
      throw SensorException(e.toString());
    }
  }
}
