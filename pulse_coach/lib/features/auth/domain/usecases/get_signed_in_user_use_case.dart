import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';

@injectable
class GetSignedInUserUseCase {
  final AuthRepository _repository;
  GetSignedInUserUseCase(this._repository);

  Future<AuthUser?> call() => _repository.getSignedInUser();
}
