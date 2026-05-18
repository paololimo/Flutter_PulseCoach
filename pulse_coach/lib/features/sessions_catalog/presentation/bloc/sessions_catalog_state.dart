import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

part 'sessions_catalog_state.freezed.dart';

enum SessionsCatalogCategory { all, mobility, cardio, breathing }

const sessionsCatalogDisplayCategories = <SessionsCatalogCategory>[
  SessionsCatalogCategory.mobility,
  SessionsCatalogCategory.cardio,
  SessionsCatalogCategory.breathing,
];

extension SessionsCatalogCategoryX on SessionsCatalogCategory {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    SessionsCatalogCategory.all => l10n.catalogCategoryAll,
    SessionsCatalogCategory.mobility => l10n.sessionNameMobility,
    SessionsCatalogCategory.cardio => l10n.sessionNameCardio,
    SessionsCatalogCategory.breathing => l10n.sessionNameBreathing,
  };

  String? get sessionType => switch (this) {
    SessionsCatalogCategory.all => null,
    SessionsCatalogCategory.mobility => 'mobility',
    SessionsCatalogCategory.cardio => 'cardio',
    SessionsCatalogCategory.breathing => 'breathing',
  };
}

@freezed
sealed class SessionsCatalogState with _$SessionsCatalogState {
  const factory SessionsCatalogState.initial() = SessionsCatalogInitial;
  const factory SessionsCatalogState.loading() = SessionsCatalogLoading;
  const factory SessionsCatalogState.loaded({
    required SessionsCatalogCategory selectedCategory,
    required Map<SessionsCatalogCategory, List<Exercise>> groupedExercises,
    @Default(<SessionsCatalogCategory, Failure>{})
    Map<SessionsCatalogCategory, Failure> degradedCategories,
  }) = SessionsCatalogLoaded;
  const factory SessionsCatalogState.error({required Failure failure}) =
      SessionsCatalogError;
}
