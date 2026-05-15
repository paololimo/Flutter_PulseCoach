import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart';

@lazySingleton
class SessionsCatalogCubit extends Cubit<SessionsCatalogState> {
  SessionsCatalogCubit(this._getExercisesByType)
    : super(const SessionsCatalogState.initial());

  final GetExercisesByType _getExercisesByType;

  Future<void> loadCatalog() async {
    emit(const SessionsCatalogState.loading());

    final grouped = <SessionsCatalogCategory, List<Exercise>>{
      for (final category in sessionsCatalogDisplayCategories) category: [],
    };
    final degraded = <SessionsCatalogCategory, Failure>{};

    for (final category in sessionsCatalogDisplayCategories) {
      if (isClosed) return;
      final sessionType = category.sessionType;
      if (sessionType == null) continue;

      final result = await _getExercisesByType.call(sessionType);
      result.fold(
        (failure) => degraded[category] = failure,
        (exercises) => grouped[category] = exercises
            .where((exercise) => exercise.sessionType == sessionType)
            .toList(growable: false),
      );
    }

    if (isClosed) return;

    final everyCategoryFailed =
        degraded.length == sessionsCatalogDisplayCategories.length;
    if (everyCategoryFailed) {
      final failure = degraded.values.first;
      emit(SessionsCatalogState.error(failure: failure));
      return;
    }

    emit(
      SessionsCatalogState.loaded(
        selectedCategory: SessionsCatalogCategory.all,
        groupedExercises: grouped,
        degradedCategories: degraded,
      ),
    );
  }

  void selectCategory(SessionsCatalogCategory category) {
    final current = state;
    if (current is! SessionsCatalogLoaded) return;

    emit(current.copyWith(selectedCategory: category));
  }
}
