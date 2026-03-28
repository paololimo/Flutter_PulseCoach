import 'package:dartz/dartz.dart';

// Note: dartz 0.10.1 already defines isLeft() and isRight() as methods on Either.
// This extension adds null-returning convenience getters not provided by dartz.
extension EitherX<L, R> on Either<L, R> {
  R? get rightOrNull => fold((_) => null, (r) => r);
  L? get leftOrNull => fold((l) => l, (_) => null);
}
