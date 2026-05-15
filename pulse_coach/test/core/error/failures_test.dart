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

    group('Failure equality', () {
      test('6.5-EQ-001: same type and message are equal', () {
        const a = ServerFailure('err');
        const b = ServerFailure('err');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('6.5-EQ-002: same type but different message are not equal', () {
        const a = ServerFailure('err1');
        const b = ServerFailure('err2');
        expect(a, isNot(equals(b)));
      });

      test('6.5-EQ-003: different types with same message are not equal', () {
        const a = ServerFailure('err');
        const b = CacheFailure('err');
        expect(a, isNot(equals(b)));
      });

      test('6.5-EQ-004: CacheFailure equality', () {
        expect(const CacheFailure('x'), equals(const CacheFailure('x')));
        expect(const CacheFailure('x'), isNot(equals(const CacheFailure('y'))));
      });

      test('6.5-EQ-005: SensorFailure equality', () {
        expect(const SensorFailure('s'), equals(const SensorFailure('s')));
        expect(
          const SensorFailure('s'),
          isNot(equals(const SensorFailure('t'))),
        );
      });

      test('6.5-EQ-006: LocationFailure equality', () {
        expect(
          const LocationFailure('loc'),
          equals(const LocationFailure('loc')),
        );
        expect(
          const LocationFailure('loc'),
          isNot(equals(const LocationFailure('other'))),
        );
      });

      test('6.5-EQ-007: different types with same message have different hashCode', () {
        expect(
          const ServerFailure('x').hashCode,
          isNot(equals(const CacheFailure('x').hashCode)),
        );
        expect(
          const SensorFailure('x').hashCode,
          isNot(equals(const LocationFailure('x').hashCode)),
        );
      });

      test('6.5-EQ-008: Failure is not equal to null or unrelated Object', () {
        const f = ServerFailure('err');
        expect(f, isNot(equals(null)));
        expect(f, isNot(equals(Object())));
        expect(f, isNot(equals('err')));
      });

      test('6.5-EQ-009: equality is transitive across three instances', () {
        const a = CacheFailure('same');
        const b = CacheFailure('same');
        const c = CacheFailure('same');
        expect(a, equals(b));
        expect(b, equals(c));
        expect(a, equals(c));
        expect(a.hashCode, equals(c.hashCode));
      });
    });
  });
}
