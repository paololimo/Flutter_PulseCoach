import 'package:flutter/material.dart';
import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class ComparisonRow extends StatelessWidget {
  final ProgressComparisonEntry entry;

  // FR12: always 3 — the AI session-count cap
  static const int weeklyTarget = 3;

  const ComparisonRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Own entry gets subtle surfaceContainerHigh; friends get standard surfaceContainer
    final backgroundColor = entry.isOwn
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainer;

    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '@${entry.displayHandle}',
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.visible, // UX-DR33: wraps, never truncates
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.comparisonSessions(
                      entry.sessionsThisWeek, weeklyTarget),
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  l10n.comparisonMinutes(entry.minutesThisWeek),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
