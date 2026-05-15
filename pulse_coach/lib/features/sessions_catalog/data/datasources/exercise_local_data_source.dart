import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/exercise_cache_dao.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
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
      developer.log(
        'sessionType "$sessionType" normalized to "$normalizedType"',
        name: 'ExerciseLocalDataSource',
      );
    }
    if (normalizedType.isEmpty) {
      developer.log(
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
      } catch (e) {
        // Skip individual corrupt rows so one bad payload cannot poison the
        // entire cache for every session type.
        developer.log(
          'Skipping corrupt cache row ${row.exerciseId}',
          name: 'ExerciseLocalDataSource',
          error: e,
        );
      }
    }
    if (entries.isEmpty) {
      developer.log(
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
      developer.log(
        'sessionType "$sessionType" normalized to "$normalizedType"',
        name: 'ExerciseLocalDataSource',
      );
    }
    if (normalizedType.isEmpty) {
      developer.log(
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
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      try {
        final exercise = Exercise.fromJson(entry);
        if (exercise.sessionType == normalizedType) {
          if (!seen.add(exercise.id)) {
            developer.log(
              'Duplicate fallback id "${exercise.id}" - skipping',
              name: 'ExerciseLocalDataSource',
            );
            continue;
          }
          exercises.add(exercise);
        }
      } catch (e) {
        // Skip individual malformed fallback records so one bad entry cannot
        // wipe the entire degraded path.
        developer.log(
          'Skipping malformed fallback record',
          name: 'ExerciseLocalDataSource',
          error: e,
        );
      }
    }
    if (exercises.isEmpty) {
      developer.log(
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
