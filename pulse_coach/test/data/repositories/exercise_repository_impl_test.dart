import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_local_data_source.dart';
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_remote_data_source.dart';
import 'package:pulse_coach/features/sessions_catalog/data/models/exercise_model.dart';
import 'package:pulse_coach/features/sessions_catalog/data/repositories/exercise_repository_impl.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';

import 'exercise_repository_impl_test.mocks.dart';

@GenerateMocks([ExerciseRemoteDataSource, ExerciseLocalDataSource])
void main() {
  late MockExerciseRemoteDataSource mockRemote;
  late MockExerciseLocalDataSource mockLocal;
  late ExerciseRepositoryImpl sut;

  const cachedExercise = Exercise(
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

  final freshCachedEntry = CachedExerciseEntry(
    exercise: cachedExercise,
    cachedAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
  );
  final staleCachedEntry = CachedExerciseEntry(
    exercise: cachedExercise,
    cachedAt: DateTime.now().toUtc().subtract(const Duration(hours: 25)),
  );

  const remoteModel = ExerciseModel(
    id: 'mobility-2',
    name: 'Hip Stretch',
    description: 'Mobility work.',
    sessionType: 'mobility',
    steps: ['Stretch gently'],
    durationMinutes: 5,
    difficulty: 'low',
    indoorCompatible: true,
    outdoorCompatible: true,
  );

  const replacementRemoteModel = ExerciseModel(
    id: 'mobility-2',
    name: 'Hip Stretch Updated',
    description: 'Updated mobility work.',
    sessionType: 'mobility',
    steps: ['Stretch gently', 'Breathe'],
    durationMinutes: 6,
    difficulty: 'medium',
    indoorCompatible: true,
    outdoorCompatible: true,
  );

  const fallbackExercise = Exercise(
    id: 'fallback-breathing-1',
    name: 'Box Breathing',
    description: 'Breathing drill.',
    sessionType: 'breathing',
    steps: ['Inhale', 'Hold', 'Exhale'],
    durationMinutes: 4,
    difficulty: 'low',
    indoorCompatible: true,
    outdoorCompatible: true,
  );

  List<Exercise> fallbackExercisesFor(String sessionType) => List.generate(
    10,
    (index) => Exercise(
      id: 'fallback_${sessionType}_$index',
      name: '$sessionType fallback $index',
      description: 'Fallback exercise.',
      sessionType: sessionType,
      steps: const ['Prepare', 'Move with control', 'Finish calmly'],
      durationMinutes: 4,
      difficulty: 'low',
      indoorCompatible: true,
      outdoorCompatible: true,
    ),
  );

  setUp(() {
    mockRemote = MockExerciseRemoteDataSource();
    mockLocal = MockExerciseLocalDataSource();
    sut = ExerciseRepositoryImpl(mockRemote, mockLocal);
  });

  test(
    '6.1-UNIT-007: fresh cache hit returns cache and skips remote',
    () async {
      when(
        mockLocal.getCachedExercisesByType('mobility'),
      ).thenAnswer((_) async => [freshCachedEntry]);

      final result = await sut.getExercisesByType('mobility');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (exercises) {
        expect(exercises, hasLength(1));
        expect(exercises.single.id, 'mobility-1');
        expect(exercises.single, equals(cachedExercise));
      });
      verifyNever(mockRemote.fetchExercisesByType(any));
      verifyNever(mockRemote.fetchAll());
    },
  );

  test(
    '6.1-UNIT-008: stale cache plus remote success returns fresh data and writes cache',
    () async {
      when(
        mockLocal.getCachedExercisesByType('mobility'),
      ).thenAnswer((_) async => [staleCachedEntry]);
      when(
        mockRemote.fetchExercisesByType('mobility'),
      ).thenAnswer((_) async => [remoteModel]);
      when(mockLocal.cacheExercises(any, any)).thenAnswer((_) async {});

      final result = await sut.getExercisesByType('mobility');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (exercises) {
        expect(exercises.single.id, 'mobility-2');
      });
      verify(mockLocal.cacheExercises(any, any)).called(1);
    },
  );

  test(
    '6.1-UNIT-009: remote failure plus stale cache returns stale cache',
    () async {
      when(
        mockLocal.getCachedExercisesByType('mobility'),
      ).thenAnswer((_) async => [staleCachedEntry]);
      when(
        mockRemote.fetchExercisesByType('mobility'),
      ).thenThrow(const ServerException('timeout'));

      final result = await sut.getExercisesByType('mobility');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (exercises) {
        expect(exercises.single.id, 'mobility-1');
      });
    },
  );

  test(
    '6.1-UNIT-010: remote failure plus empty cache loads fallback',
    () async {
      when(
        mockLocal.getCachedExercisesByType('breathing'),
      ).thenAnswer((_) async => const []);
      when(
        mockRemote.fetchExercisesByType('breathing'),
      ).thenThrow(const ServerException('timeout'));
      when(
        mockLocal.loadFallbackExercisesByType('breathing'),
      ).thenAnswer((_) async => [fallbackExercise]);

      final result = await sut.getExercisesByType('breathing');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (exercises) {
        expect(exercises.single.id, 'fallback-breathing-1');
      });
    },
  );

  test(
    '6.2-UNIT-002: remote failure plus empty cache returns category-sized fallback lists',
    () async {
      for (final sessionType in ['mobility', 'cardio', 'breathing']) {
        final fallback = fallbackExercisesFor(sessionType);
        when(
          mockLocal.getCachedExercisesByType(sessionType),
        ).thenAnswer((_) async => const []);
        when(
          mockRemote.fetchExercisesByType(sessionType),
        ).thenThrow(const ServerException('timeout'));
        when(
          mockLocal.loadFallbackExercisesByType(sessionType),
        ).thenAnswer((_) async => fallback);

        final result = await sut.getExercisesByType(sessionType);

        expect(result.isRight(), isTrue, reason: sessionType);
        result.fold((_) => fail('Expected Right for $sessionType'), (
          exercises,
        ) {
          expect(exercises, hasLength(10), reason: sessionType);
          expect(
            exercises.every((exercise) => exercise.sessionType == sessionType),
            isTrue,
            reason: sessionType,
          );
          expect(
            exercises.every((exercise) => exercise.indoorCompatible),
            isTrue,
            reason: sessionType,
          );
        });

        verify(mockLocal.loadFallbackExercisesByType(sessionType)).called(1);
        verifyNever(mockLocal.cacheExercises(any, any));
      }
    },
  );

  test(
    '6.1-UNIT-012: cache read failure falls through to remote fetch',
    () async {
      when(
        mockLocal.getCachedExercisesByType('mobility'),
      ).thenThrow(const CacheException('cache unavailable'));
      when(
        mockRemote.fetchExercisesByType('mobility'),
      ).thenAnswer((_) async => [remoteModel]);
      when(mockLocal.cacheExercises(any, any)).thenAnswer((_) async {});

      final result = await sut.getExercisesByType('mobility');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (exercises) {
        expect(exercises.single.id, 'mobility-2');
      });
      verify(mockRemote.fetchExercisesByType('mobility')).called(1);
      verify(mockLocal.cacheExercises(any, any)).called(1);
    },
  );

  test(
    '6.1-UNIT-013: cache write failure still returns fresh remote data',
    () async {
      when(
        mockLocal.getCachedExercisesByType('mobility'),
      ).thenAnswer((_) async => const []);
      when(
        mockRemote.fetchExercisesByType('mobility'),
      ).thenAnswer((_) async => [remoteModel]);
      when(
        mockLocal.cacheExercises(any, any),
      ).thenThrow(const CacheException('disk full'));

      final result = await sut.getExercisesByType('mobility');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (exercises) {
        expect(exercises.single.id, 'mobility-2');
      });
      verify(mockLocal.cacheExercises(any, any)).called(1);
    },
  );

  test(
    '6.1-UNIT-014: remote empty response with stale cache returns stale cache',
    () async {
      when(
        mockLocal.getCachedExercisesByType('mobility'),
      ).thenAnswer((_) async => [staleCachedEntry]);
      when(
        mockRemote.fetchExercisesByType('mobility'),
      ).thenAnswer((_) async => const []);

      final result = await sut.getExercisesByType('mobility');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (exercises) {
        expect(exercises.single, cachedExercise);
      });
      verifyNever(mockLocal.loadFallbackExercisesByType(any));
      verifyNever(mockLocal.cacheExercises(any, any));
    },
  );

  test(
    '6.1-UNIT-011: missing fallback with no cache returns Left(CacheFailure)',
    () async {
      when(
        mockLocal.getCachedExercisesByType('breathing'),
      ).thenAnswer((_) async => const []);
      when(
        mockRemote.fetchExercisesByType('breathing'),
      ).thenThrow(const ServerException('timeout'));
      when(
        mockLocal.loadFallbackExercisesByType('breathing'),
      ).thenThrow(const CacheException('missing asset'));

      final result = await sut.getExercisesByType('breathing');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
    },
  );

  test(
    '6.1-SYNC-001: syncCatalog fetches all, dedupes by id, and replaces cache',
    () async {
      when(
        mockRemote.fetchAll(),
      ).thenAnswer((_) async => [remoteModel, replacementRemoteModel]);
      when(mockLocal.replaceCache(any, any)).thenAnswer((_) async {});

      final result = await sut.syncCatalog();

      expect(result.isRight(), isTrue);
      final capturedExercises =
          verify(mockLocal.replaceCache(captureAny, any)).captured.single
              as List<Exercise>;
      expect(capturedExercises, hasLength(1));
      expect(capturedExercises.single.id, 'mobility-2');
      expect(capturedExercises.single.name, 'Hip Stretch Updated');
    },
  );

  test(
    '6.1-SYNC-002: syncCatalog returns ServerFailure when remote has no mappable exercises',
    () async {
      when(mockRemote.fetchAll()).thenAnswer((_) async => const []);

      final result = await sut.syncCatalog();

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'ExerciseDB returned no mappable exercises');
      }, (_) => fail('Expected Left'));
      verifyNever(mockLocal.replaceCache(any, any));
    },
  );

  test(
    '6.1-SYNC-003: syncCatalog maps ServerException to ServerFailure',
    () async {
      when(
        mockRemote.fetchAll(),
      ).thenThrow(const ServerException('remote down'));

      final result = await sut.syncCatalog();

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'remote down');
      }, (_) => fail('Expected Left'));
      verifyNever(mockLocal.replaceCache(any, any));
    },
  );

  test(
    '6.1-SYNC-004: syncCatalog maps replaceCache CacheException to CacheFailure',
    () async {
      when(mockRemote.fetchAll()).thenAnswer((_) async => [remoteModel]);
      when(
        mockLocal.replaceCache(any, any),
      ).thenThrow(const CacheException('write failed'));

      final result = await sut.syncCatalog();

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<CacheFailure>());
        expect(failure.message, 'write failed');
      }, (_) => fail('Expected Left'));
    },
  );
}
