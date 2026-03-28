import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/exceptions.dart';

void main() {
  group('Exception types', () {
    test('ServerException stores message', () {
      const e = ServerException('500 Internal Server Error');
      expect(e.message, '500 Internal Server Error');
      expect(e, isA<Exception>());
    });

    test('CacheException stores message', () {
      const e = CacheException('cache empty');
      expect(e.message, 'cache empty');
      expect(e, isA<Exception>());
    });

    test('SensorException stores message', () {
      const e = SensorException('accelerometer not available');
      expect(e.message, 'accelerometer not available');
      expect(e, isA<Exception>());
    });

    test('LocationException stores message', () {
      const e = LocationException('location permission denied');
      expect(e.message, 'location permission denied');
      expect(e, isA<Exception>());
    });
  });
}
