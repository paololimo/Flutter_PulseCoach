import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

/// Passive readout of the rolling 30-day active-days count. Not a streak:
/// no reset messaging, no flame glyph, no animation beyond the standard
/// card reveal (AC3, AC4).
class ActiveDaysCard extends StatelessWidget {
  final int count;

  const ActiveDaysCard({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final caption = l10n.activeDaysCaption(count);

    return Semantics(
      label: caption,
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: pulseTheme.surfaceContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              caption,
              style: AppTextStyles.caption.copyWith(
                color: pulseTheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
