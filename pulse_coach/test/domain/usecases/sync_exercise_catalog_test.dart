import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/repositories/exercise_repository.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/sync_exercise_catalog.dart';

void main() {
  group('SyncExerciseCatalog', () {
    late _FakeExerciseRepository repository;
    late SyncExerciseCatalog useCase;

    setUp(() {
      repository = _FakeExerciseRepository();
      useCase = SyncExerciseCatalog(repository);
    });

    test(
      '6.1-UC-001: call delegates to ExerciseRepository.syncCatalog and returns Right(unit)',
      () async {
        repository.syncResult = const Right(unit);

        final result = await useCase();

        expect(result, const Right<Failure, Unit>(unit));
        expect(repository.syncCatalogCalls, 1);
      },
    );

    test('6.1-UC-002: call propagates repository failure', () async {
      repository.syncResult = const Left(CacheFailure('sync failed'));

      final result = await useCase();

      expect(result, const Left<Failure, Unit>(CacheFailure('sync failed')));
      expect(repository.syncCatalogCalls, 1);
    });
  });
}

class _FakeExerciseRepository implements ExerciseRepository {
  Either<Failure, Unit> syncResult = const Right(unit);
  int syncCatalogCalls = 0;

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesByType(
    String sessionType,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Unit>> syncCatalog() async {
    syncCatalogCalls++;
    return syncResult;
  }
}
