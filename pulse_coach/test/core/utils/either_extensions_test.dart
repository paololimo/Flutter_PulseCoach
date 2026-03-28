import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/utils/either_extensions.dart';

void main() {
  group('EitherX extensions', () {
    // dartz 0.10.1 provides isLeft() and isRight() as methods on Either.
    test('isRight() true for Right (dartz native)', () {
      const e = Right<String, int>(42);
      expect(e.isRight(), isTrue);
      expect(e.isLeft(), isFalse);
    });

    test('isLeft() true for Left (dartz native)', () {
      const e = Left<String, int>('error');
      expect(e.isLeft(), isTrue);
      expect(e.isRight(), isFalse);
    });

    test('rightOrNull returns value for Right', () {
      const e = Right<String, int>(42);
      expect(e.rightOrNull, 42);
    });

    test('rightOrNull returns null for Left', () {
      const e = Left<String, int>('error');
      expect(e.rightOrNull, isNull);
    });

    test('leftOrNull returns value for Left', () {
      const e = Left<String, int>('error');
      expect(e.leftOrNull, 'error');
    });

    test('leftOrNull returns null for Right', () {
      const e = Right<String, int>(42);
      expect(e.leftOrNull, isNull);
    });
  });
}
