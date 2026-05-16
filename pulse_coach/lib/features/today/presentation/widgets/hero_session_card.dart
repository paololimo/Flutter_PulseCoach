import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class HeroSessionCard extends StatelessWidget {
  final PlannedSession session;
  final VoidCallback? onStart;
  final String? heroTag;
  final VoidCallback? onRegenerate;

  const HeroSessionCard({
    super.key,
    required this.session,
    this.onStart,
    this.heroTag,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final pulseThemeOrNull = Theme.of(context).extension<PulseCoachTheme>();
    assert(
      pulseThemeOrNull != null,
      'HeroSessionCard requires PulseCoachTheme extension',
    );
    final pulseTheme = pulseThemeOrNull!;
    final l10n = AppLocalizations.of(context)!;

    final accentColor = sessionAccentColor(session.sessionType, pulseTheme);
    final displayName = sessionDisplayName(session.sessionType, l10n);
    final durationLabel = '${session.durationMinutes} min';
    final intensityText = intensityLabel(session.intensity, l10n);
    final hasExplanation = session.explanation.isNotEmpty;
    final canStart = onStart != null;

    final summary = StringBuffer(
      l10n.heroCardSemanticPreamble(displayName, durationLabel),
    );
    if (hasExplanation) {
      summary.write(', ${session.explanation}');
    }
    summary.write('. ${l10n.heroCardSemanticCta}');

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
                  heroTag != null
                      ? Hero(
                          tag: heroTag!,
                          child: Icon(
                            sessionIcon(session.sessionType),
                            size: 32,
                            color: accentColor,
                          ),
                        )
                      : Icon(
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
                  if (onRegenerate != null)
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        size: 20,
                        semanticLabel: l10n.regenSemanticLabel,
                      ),
                      color: pulseTheme.onSurfaceVariant,
                      onPressed: onRegenerate,
                      tooltip: l10n.regenTooltip,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
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
                  child: Text(l10n.startSessionButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
