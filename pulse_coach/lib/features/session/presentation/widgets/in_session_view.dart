import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class InSessionView extends StatelessWidget {
  final InSessionState sessionState;
  final VoidCallback onAbandon;

  const InSessionView({
    required this.sessionState,
    required this.onAbandon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final step = sessionState.currentStep;

    return Scaffold(
      backgroundColor: pulseTheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      step.title,
                      style: AppTextStyles.h2.copyWith(
                        color: pulseTheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.inSessionStepLabel(
                      (sessionState.currentStepIndex + 1).toString(),
                      sessionState.totalSteps.toString(),
                    ),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _formatTime(sessionState.secondsRemaining),
                    style: AppTextStyles.timerDisplay.copyWith(
                      color: pulseTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value:
                        (sessionState.currentStepIndex + 1) /
                        sessionState.totalSteps,
                    backgroundColor: pulseTheme.surfaceContainerHigh,
                    color: pulseTheme.primaryColor,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    step.instruction,
                    style: AppTextStyles.body.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onAbandon,
                    child: Text(
                      l10n.inSessionAbandonButton,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: pulseTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (sessionState.liveHr != null)
              Positioned(
                top: 16,
                right: 16,
                child: _HrBadge(
                  bpm: sessionState.liveHr!,
                  lastHrAtEpochMs: sessionState.lastHrAtEpochMs,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _HrBadge extends StatelessWidget {
  const _HrBadge({required this.bpm, this.lastHrAtEpochMs});

  static const int _staleAfterMs = 15000;

  final int bpm;
  final int? lastHrAtEpochMs;

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final label = l10n.inSessionHrDisplay(bpm.toString());

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isStale = lastHrAtEpochMs != null &&
        (nowMs - lastHrAtEpochMs!) > _staleAfterMs;

    return Semantics(
      label: 'Heart rate $bpm beats per minute',
      liveRegion: true,
      child: Opacity(
        opacity: isStale ? 0.4 : 1.0,
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: pulseTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
