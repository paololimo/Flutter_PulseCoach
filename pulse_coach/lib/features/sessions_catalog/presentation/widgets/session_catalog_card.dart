import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class SessionCatalogCard extends StatelessWidget {
  const SessionCatalogCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.selected = false,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  /// Highlights the card as the active row in the tablet master-detail pane.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulseTheme = theme.extension<PulseCoachTheme>()!;
    final category = _categoryFor(exercise.sessionType);

    return Semantics(
      button: true,
      selected: selected,
      label: '${exercise.name}, ${exercise.durationMinutes} minutes',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: selected
            ? pulseTheme.surfaceContainerHigh
            : pulseTheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: selected
              ? BorderSide(color: pulseTheme.primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _TypeChip(
                            label: category.localizedLabel(
                              AppLocalizations.of(context)!,
                            ),
                          ),
                          _DifficultyDots(difficulty: exercise.difficulty),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        exercise.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: pulseTheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${exercise.durationMinutes} min',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: pulseTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: pulseTheme.onSurfaceVariant,
                  semanticLabel: 'Open details',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulseTheme = theme.extension<PulseCoachTheme>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: pulseTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: pulseTheme.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final activeCount = switch (difficulty.toLowerCase()) {
      'high' => 3,
      'medium' => 2,
      'low' => 1,
      _ => 0,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Icon(
            Icons.circle,
            size: 8,
            color: index < activeCount
                ? pulseTheme.tertiary
                : pulseTheme.onSurfaceVariant.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}

SessionsCatalogCategory _categoryFor(String sessionType) {
  return switch (sessionType) {
    'mobility' => SessionsCatalogCategory.mobility,
    'cardio' => SessionsCatalogCategory.cardio,
    'breathing' => SessionsCatalogCategory.breathing,
    _ => throw ArgumentError.value(
      sessionType,
      'sessionType',
      'Unsupported session type reached presentation layer; '
          'SessionsCatalogCubit must filter these out.',
    ),
  };
}
