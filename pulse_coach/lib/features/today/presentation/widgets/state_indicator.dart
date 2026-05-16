import 'package:flutter/material.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

/// Displays the current behavioral state label and plain-language explanation.
///
/// When [transitionMessage] is provided, it replaces the static state copy.
class StateIndicator extends StatelessWidget {
  final BehavioralState state;
  final String? transitionMessage;

  const StateIndicator({
    super.key,
    required this.state,
    this.transitionMessage,
  });

  @override
  Widget build(BuildContext context) {
    final pulseThemeOrNull = Theme.of(context).extension<PulseCoachTheme>();
    assert(
      pulseThemeOrNull != null,
      'StateIndicator requires PulseCoachTheme to be registered on the ambient ThemeData (see AppTheme).',
    );
    final pulseTheme = pulseThemeOrNull!;
    final l10n = AppLocalizations.of(context)!;
    final stateColor = StateMessages.colorFor(state, pulseTheme);
    final subCopy =
        transitionMessage ?? StateMessages.staticCopyFor(state, l10n);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StateIcon(state: state, color: stateColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                StateMessages.labelFor(state, l10n),
                style: AppTextStyles.h3.copyWith(color: stateColor),
              ),
              const SizedBox(height: 2),
              Text(
                subCopy,
                style: AppTextStyles.bodySmall.copyWith(
                  color: pulseTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StateMessages {
  const StateMessages._();

  static String labelFor(BehavioralState state, AppLocalizations l10n) {
    switch (state) {
      case BehavioralState.active:
        return l10n.stateLabelActive;
      case BehavioralState.fatigued:
        return l10n.stateLabelFatigued;
      case BehavioralState.atRisk:
        return l10n.stateLabelAtRisk;
      case BehavioralState.recovering:
        return l10n.stateLabelRecovering;
    }
  }

  static String staticCopyFor(BehavioralState state, AppLocalizations l10n) {
    switch (state) {
      case BehavioralState.active:
        return l10n.staticCopyActive;
      case BehavioralState.fatigued:
        return l10n.staticCopyFatigued;
      case BehavioralState.atRisk:
        return l10n.staticCopyAtRisk;
      case BehavioralState.recovering:
        return l10n.staticCopyRecovering;
    }
  }

  static Color colorFor(BehavioralState state, PulseCoachTheme theme) {
    switch (state) {
      case BehavioralState.active:
        return theme.primaryColor;
      case BehavioralState.fatigued:
        return theme.secondary;
      case BehavioralState.atRisk:
        return theme.tertiary;
      case BehavioralState.recovering:
        return theme.secondary.withValues(alpha: 0.70);
    }
  }
}

class _StateIcon extends StatelessWidget {
  final BehavioralState state;
  final Color color;

  const _StateIcon({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BehavioralState.atRisk:
        return Icon(Icons.warning_amber_outlined, color: color, size: 20);
      case BehavioralState.recovering:
        return Icon(Icons.autorenew, color: color, size: 20);
      case BehavioralState.active:
      case BehavioralState.fatigued:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    }
  }
}
