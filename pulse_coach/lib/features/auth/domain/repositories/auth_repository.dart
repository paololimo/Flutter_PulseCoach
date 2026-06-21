import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<Either<AuthFailure, AuthUser>> signInWithApple();
  Future<Either<AuthFailure, AuthUser>> signInWithGoogle();
  Future<Either<AuthFailure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Returns `Right(null)` when email confirmation is required (unconfirmed).
  Future<Either<AuthFailure, AuthUser?>> signUp({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, Unit>> signOut();
  Future<AuthUser?> getSignedInUser();
}
