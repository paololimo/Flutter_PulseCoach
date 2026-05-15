import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';

class CompletedSessionCard extends StatelessWidget {
  final PlannedSession session;

  const CompletedSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final pulseThemeOrNull = Theme.of(context).extension<PulseCoachTheme>();
    assert(
      pulseThemeOrNull != null,
      'CompletedSessionCard requires PulseCoachTheme extension',
    );
    final pulseTheme = pulseThemeOrNull!;
    final displayName = sessionDisplayName(session.sessionType);
    final durationLabel = '${session.durationMinutes} min';

    return Semantics(
      label: 'Completata: $displayName, $durationLabel.',
      excludeSemantics: false,
      child: Container(
        decoration: BoxDecoration(
          color: pulseTheme.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 24,
                color: pulseTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                durationLabel,
                style: AppTextStyles.bodySmall.copyWith(
                  color: pulseTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
