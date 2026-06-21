import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignInWithEmailUseCase {
  final AuthRepository _repository;
  SignInWithEmailUseCase(this._repository);

  Future<Either<AuthFailure, AuthUser>> call({
    required String email,
    required String password,
  }) =>
      _repository.signInWithEmail(email: email, password: password);
}
