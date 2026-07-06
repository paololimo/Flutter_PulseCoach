import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
import 'package:pulse_coach/features/session/presentation/widgets/milestone_progress_bar.dart';
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
      body: OrientationBuilder(
        builder: (ctx, orientation) => SafeArea(
          child: orientation == Orientation.landscape
              ? _landscapeBody(ctx, pulseTheme, l10n, step)
              : _portraitBody(ctx, pulseTheme, l10n, step),
        ),
      ),
    );
  }

  Widget _portraitBody(
    BuildContext context,
    PulseCoachTheme pulseTheme,
    AppLocalizations l10n,
    ExerciseStep step,
  ) {
    return Stack(
      children: [
        _scrollable(
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
                MilestoneProgressBar(
                  currentStepIndex: sessionState.currentStepIndex,
                  totalSteps: sessionState.totalSteps,
                  isComplete: sessionState.isComplete,
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
    );
  }

  Widget _landscapeBody(
    BuildContext context,
    PulseCoachTheme pulseTheme,
    AppLocalizations l10n,
    ExerciseStep step,
  ) {
    return Stack(
      children: [
        _scrollable(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          step.title,
                          style: AppTextStyles.h2.copyWith(
                            color: pulseTheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.inSessionStepLabel(
                          (sessionState.currentStepIndex + 1).toString(),
                          sessionState.totalSteps.toString(),
                        ),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: pulseTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatTime(sessionState.secondsRemaining),
                        style: AppTextStyles.timerDisplay.copyWith(
                          color: pulseTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MilestoneProgressBar(
                        currentStepIndex: sessionState.currentStepIndex,
                        totalSteps: sessionState.totalSteps,
                        isComplete: sessionState.isComplete,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        step.instruction,
                        style: AppTextStyles.body.copyWith(
                          color: pulseTheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
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
              ],
            ),
          ),
        ),
        if (sessionState.liveHr != null)
          Positioned(
            top: 8,
            right: 8,
            child: _HrBadge(
              bpm: sessionState.liveHr!,
              lastHrAtEpochMs: sessionState.lastHrAtEpochMs,
            ),
          ),
      ],
    );
  }

  /// Wraps body content so it fills the available height (preserving the
  /// `Spacer`/centered layouts) but degrades to a scroll when content exceeds
  /// it — e.g. large accessibility text scale or very short landscape surfaces.
  Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: child),
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
    final isStale =
        lastHrAtEpochMs != null && (nowMs - lastHrAtEpochMs!) > _staleAfterMs;

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
