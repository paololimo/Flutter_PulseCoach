import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignInWithAppleUseCase {
  final AuthRepository _repository;
  SignInWithAppleUseCase(this._repository);

  Future<Either<AuthFailure, AuthUser>> call() => _repository.signInWithApple();
}
