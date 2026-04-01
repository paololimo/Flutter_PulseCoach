import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';

@LazySingleton(as: OnboardingRepository)
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<Either<Failure, void>> acceptDisclaimer() async {
    try {
      final existing = await _db.userProfileDao.getProfile();
      if (existing == null) {
        await _db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            disclaimerAccepted: const Value(true),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await _db.userProfileDao.updateProfile(
          existing.copyWith(
            disclaimerAccepted: true,
            updatedAt: DateTime.now(),
          ),
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isDisclaimerAccepted() async {
    try {
      final profile = await _db.userProfileDao.getProfile();
      return Right(profile?.disclaimerAccepted ?? false);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
