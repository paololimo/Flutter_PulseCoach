import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignOutUseCase {
  final AuthRepository _repository;
  SignOutUseCase(this._repository);

  Future<Either<AuthFailure, Unit>> call() => _repository.signOut();
}
