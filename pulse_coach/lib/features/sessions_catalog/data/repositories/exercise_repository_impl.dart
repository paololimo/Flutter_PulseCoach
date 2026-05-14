import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_local_data_source.dart';
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_remote_data_source.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/repositories/exercise_repository.dart';

@Injectable(as: ExerciseRepository)
class ExerciseRepositoryImpl implements ExerciseRepository {
  ExerciseRepositoryImpl(this._remote, this._local);

  final ExerciseRemoteDataSource _remote;
  final ExerciseLocalDataSource _local;

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesByType(
    String sessionType,
  ) async {
    List<CachedExerciseEntry> cachedEntries;
    try {
      cachedEntries = await _local.getCachedExercisesByType(sessionType);
    } on CacheException {
      cachedEntries = const [];
    }

    if (cachedEntries.isNotEmpty && _isCacheValid(cachedEntries)) {
      return Right(
        cachedEntries.map((entry) => entry.exercise).toList(growable: false),
      );
    }

    try {
      final remoteExercises = (await _remote.fetchExercisesByType(
        sessionType,
      )).map((model) => model.toEntity()).toList(growable: false);
      if (remoteExercises.isNotEmpty) {
        try {
          await _local.cacheExercises(remoteExercises, DateTime.now().toUtc());
        } on CacheException {
          // Fresh remote data is still returned even if cache write fails.
        }
        return Right(remoteExercises);
      }
      // Remote succeeded but produced no mappable records — treat as a
      // recovery condition so the stale-cache → fallback chain still runs.
      final recovered = await _recoverFromFallbacks(
        cachedEntries: cachedEntries,
        sessionType: sessionType,
        reason: 'remote returned no mappable exercises',
      );
      return recovered;
    } on ServerException catch (e) {
      return _recoverFromFallbacks(
        cachedEntries: cachedEntries,
        sessionType: sessionType,
        reason: e.message,
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> syncCatalog() async {
    try {
      final now = DateTime.now().toUtc();
      final remoteModels = await _remote.fetchAll();
      final exercises = _dedupeById(
        remoteModels.map((model) => model.toEntity()),
      );
      if (exercises.isEmpty) {
        return const Left(
          ServerFailure('ExerciseDB returned no mappable exercises'),
        );
      }
      // Replace the whole catalog so records removed upstream are evicted and
      // every surviving row shares the same `cachedAt` for TTL purposes.
      await _local.replaceCache(exercises, now);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  List<Exercise> _dedupeById(Iterable<Exercise> exercises) {
    final seen = <String, Exercise>{};
    for (final exercise in exercises) {
      seen[exercise.id] = exercise;
    }
    return List.unmodifiable(seen.values);
  }

  bool _isCacheValid(List<CachedExerciseEntry> entries) {
    final now = DateTime.now().toUtc();
    final oldestCachedAt = entries
        .map((entry) => entry.cachedAt.toUtc())
        .reduce((left, right) => left.isBefore(right) ? left : right);
    final age = now.difference(oldestCachedAt);
    // Negative age means `cachedAt` is in the future (clock skew or NTP
    // correction). Treat as stale rather than perpetually fresh.
    if (age.isNegative) {
      return false;
    }
    return age < const Duration(hours: 24);
  }

  Future<Either<Failure, List<Exercise>>> _recoverFromFallbacks({
    required List<CachedExerciseEntry> cachedEntries,
    required String sessionType,
    required String reason,
  }) async {
    if (cachedEntries.isNotEmpty) {
      return Right(
        cachedEntries.map((entry) => entry.exercise).toList(growable: false),
      );
    }

    final fallback = await _loadFallback(sessionType);
    if (fallback != null) {
      return Right(fallback);
    }

    return Left(
      CacheFailure('No exercises available for $sessionType ($reason)'),
    );
  }

  Future<List<Exercise>?> _loadFallback(String sessionType) async {
    try {
      final fallback = await _local.loadFallbackExercisesByType(sessionType);
      if (fallback.isNotEmpty) {
        return fallback;
      }
    } on CacheException {
      // Caller decides final failure.
    }
    return null;
  }
}
