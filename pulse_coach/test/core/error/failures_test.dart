import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/failures.dart';

void main() {
  group('Failure types', () {
    test('ServerFailure stores message', () {
      const f = ServerFailure('server error');
      expect(f.message, 'server error');
      expect(f, isA<Failure>());
    });

    test('CacheFailure stores message', () {
      const f = CacheFailure('cache miss');
      expect(f.message, 'cache miss');
      expect(f, isA<Failure>());
    });

    test('SensorFailure stores message', () {
      const f = SensorFailure('sensor unavailable');
      expect(f.message, 'sensor unavailable');
      expect(f, isA<Failure>());
    });

    test('LocationFailure stores message', () {
      const f = LocationFailure('permission denied');
      expect(f.message, 'permission denied');
      expect(f, isA<Failure>());
    });
  });
}
