import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/exercise_cache_dao.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_local_data_source.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';

class _ThrowingExerciseCacheDao extends Fake implements ExerciseCacheDao {
  _ThrowingExerciseCacheDao({this.throwOnDelete = false});

  final bool throwOnDelete;

  @override
  Future<int> deleteAll() async {
    if (throwOnDelete) {
      throw StateError('delete failed');
    }
    return 0;
  }

  @override
  Future<void> insertOrReplaceBatch(
    List<ExerciseCacheCompanion> entries,
  ) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ExerciseLocalDataSource sut;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sut = ExerciseLocalDataSource(db.exerciseCacheDao);
  });

  tearDown(() async {
    await db.close();
  });

  const mobilityExercise = Exercise(
    id: 'mobility-1',
    name: 'Neck Rolls',
    description: 'Mobility work.',
    sessionType: 'mobility',
    steps: ['Move slowly'],
    durationMinutes: 4,
    difficulty: 'low',
    indoorCompatible: true,
    outdoorCompatible: true,
  );

  const cardioExercise = Exercise(
    id: 'cardio-1',
    name: 'March In Place',
    description: 'Cardio work.',
    sessionType: 'cardio',
    steps: ['March quickly'],
    durationMinutes: 7,
    difficulty: 'medium',
    indoorCompatible: true,
    outdoorCompatible: true,
  );

  test(
    '6.1-UNIT-002: cacheExercises + getCachedExercisesByType preserves rows and cachedAt',
    () async {
      final cachedAt = DateTime.utc(2026, 5, 14, 9);
      const exercises = [mobilityExercise, cardioExercise];

      await sut.cacheExercises(exercises, cachedAt);

      final cachedMobility = await sut.getCachedExercisesByType('mobility');
      final cachedCardio = await sut.getCachedExercisesByType('cardio');

      expect(cachedMobility, hasLength(1));
      expect(cachedMobility.first.exercise.name, 'Neck Rolls');
      expect(
        cachedMobility.first.cachedAt.toUtc().isAtSameMomentAs(cachedAt),
        isTrue,
      );
      expect(cachedCardio, hasLength(1));
      expect(cachedCardio.first.exercise.durationMinutes, 7);
    },
  );

  test(
    '6.1-LOCAL-007: replaceCache deletes old rows and writes replacement catalog',
    () async {
      final oldCachedAt = DateTime.utc(2026, 5, 14, 9);
      final newCachedAt = DateTime.utc(2026, 5, 15, 9);

      await sut.cacheExercises([mobilityExercise], oldCachedAt);

      await sut.replaceCache([cardioExercise], newCachedAt);

      final mobility = await sut.getCachedExercisesByType('mobility');
      final cardio = await sut.getCachedExercisesByType('cardio');
      final rows = await db.exerciseCacheDao.getAll();

      expect(rows, hasLength(1));
      expect(mobility, isEmpty);
      expect(cardio, hasLength(1));
      expect(cardio.single.exercise.id, 'cardio-1');
      expect(
        cardio.single.cachedAt.millisecondsSinceEpoch,
        newCachedAt.millisecondsSinceEpoch,
      );
    },
  );

  test('6.1-LOCAL-008: replaceCache with empty list clears cache', () async {
    final cachedAt = DateTime.utc(2026, 5, 14, 9);

    await sut.cacheExercises([mobilityExercise, cardioExercise], cachedAt);

    await sut.replaceCache(const [], DateTime.utc(2026, 5, 15, 9));

    expect(await db.exerciseCacheDao.getAll(), isEmpty);
  });

  test(
    '6.1-LOCAL-009: replaceCache wraps DAO failures in CacheException',
    () async {
      final throwingSut = ExerciseLocalDataSource(
        _ThrowingExerciseCacheDao(throwOnDelete: true),
      );

      expect(
        () => throwingSut.replaceCache([
          mobilityExercise,
        ], DateTime.utc(2026, 5, 14, 9)),
        throwsA(
          isA<CacheException>().having(
            (exception) => exception.message,
            'message',
            contains('Failed to replace exercise cache'),
          ),
        ),
      );
    },
  );

  test(
    '6.1-UNIT-003: loadFallbackExercisesByType loads bundled fallback asset',
    () async {
      final exercises = await sut.loadFallbackExercisesByType('breathing');

      expect(exercises, isNotEmpty);
      expect(exercises.first.sessionType, 'breathing');
      expect(exercises.first.steps, isNotEmpty);
    },
  );

  test(
    '6.2-UNIT-001: bundled fallback catalog satisfies data integrity contract',
    () async {
      final exercises = [
        ...await sut.loadFallbackExercisesByType('mobility'),
        ...await sut.loadFallbackExercisesByType('cardio'),
        ...await sut.loadFallbackExercisesByType('breathing'),
      ];
      final countsByType = <String, int>{};
      final ids = <String>{};
      const supportedTypes = {'mobility', 'cardio', 'breathing'};
      const supportedDifficulties = {'low', 'medium', 'high'};

      for (final exercise in exercises) {
        countsByType.update(
          exercise.sessionType,
          (count) => count + 1,
          ifAbsent: () => 1,
        );

        expect(
          exercise.id,
          startsWith('fallback_'),
          reason: '${exercise.id} must use the fallback_ prefix',
        );
        expect(
          exercise.id.trim(),
          isNotEmpty,
          reason: '${exercise.id} id must be non-empty after trim',
        );
        expect(
          exercise.name.trim(),
          isNotEmpty,
          reason: '${exercise.id} name must be non-empty after trim',
        );
        expect(
          exercise.description.trim(),
          isNotEmpty,
          reason: '${exercise.id} description must be non-empty after trim',
        );
        expect(
          ids.add(exercise.id),
          isTrue,
          reason: '${exercise.id} must be unique',
        );
        expect(
          supportedTypes,
          contains(exercise.sessionType),
          reason: '${exercise.id} has unsupported sessionType',
        );
        expect(
          supportedDifficulties,
          contains(exercise.difficulty),
          reason: '${exercise.id} has unsupported difficulty',
        );
        expect(
          exercise.steps.where((step) => step.trim().isNotEmpty),
          hasLength(greaterThanOrEqualTo(3)),
          reason: '${exercise.id} must have at least 3 non-empty steps',
        );
        expect(
          exercise.durationMinutes,
          inInclusiveRange(2, 10),
          reason: '${exercise.id} duration must stay in the product range',
        );
        expect(
          exercise.indoorCompatible,
          isTrue,
          reason: '${exercise.id} must always be indoor compatible',
        );
        expect(
          exercise.outdoorCompatible,
          isTrue,
          reason:
              '${exercise.id} bundled fallback must work anywhere offline; '
              'set outdoorCompatible: true or relax this assertion intentionally',
        );
      }

      expect(exercises, hasLength(greaterThanOrEqualTo(30)));
      expect(countsByType['mobility'], greaterThanOrEqualTo(10));
      expect(countsByType['cardio'], greaterThanOrEqualTo(10));
      expect(countsByType['breathing'], greaterThanOrEqualTo(10));
    },
  );

  test(
    '6.5-UNIT-001: loadFallbackExercisesByType normalizes uppercase sessionType',
    () async {
      final upper = await sut.loadFallbackExercisesByType('BREATHING');
      final lower = await sut.loadFallbackExercisesByType('breathing');

      expect(upper, hasLength(lower.length));
      expect(upper, isNotEmpty);
    },
  );

  test(
    '6.5-UNIT-002: loadFallbackExercisesByType normalizes sessionType with trailing space',
    () async {
      final spaced = await sut.loadFallbackExercisesByType('breathing ');
      final normal = await sut.loadFallbackExercisesByType('breathing');

      expect(spaced, hasLength(normal.length));
      expect(spaced, isNotEmpty);
    },
  );

  test(
    '6.5-UNIT-003: getCachedExercisesByType normalizes uppercase sessionType',
    () async {
      final cachedAt = DateTime.utc(2026, 5, 14, 9);
      const exercise = Exercise(
        id: 'mobility-norm-test',
        name: 'Norm Test',
        description: 'Test.',
        sessionType: 'mobility',
        steps: ['Step'],
        durationMinutes: 5,
        difficulty: 'low',
        indoorCompatible: true,
        outdoorCompatible: true,
      );
      await sut.cacheExercises([exercise], cachedAt);

      final upper = await sut.getCachedExercisesByType('MOBILITY');

      expect(upper, hasLength(1));
      expect(upper.first.exercise.id, 'mobility-norm-test');
    },
  );

  test(
    '6.5-UNIT-004: loadFallbackExercisesByType deduplicates records by id',
    () async {
      const assetKey = 'assets/data/fallback_exercises.json';
      const dupeJson = '''
[
  {
    "id": "fallback_dup",
    "name": "First",
    "description": "d",
    "sessionType": "breathing",
    "steps": ["a", "b", "c"],
    "durationMinutes": 5,
    "difficulty": "low",
    "indoorCompatible": true,
    "outdoorCompatible": true
  },
  {
    "id": "fallback_dup",
    "name": "Second",
    "description": "d",
    "sessionType": "breathing",
    "steps": ["a", "b", "c"],
    "durationMinutes": 5,
    "difficulty": "low",
    "indoorCompatible": true,
    "outdoorCompatible": true
  }
]
''';

      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      rootBundle.evict(assetKey);
      binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
        ByteData? message,
      ) async {
        return ByteData.view(Uint8List.fromList(utf8.encode(dupeJson)).buffer);
      });
      addTearDown(() {
        binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/assets',
          null,
        );
        rootBundle.evict(assetKey);
      });

      final result = await sut.loadFallbackExercisesByType('breathing');

      expect(result, hasLength(1));
      expect(result.first.name, 'First');
    },
  );

  test(
    '6.5-UNIT-005: loadFallbackExercisesByType returns empty for blank sessionType',
    () async {
      final result = await sut.loadFallbackExercisesByType('   ');

      expect(result, isEmpty);
    },
  );

  test(
    '6.5-UNIT-006: getCachedExercisesByType returns empty for blank sessionType',
    () async {
      final cachedAt = DateTime.utc(2026, 5, 14, 9);
      const exercise = Exercise(
        id: 'blank-session-type-guard',
        name: 'Blank Guard',
        description: 'Test.',
        sessionType: 'mobility',
        steps: ['Step'],
        durationMinutes: 5,
        difficulty: 'low',
        indoorCompatible: true,
        outdoorCompatible: true,
      );
      await sut.cacheExercises([exercise], cachedAt);

      final result = await sut.getCachedExercisesByType(' ');

      expect(result, isEmpty);
    },
  );
}
