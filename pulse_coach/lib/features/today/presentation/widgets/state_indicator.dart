import 'package:flutter/material.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

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
    final stateColor = StateMessages.colorFor(state, pulseTheme);
    final subCopy = transitionMessage ?? StateMessages.staticCopyFor(state);

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
                StateMessages.labelFor(state),
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

  static String labelFor(BehavioralState state) {
    switch (state) {
      case BehavioralState.active:
        return 'In forma';
      case BehavioralState.fatigued:
        return 'Sotto sforzo';
      case BehavioralState.atRisk:
        return 'In ripresa';
      case BehavioralState.recovering:
        return 'In recupero';
    }
  }

  static String staticCopyFor(BehavioralState state) {
    switch (state) {
      case BehavioralState.active:
        return 'Pronto per il piano di oggi.';
      case BehavioralState.fatigued:
        return 'Oggi alleggeriamo per recuperare.';
      case BehavioralState.atRisk:
        return 'Ripartiamo con calma. Sessioni brevi e leggere.';
      case BehavioralState.recovering:
        return 'Costruiamo il ritmo, un passo alla volta.';
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
