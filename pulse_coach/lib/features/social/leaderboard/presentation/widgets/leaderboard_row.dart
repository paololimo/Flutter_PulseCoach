import 'package:flutter/material.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/widgets/medal_colors.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  const LeaderboardRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = medalColor(entry.rank);
    final icon = medalIcon(entry.rank);

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
            // Cue 1: rank number — always shown, primary cue.
            SizedBox(
              width: 32,
              child: Text('${entry.rank}°', style: theme.textTheme.titleMedium),
            ),
            // Cue 2: shape-distinct glyph (top 3 only).
            if (icon != null) ...[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                '@${entry.displayHandle}',
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.visible, // UX-DR33: wraps, never truncates
              ),
            ),
            // Cue 3: text label (top 3 only) — never color alone.
            if (entry.rank <= 3)
              Text(_medalLabel(entry.rank, l10n), style: theme.textTheme.bodySmall)
            else
              Text(
                l10n.leaderboardPoints(entry.totalPoints),
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  String _medalLabel(int rank, AppLocalizations l10n) => switch (rank) {
    1 => l10n.leaderboardMedalGold,
    2 => l10n.leaderboardMedalSilver,
    3 => l10n.leaderboardMedalBronze,
    _ => '',
  };
}
