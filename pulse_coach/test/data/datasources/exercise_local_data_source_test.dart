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
}
