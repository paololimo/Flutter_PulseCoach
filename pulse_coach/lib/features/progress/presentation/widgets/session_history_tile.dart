import 'package:flutter/material.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

class SessionHistoryTile extends StatelessWidget {
  const SessionHistoryTile({super.key, required this.entry});

  final SessionHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAbandoned = entry.abandoned;

    return Opacity(
      opacity: isAbandoned ? 0.45 : 1.0,
      child: ListTile(
        leading: _SessionTypeIcon(sessionType: entry.sessionType),
        title: Text(
          _sessionLabel(entry.sessionType),
          style: textTheme.bodyLarge,
        ),
        subtitle: Text(
          _subtitleText(entry),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: _RpeBadge(rpeValue: entry.rpeValue),
      ),
    );
  }

  String _sessionLabel(String sessionType) => switch (sessionType) {
    'mobility' => 'Mobilità',
    'cardio' => 'Cardio',
    'breathing' => 'Respirazione',
    _ => sessionType,
  };

  String _subtitleText(SessionHistoryEntry entry) {
    final date = _formatDate(entry.completedAt);
    if (entry.abandoned) {
      // Always mark abandoned sessions, even when no elapsed time was recorded.
      // Sub-minute elapsed renders as "<1min" so a brief-but-real session is
      // never displayed as "0min".
      final elapsed = entry.elapsedSeconds;
      final elapsedLabel = elapsed == null
          ? ''
          : elapsed < 60
          ? '<1min '
          : '${elapsed ~/ 60}min ';
      return '$date · $elapsedLabel(abbandonata)';
    }
    return '$date · ${entry.durationMinutes}min';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

class _SessionTypeIcon extends StatelessWidget {
  const _SessionTypeIcon({required this.sessionType});

  final String sessionType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconData = switch (sessionType) {
      'mobility' => Icons.self_improvement,
      'cardio' => Icons.directions_run,
      'breathing' => Icons.air,
      _ => Icons.fitness_center,
    };
    return CircleAvatar(
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(iconData, color: colorScheme.onPrimaryContainer, size: 20),
    );
  }
}

class _RpeBadge extends StatelessWidget {
  const _RpeBadge({required this.rpeValue});

  final int? rpeValue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    if (rpeValue == null) {
      return Text(
        '—',
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'RPE $rpeValue',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
