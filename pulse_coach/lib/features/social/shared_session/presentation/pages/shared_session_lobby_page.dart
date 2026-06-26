import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/widgets/join_code_card.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class SharedSessionLobbyPage extends StatelessWidget {
  const SharedSessionLobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SharedSessionBloc, SharedSessionState>(
      listenWhen: (prev, curr) {
        // Fire on cancel (to pop) or when a join-code refresh just failed.
        // Fatal errors are rendered full-screen by _ErrorView, not snackbarred.
        final cancelled = curr.mapOrNull(cancelled: (_) => true) ?? false;
        if (cancelled) return true;
        final prevTick = prev.mapOrNull(lobby: (s) => s.refreshErrorTick);
        final currTick = curr.mapOrNull(lobby: (s) => s.refreshErrorTick);
        return prevTick != null && currTick != null && currTick != prevTick;
      },
      listener: (context, state) {
        state.mapOrNull(
          cancelled: (_) {
            if (context.canPop()) context.pop();
          },
          lobby: (_) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.sharedSessionRefreshError)),
            );
          },
        );
      },
      child: BlocBuilder<SharedSessionBloc, SharedSessionState>(
        builder: (context, state) {
          return state.map(
            initial: (_) => const SizedBox.shrink(),
            loading: (_) => const _LobbyShimmer(),
            lobby: (s) => _LobbyView(
              participants: s.participants,
              isHost: s.isHost,
              steps: s.steps,
              joinCode: s.joinCode,
              coLocated: s.coLocated,
              onStart: () =>
                  context.read<SharedSessionBloc>().add(const SessionStartTapped()),
              onCancel: () => _showCancelDialog(context),
            ),
            inSession: (s) => _SharedInSessionView(
              stepIndex: s.stepIndex,
              elapsedSeconds: s.elapsedSeconds,
              steps: s.steps,
              droppedHandle: s.droppedHandle,
            ),
            error: (s) => _ErrorView(failure: s.failure),
            sessionEnded: (_) => const _SessionEndedView(),
            cancelled: (_) => const _CancelledView(),
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sharedSessionCancelDialogTitle),
        content: Text(l10n.sharedSessionCancelDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.sharedSessionCancelDialogKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.sharedSessionCancelDialogConfirm),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<SharedSessionBloc>().add(const SharedSessionCancelled());
      }
    });
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

  Widget _shimmerBox(BuildContext context,
      {required double height, double? width}) {
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

class _LobbyView extends StatefulWidget {
  final List<ParticipantPresence> participants;
  final bool isHost;
  final List<ExerciseStep> steps;
  final String? joinCode;
  final bool? coLocated;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  const _LobbyView({
    required this.participants,
    required this.isHost,
    required this.steps,
    this.joinCode,
    this.coLocated,
    required this.onStart,
    required this.onCancel,
  });

  @override
  State<_LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<_LobbyView> {
  bool _showNoOneYet = false;
  Timer? _waitTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isHost) {
      _waitTimer = Timer(const Duration(minutes: 5), () {
        if (mounted) setState(() => _showNoOneYet = true);
      });
    }
  }

  @override
  void didUpdateWidget(_LobbyView old) {
    super.didUpdateWidget(old);
    // Clear the "no one yet" message when another participant joins
    if (widget.participants.length > 1 && _showNoOneYet) {
      setState(() => _showNoOneYet = false);
    }
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final canStart = widget.isHost && widget.participants.length >= 2;

    return Scaffold(
      backgroundColor: pulseTheme.surface,
      appBar: AppBar(
        title: Text(l10n.sharedSessionLobbyTitle),
        leading: widget.isHost
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (widget.isHost && widget.joinCode != null) ...[
            JoinCodeCard(
              joinCode: widget.joinCode!,
              onRefresh: () => context
                  .read<SharedSessionBloc>()
                  .add(const SharedSessionJoinCodeRefreshed()),
            ),
            const SizedBox(height: 8),
          ],
          if (_showNoOneYet && widget.participants.length <= 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.sharedSessionNoOneYet,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          if (widget.participants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.sharedSessionLobbyWaiting,
                style: AppTextStyles.body.copyWith(
                  color: pulseTheme.onSurfaceVariant,
                ),
              ),
            ),
          ...widget.participants.map(
            (p) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _ParticipantRow(participant: p),
            ),
          ),
          if (!widget.isHost && widget.coLocated == true)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on,
                      size: 16,
                      color: pulseTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    l10n.sharedSessionCoLocated,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: pulseTheme.primaryColor),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: canStart ? widget.onStart : null,
                child: Text(l10n.sharedSessionStartButton),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.sharedSessionWaitingForHost,
                style: AppTextStyles.bodySmall.copyWith(
                  color: pulseTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
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

class _CancelledView extends StatelessWidget {
  const _CancelledView();

  @override
  Widget build(BuildContext context) {
    // Terminal state; navigation pop handled by BlocListener above.
    return const SizedBox.shrink();
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
