import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';

@injectable
class ExportDataUseCase {
  final AuthRepository _repository;
  ExportDataUseCase(this._repository);

  Future<Either<AuthFailure, String>> call() => _repository.exportData();
}
