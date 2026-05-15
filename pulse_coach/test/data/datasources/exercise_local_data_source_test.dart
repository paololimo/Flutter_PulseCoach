import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_local_data_source.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';

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

  test(
    '6.1-UNIT-002: cacheExercises + getCachedExercisesByType preserves rows and cachedAt',
    () async {
      final cachedAt = DateTime.utc(2026, 5, 14, 9);
      const exercises = [
        Exercise(
          id: 'mobility-1',
          name: 'Neck Rolls',
          description: 'Mobility work.',
          sessionType: 'mobility',
          steps: ['Move slowly'],
          durationMinutes: 4,
          difficulty: 'low',
          indoorCompatible: true,
          outdoorCompatible: true,
        ),
        Exercise(
          id: 'cardio-1',
          name: 'March In Place',
          description: 'Cardio work.',
          sessionType: 'cardio',
          steps: ['March quickly'],
          durationMinutes: 7,
          difficulty: 'medium',
          indoorCompatible: true,
          outdoorCompatible: true,
        ),
      ];

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
}
