import 'package:flutter/material.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class WeeklyGoalIndicator extends StatelessWidget {
  const WeeklyGoalIndicator({
    super.key,
    required this.completedThisWeek,
    required this.weeklyTarget,
  });

  final int completedThisWeek;
  final int weeklyTarget;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final progress = weeklyTarget > 0
        ? (completedThisWeek / weeklyTarget).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = completedThisWeek >= weeklyTarget;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weeklyGoalProgress(completedThisWeek, weeklyTarget),
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            color: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainerHighest,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          if (completedThisWeek == 0) ...[
            const SizedBox(height: 6),
            Text(
              l10n.weeklyGoalFirstSession,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (isComplete) ...[
            const SizedBox(height: 6),
            Text(
              l10n.weeklyGoalReached,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
