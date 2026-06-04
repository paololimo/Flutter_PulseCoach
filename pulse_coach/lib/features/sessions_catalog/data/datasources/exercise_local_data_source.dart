import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/exercise_cache_dao.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/sessions_catalog/data/models/exercise_model.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';

@injectable
class ExerciseLocalDataSource {
  ExerciseLocalDataSource(this._dao);

  final ExerciseCacheDao _dao;

  Future<List<CachedExerciseEntry>> getCachedExercisesByType(
    String sessionType,
  ) async {
    final normalizedType = sessionType.trim().toLowerCase();
    if (normalizedType != sessionType) {
      AppLogger.debug(
        'sessionType "$sessionType" normalized to "$normalizedType"',
        name: 'ExerciseLocalDataSource',
      );
    }
    if (normalizedType.isEmpty) {
      AppLogger.debug(
        'Empty sessionType passed - returning empty list',
        name: 'ExerciseLocalDataSource',
      );
      return List.unmodifiable(const <CachedExerciseEntry>[]);
    }

    final List<ExerciseCacheData> rows;
    try {
      rows = await _dao.getAll();
    } catch (e) {
      throw CacheException('Failed to read exercise cache: $e');
    }

    final entries = <CachedExerciseEntry>[];
    // Aggregate corrupt-row diagnostics into a single error log after the loop
    // so a corrupt cache cannot emit one release log line per bad row.
    var corruptRowCount = 0;
    Object? firstCorruptError;
    StackTrace? firstCorruptStackTrace;
    for (final row in rows) {
      try {
        final exercise = ExerciseModel.fromPulseCoachJson(
          jsonDecode(row.exerciseJson) as Map<String, dynamic>,
        ).toEntity();
        if (exercise.sessionType == normalizedType) {
          entries.add(
            CachedExerciseEntry(exercise: exercise, cachedAt: row.cachedAt),
          );
        }
      } catch (e, st) {
        // Skip individual corrupt rows so one bad payload cannot poison the
        // entire cache for every session type.
        corruptRowCount++;
        firstCorruptError ??= e;
        firstCorruptStackTrace ??= st;
      }
    }
    if (corruptRowCount > 0) {
      AppLogger.error(
        'Skipped $corruptRowCount corrupt cache row(s)',
        name: 'ExerciseLocalDataSource',
        error: firstCorruptError,
        stackTrace: firstCorruptStackTrace,
      );
    }
    if (entries.isEmpty) {
      AppLogger.debug(
        'No cached exercises found for sessionType "$normalizedType"',
        name: 'ExerciseLocalDataSource',
      );
    }
    return List.unmodifiable(entries);
  }

  Future<void> cacheExercises(
    List<Exercise> exercises,
    DateTime cachedAt,
  ) async {
    try {
      await _dao.insertOrReplaceBatch([
        for (final exercise in exercises)
          ExerciseCacheCompanion.insert(
            exerciseId: exercise.id,
            exerciseJson: jsonEncode(exercise.toJson()),
            cachedAt: cachedAt,
          ),
      ]);
    } catch (e) {
      throw CacheException('Failed to write exercise cache: $e');
    }
  }

  Future<void> replaceCache(List<Exercise> exercises, DateTime cachedAt) async {
    try {
      await _dao.deleteAll();
      if (exercises.isEmpty) {
        return;
      }
      await _dao.insertOrReplaceBatch([
        for (final exercise in exercises)
          ExerciseCacheCompanion.insert(
            exerciseId: exercise.id,
            exerciseJson: jsonEncode(exercise.toJson()),
            cachedAt: cachedAt,
          ),
      ]);
    } catch (e) {
      throw CacheException('Failed to replace exercise cache: $e');
    }
  }

  Future<List<Exercise>> loadFallbackExercisesByType(String sessionType) async {
    final normalizedType = sessionType.trim().toLowerCase();
    if (normalizedType != sessionType) {
      AppLogger.debug(
        'sessionType "$sessionType" normalized to "$normalizedType"',
        name: 'ExerciseLocalDataSource',
      );
    }
    if (normalizedType.isEmpty) {
      AppLogger.debug(
        'Empty sessionType passed - returning empty list',
        name: 'ExerciseLocalDataSource',
      );
      return List.unmodifiable(const <Exercise>[]);
    }

    final String jsonString;
    final dynamic decoded;
    try {
      jsonString = await rootBundle.loadString(
        'assets/data/fallback_exercises.json',
      );
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw CacheException('Failed to load fallback exercises: $e');
    }

    if (decoded is! List) {
      throw const CacheException('Fallback exercises must be a JSON list');
    }

    final exercises = <Exercise>[];
    final seen = <String>{};
    // Aggregate malformed-record diagnostics into a single error log after the
    // loop so a corrupt fallback file cannot emit one release log line per bad
    // record.
    var malformedCount = 0;
    Object? firstMalformedError;
    StackTrace? firstMalformedStackTrace;
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      try {
        final exercise = Exercise.fromJson(entry);
        if (exercise.sessionType == normalizedType) {
          if (!seen.add(exercise.id)) {
            AppLogger.warning(
              'Duplicate fallback id "${exercise.id}" - skipping',
              name: 'ExerciseLocalDataSource',
            );
            continue;
          }
          exercises.add(exercise);
        }
      } catch (e, st) {
        // Skip individual malformed fallback records so one bad entry cannot
        // wipe the entire degraded path.
        malformedCount++;
        firstMalformedError ??= e;
        firstMalformedStackTrace ??= st;
      }
    }
    if (malformedCount > 0) {
      AppLogger.error(
        'Skipped $malformedCount malformed fallback record(s)',
        name: 'ExerciseLocalDataSource',
        error: firstMalformedError,
        stackTrace: firstMalformedStackTrace,
      );
    }
    if (exercises.isEmpty) {
      AppLogger.debug(
        'No fallback exercises found for sessionType "$normalizedType"',
        name: 'ExerciseLocalDataSource',
      );
    }
    return List.unmodifiable(exercises);
  }
}

class CachedExerciseEntry {
  const CachedExerciseEntry({required this.exercise, required this.cachedAt});

  final Exercise exercise;
  final DateTime cachedAt;
}
