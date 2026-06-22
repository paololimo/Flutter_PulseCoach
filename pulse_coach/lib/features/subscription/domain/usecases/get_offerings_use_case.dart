import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
import 'package:pulse_coach/features/subscription/domain/repositories/entitlement_repository.dart';

@injectable
class GetOfferingsUseCase {
  final EntitlementRepository _repository;
  GetOfferingsUseCase(this._repository);

  Future<Either<Failure, List<ProOffer>>> call() => _repository.getOfferings();
}
