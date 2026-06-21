import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';

@injectable
class DeleteAccountUseCase {
  final AuthRepository _repository;
  DeleteAccountUseCase(this._repository);

  Future<Either<AuthFailure, Unit>> call() => _repository.deleteAccount();
}
