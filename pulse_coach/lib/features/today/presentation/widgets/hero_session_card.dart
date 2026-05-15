import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';

class HeroSessionCard extends StatelessWidget {
  final PlannedSession session;
  final VoidCallback? onStart;

  const HeroSessionCard({super.key, required this.session, this.onStart});

  @override
  Widget build(BuildContext context) {
    final pulseThemeOrNull = Theme.of(context).extension<PulseCoachTheme>();
    assert(
      pulseThemeOrNull != null,
      'HeroSessionCard requires PulseCoachTheme extension',
    );
    final pulseTheme = pulseThemeOrNull!;

    final accentColor = sessionAccentColor(session.sessionType, pulseTheme);
    final displayName = sessionDisplayName(session.sessionType);
    final durationLabel = '${session.durationMinutes} min';
    final intensityText = intensityLabel(session.intensity);
    final hasExplanation = session.explanation.isNotEmpty;
    final canStart = onStart != null;

    final summary = StringBuffer(
      'Prossima sessione: $displayName, $durationLabel',
    );
    if (hasExplanation) {
      summary.write(', ${session.explanation}');
    }
    summary.write('. Tocca per iniziare.');

    return Semantics(
      label: summary.toString(),
      button: canStart,
      onTap: onStart,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.12),
              pulseTheme.surfaceContainer,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    sessionIcon(session.sessionType),
                    size: 32,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      style: AppTextStyles.h2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    durationLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    intensityText,
                    style: AppTextStyles.bodySmall.copyWith(color: accentColor),
                  ),
                ],
              ),
              if (hasExplanation) ...[
                const SizedBox(height: 8),
                Text(
                  session.explanation,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStart,
                  child: const Text('Inizia sessione'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
