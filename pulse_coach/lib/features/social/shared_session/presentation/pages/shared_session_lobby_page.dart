import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class SharedSessionLobbyPage extends StatelessWidget {
  const SharedSessionLobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SharedSessionBloc, SharedSessionState>(
      builder: (context, state) {
        return state.map(
          initial: (_) => const SizedBox.shrink(),
          loading: (_) => const _LobbyShimmer(),
          lobby: (s) => _LobbyView(
            participants: s.participants,
            isHost: s.isHost,
            steps: s.steps,
            onStart: () =>
                context.read<SharedSessionBloc>().add(const SessionStartTapped()),
          ),
          inSession: (s) => _SharedInSessionView(
            stepIndex: s.stepIndex,
            elapsedSeconds: s.elapsedSeconds,
            steps: s.steps,
            droppedHandle: s.droppedHandle,
          ),
          error: (s) => _ErrorView(failure: s.failure),
          sessionEnded: (_) => const _SessionEndedView(),
        );
      },
    );
  }
}

class _LobbyShimmer extends StatelessWidget {
  const _LobbyShimmer();

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    return Scaffold(
      backgroundColor: pulseTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _shimmerBox(context, height: 28, width: 200),
                const SizedBox(height: 24),
                for (int i = 0; i < 3; i++) ...[
                  _shimmerBox(context, height: 48),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 24),
                _shimmerBox(context, height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(BuildContext context, {required double height, double? width}) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: pulseTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _LobbyView extends StatelessWidget {
  final List<ParticipantPresence> participants;
  final bool isHost;
  final List<ExerciseStep> steps;
  final VoidCallback onStart;

  const _LobbyView({
    required this.participants,
    required this.isHost,
    required this.steps,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final canStart = isHost && participants.length >= 2;

    return Scaffold(
      backgroundColor: pulseTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sharedSessionLobbyTitle,
                style: AppTextStyles.h2.copyWith(color: pulseTheme.onSurface),
              ),
              const SizedBox(height: 24),
              ...participants.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ParticipantRow(participant: p),
                ),
              ),
              if (participants.isEmpty)
                Text(
                  l10n.sharedSessionLobbyWaiting,
                  style: AppTextStyles.body.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 32),
              if (isHost)
                FilledButton(
                  onPressed: canStart ? onStart : null,
                  child: Text(l10n.sharedSessionStartButton),
                )
              else
                Text(
                  l10n.sharedSessionWaitingForHost,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final ParticipantPresence participant;

  const _ParticipantRow({required this.participant});

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 20),
        const SizedBox(width: 8),
        Text(
          participant.displayHandle ?? participant.userId,
          style: AppTextStyles.body.copyWith(color: pulseTheme.onSurface),
        ),
      ],
    );
  }
}

// AC5: Semantics(liveRegion: true, label: step.title) on the step name
// widget so AT users receive announcements when the group advances silently.
class _SharedInSessionView extends StatelessWidget {
  final int stepIndex;
  final int elapsedSeconds;
  final List<ExerciseStep> steps;
  final String? droppedHandle;

  const _SharedInSessionView({
    required this.stepIndex,
    required this.elapsedSeconds,
    required this.steps,
    this.droppedHandle,
  });

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;

    if (steps.isEmpty) {
      return Scaffold(
        backgroundColor: pulseTheme.surface,
        body: const SizedBox.shrink(),
      );
    }

    final safeIndex = stepIndex.clamp(0, steps.length - 1);
    final step = steps[safeIndex];
    final totalSteps = steps.length;
    final displayStep = safeIndex + 1;
    final minutesDisplay = _formatTime(elapsedSeconds);

    return Scaffold(
      backgroundColor: pulseTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                liveRegion: true,
                label: step.title,
                child: Text(
                  step.title,
                  style: AppTextStyles.h2.copyWith(color: pulseTheme.onSurface),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.inSessionStepLabel(
                  displayStep.toString(),
                  totalSteps.toString(),
                ),
                style: AppTextStyles.bodySmall.copyWith(
                  color: pulseTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                minutesDisplay,
                style: AppTextStyles.timerDisplay.copyWith(
                  color: pulseTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: displayStep / totalSteps,
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
              // AC1: inline drop-out note (E18R-2: localized IT, no raw string)
              if (droppedHandle != null) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.sharedSessionParticipantDropped(droppedHandle!),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _ErrorView extends StatelessWidget {
  final Failure failure;

  const _ErrorView({required this.failure});

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: pulseTheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          // E18R-2 + E18R-CB2: NO raw failure.message passthrough.
          child: Text(
            l10n.sharedSessionErrorGeneric,
            style: AppTextStyles.body.copyWith(
              color: pulseTheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// AC4: terminal state shown when session_ended broadcast received.
// Story 20.4 will wire RPE navigation via a BlocListener on sessionEnded().
class _SessionEndedView extends StatelessWidget {
  const _SessionEndedView();

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: pulseTheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.sharedSessionEnded,
            style: AppTextStyles.h2.copyWith(color: pulseTheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
