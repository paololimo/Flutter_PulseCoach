import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class SessionCatalogDetailSheet extends StatelessWidget {
  const SessionCatalogDetailSheet({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulseTheme = theme.extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final category = _categoryFor(exercise.sessionType);
    final intensity = _intensityLabel(l10n, exercise.difficulty);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: pulseTheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.sessionDetailClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetadataPill(
                    label: category.localizedLabel(l10n),
                  ),
                  _MetadataPill(label: '${exercise.durationMinutes} min'),
                  _MetadataPill(label: intensity),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                exercise.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: pulseTheme.onSurface,
                ),
              ),
              if (exercise.steps.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.sessionDetailSteps,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: pulseTheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final MapEntry(:key, :value)
                    in exercise.steps.asMap().entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${key + 1}. $value',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: pulseTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulseTheme = theme.extension<PulseCoachTheme>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: pulseTheme.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: pulseTheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _intensityLabel(AppLocalizations l10n, String difficulty) {
  return switch (difficulty.toLowerCase()) {
    'low' => l10n.intensityLow,
    'medium' => l10n.intensityMedium,
    'high' => l10n.intensityHigh,
    _ => l10n.intensityMedium,
  };
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
