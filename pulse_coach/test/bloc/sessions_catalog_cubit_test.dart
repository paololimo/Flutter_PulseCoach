import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart';

import 'sessions_catalog_cubit_test.mocks.dart';

@GenerateMocks([GetExercisesByType])
void main() {
  late MockGetExercisesByType mockGetExercisesByType;

  const mobility = Exercise(
    id: 'mobility-1',
    name: 'Hip Reset',
    description: 'Open hips and restore range.',
    sessionType: 'mobility',
    steps: ['Breathe', 'Lunge', 'Rotate'],
    durationMinutes: 8,
    difficulty: 'low',
    indoorCompatible: true,
    outdoorCompatible: true,
  );

  const cardio = Exercise(
    id: 'cardio-1',
    name: 'Tempo Walk',
    description: 'A brisk walk with short pickups.',
    sessionType: 'cardio',
    steps: ['Warm up', 'Pick up pace', 'Cool down'],
    durationMinutes: 12,
    difficulty: 'medium',
    indoorCompatible: false,
    outdoorCompatible: true,
  );

  const breathing = Exercise(
    id: 'breathing-1',
    name: 'Box Breathing',
    description: 'Settle your breathing rhythm.',
    sessionType: 'breathing',
    steps: ['Inhale', 'Hold', 'Exhale', 'Hold'],
    durationMinutes: 5,
    difficulty: 'low',
    indoorCompatible: true,
    outdoorCompatible: true,
  );

  const failure = CacheFailure('cache unavailable');

  setUp(() {
    mockGetExercisesByType = MockGetExercisesByType();
  });

  SessionsCatalogCubit buildCubit() =>
      SessionsCatalogCubit(mockGetExercisesByType);

  void stubSuccesses({
    List<Exercise> mobilityExercises = const [mobility],
    List<Exercise> cardioExercises = const [cardio],
    List<Exercise> breathingExercises = const [breathing],
  }) {
    when(
      mockGetExercisesByType.call('mobility'),
    ).thenAnswer((_) async => Right(mobilityExercises));
    when(
      mockGetExercisesByType.call('cardio'),
    ).thenAnswer((_) async => Right(cardioExercises));
    when(
      mockGetExercisesByType.call('breathing'),
    ).thenAnswer((_) async => Right(breathingExercises));
  }

  group('SessionsCatalogCubit', () {
    test('6.3-UNIT-001: initial state is initial', () {
      expect(buildCubit().state, const SessionsCatalogState.initial());
    });

    blocTest<SessionsCatalogCubit, SessionsCatalogState>(
      '6.3-UNIT-002: loadCatalog emits loading then loaded grouped by fixed order',
      build: () {
        stubSuccesses();
        return buildCubit();
      },
      act: (cubit) => cubit.loadCatalog(),
      expect: () => [
        const SessionsCatalogState.loading(),
        const SessionsCatalogState.loaded(
          selectedCategory: SessionsCatalogCategory.all,
          groupedExercises: {
            SessionsCatalogCategory.mobility: [mobility],
            SessionsCatalogCategory.cardio: [cardio],
            SessionsCatalogCategory.breathing: [breathing],
          },
        ),
      ],
      verify: (_) {
        verifyInOrder([
          mockGetExercisesByType.call('mobility'),
          mockGetExercisesByType.call('cardio'),
          mockGetExercisesByType.call('breathing'),
        ]);
      },
    );

    blocTest<SessionsCatalogCubit, SessionsCatalogState>(
      '6.3-UNIT-003: selectCategory filters visible exercises without mutating grouped data',
      build: () {
        stubSuccesses();
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadCatalog();
        cubit.selectCategory(SessionsCatalogCategory.cardio);
      },
      expect: () => [
        const SessionsCatalogState.loading(),
        const SessionsCatalogState.loaded(
          selectedCategory: SessionsCatalogCategory.all,
          groupedExercises: {
            SessionsCatalogCategory.mobility: [mobility],
            SessionsCatalogCategory.cardio: [cardio],
            SessionsCatalogCategory.breathing: [breathing],
          },
        ),
        const SessionsCatalogState.loaded(
          selectedCategory: SessionsCatalogCategory.cardio,
          groupedExercises: {
            SessionsCatalogCategory.mobility: [mobility],
            SessionsCatalogCategory.cardio: [cardio],
            SessionsCatalogCategory.breathing: [breathing],
          },
        ),
      ],
    );

    blocTest<SessionsCatalogCubit, SessionsCatalogState>(
      '6.3-UNIT-004: one category failure degrades only that category',
      build: () {
        when(
          mockGetExercisesByType.call('mobility'),
        ).thenAnswer((_) async => const Right([mobility]));
        when(
          mockGetExercisesByType.call('cardio'),
        ).thenAnswer((_) async => const Left(failure));
        when(
          mockGetExercisesByType.call('breathing'),
        ).thenAnswer((_) async => const Right([breathing]));
        return buildCubit();
      },
      act: (cubit) => cubit.loadCatalog(),
      expect: () => [
        const SessionsCatalogState.loading(),
        const SessionsCatalogState.loaded(
          selectedCategory: SessionsCatalogCategory.all,
          groupedExercises: {
            SessionsCatalogCategory.mobility: [mobility],
            SessionsCatalogCategory.cardio: [],
            SessionsCatalogCategory.breathing: [breathing],
          },
          degradedCategories: {SessionsCatalogCategory.cardio: failure},
        ),
      ],
    );

    blocTest<SessionsCatalogCubit, SessionsCatalogState>(
      '6.3-UNIT-005: all category failures emit error',
      build: () {
        when(
          mockGetExercisesByType.call(any),
        ).thenAnswer((_) async => const Left(failure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadCatalog(),
      expect: () => [
        const SessionsCatalogState.loading(),
        const SessionsCatalogState.error(failure: failure),
      ],
    );
  });
}
