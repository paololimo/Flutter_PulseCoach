import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignUpWithEmailUseCase {
  final AuthRepository _repository;
  SignUpWithEmailUseCase(this._repository);

  /// Returns `Right(null)` when email confirmation is pending.
  Future<Either<AuthFailure, AuthUser?>> call({
    required String email,
    required String password,
  }) =>
      _repository.signUp(email: email, password: password);
}
