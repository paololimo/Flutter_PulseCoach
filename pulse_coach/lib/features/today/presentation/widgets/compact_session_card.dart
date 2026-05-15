import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';

class CompactSessionCard extends StatelessWidget {
  final PlannedSession session;
  final VoidCallback? onTap;

  const CompactSessionCard({super.key, required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pulseThemeOrNull = Theme.of(context).extension<PulseCoachTheme>();
    assert(
      pulseThemeOrNull != null,
      'CompactSessionCard requires PulseCoachTheme extension',
    );
    final pulseTheme = pulseThemeOrNull!;

    final accentColor = sessionAccentColor(session.sessionType, pulseTheme);
    final displayName = sessionDisplayName(session.sessionType);
    final durationLabel = '${session.durationMinutes} min';
    final canTap = onTap != null;
    final radius = BorderRadius.circular(16);

    return Semantics(
      label:
          'Sessione successiva: $displayName, $durationLabel. '
          'Tocca per selezionare come prossima sessione.',
      button: canTap,
      onTap: onTap,
      child: Material(
        color: pulseTheme.surfaceContainer,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    sessionIcon(session.sessionType),
                    size: 24,
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    durationLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: pulseTheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
