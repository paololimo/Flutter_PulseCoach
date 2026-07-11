import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

/// Modal wrapper used on phone layouts: shows the detail body inside a bottom
/// sheet and closes by popping the navigator.
class SessionCatalogDetailSheet extends StatelessWidget {
  const SessionCatalogDetailSheet({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return SessionCatalogDetailBody(
      exercise: exercise,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}

/// Exercise detail content. Rendered inside a modal bottom sheet on phones and
/// as the persistent right-hand pane of the tablet master-detail layout.
///
/// When [onClose] is null the close button is hidden — the pane has nothing to
/// dismiss, it just reflects the current selection.
class SessionCatalogDetailBody extends StatelessWidget {
  const SessionCatalogDetailBody({
    super.key,
    required this.exercise,
    this.onClose,
  });

  final Exercise exercise;
  final VoidCallback? onClose;

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
                  if (onClose != null)
                    IconButton(
                      tooltip: l10n.sessionDetailClose,
                      onPressed: onClose,
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

/// Empty-state shown in the tablet detail pane before any session is picked.
class SessionCatalogDetailPlaceholder extends StatelessWidget {
  const SessionCatalogDetailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulseTheme = theme.extension<PulseCoachTheme>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: pulseTheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.sessionDetailEmptyPane,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: pulseTheme.onSurfaceVariant,
              ),
            ),
          ],
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
