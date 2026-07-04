import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
import 'package:pulse_coach/features/session/presentation/utils/haptic_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_step_generator.dart';
import 'package:pulse_coach/features/session/presentation/widgets/in_session_view.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/widgets/join_code_card.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class SharedSessionLobbyPage extends StatefulWidget {
  const SharedSessionLobbyPage({super.key});

  @override
  State<SharedSessionLobbyPage> createState() =>
      _SharedSessionLobbyPageState();
}

class _SharedSessionLobbyPageState extends State<SharedSessionLobbyPage> {
  // Cached from the last inSession render so the sessionEnded listener can
  // compute totalDurationMinutes without needing the previous bloc state.
  List<ExerciseStep> _lastSteps = const [];

  @override
  Widget build(BuildContext context) {
    return BlocListener<SharedSessionBloc, SharedSessionState>(
      listenWhen: (prev, curr) {
        final cancelled = curr.mapOrNull(cancelled: (_) => true) ?? false;
        if (cancelled) return true;
        final sessionEnded = curr.mapOrNull(sessionEnded: (_) => true) ?? false;
        if (sessionEnded) return true;
        final prevTick = prev.mapOrNull(lobby: (s) => s.refreshErrorTick);
        final currTick = curr.mapOrNull(lobby: (s) => s.refreshErrorTick);
        return prevTick != null && currTick != null && currTick != prevTick;
      },
      listener: (context, state) {
        state.mapOrNull(
          cancelled: (_) {
            if (context.canPop()) context.pop();
          },
          sessionEnded: (s) {
            final totalDurationMinutes =
                _lastSteps.fold(0, (sum, step) => sum + step.durationSeconds) ~/
                    60;
            context.go(
              AppRouter.sessionRpe,
              extra: RpeSubmitArgs(
                planId: null,
                sessionIndex: 0,
                abandoned: false,
                armKey: s.armKey,
                durationMinutes: totalDurationMinutes,
                sessionLogId: null,
                sharedSessionId: s.sessionId,
              ),
            );
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
            inSession: (s) {
              final l10n = AppLocalizations.of(context)!;
              final steps = SessionStepGenerator.generate(
                PlannedSession(
                  sessionType: s.sessionType,
                  intensity: s.intensity,
                  durationMinutes: s.durationMinutes,
                  isIndoor: true,
                ),
                l10n,
              );
              _lastSteps = steps;
              return _SharedInSessionView(
                stepIndex: s.stepIndex,
                elapsedSeconds: s.elapsedSeconds,
                isHost: s.isHost,
                steps: steps,
                participantCount: s.participants.length,
                droppedHandle: s.droppedHandle,
              );
            },
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
    final l10n = AppLocalizations.of(context)!;
    final handle = participant.displayHandle;
    // Never render the raw userId (a 36-char UUID) — it leaks an internal id and
    // overflows the row on narrow screens. Show the @handle when known, otherwise
    // a localized generic label. Expanded + ellipsis guarantees no overflow.
    final label =
        handle != null ? '@$handle' : l10n.sharedSessionParticipantUnknown;
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(color: pulseTheme.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
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
class _SharedInSessionView extends StatefulWidget {
  final int stepIndex;
  final int elapsedSeconds;
  final bool isHost;
  final List<ExerciseStep> steps;
  final int participantCount;
  final String? droppedHandle;

  const _SharedInSessionView({
    required this.stepIndex,
    required this.elapsedSeconds,
    required this.isHost,
    required this.steps,
    required this.participantCount,
    this.droppedHandle,
  });

  @override
  State<_SharedInSessionView> createState() => _SharedInSessionViewState();
}

class _SharedInSessionViewState extends State<_SharedInSessionView> {
  // HOST-ONLY fields
  InSessionCubit? _hostCubit;
  StreamSubscription<InSessionState>? _hostSub;
  int _prevHostStepIndex = 0;
  bool _endDispatched = false;

  // FOLLOWER-ONLY fields
  Timer? _tickTimer;
  int _displayedElapsed = 0;

  // Captured in initState so the async stream callback can reference the bloc
  // safely after widget disposal.
  late SharedSessionBloc _sharedBloc;

  @override
  void initState() {
    super.initState();
    _sharedBloc = context.read<SharedSessionBloc>();
    if (widget.isHost) {
      _initHostCubit();
    } else {
      _displayedElapsed = widget.elapsedSeconds;
      _startFollowerTick();
    }
  }

  void _initHostCubit() {
    // Guard empty steps before constructing the cubit: InSessionCubit's
    // constructor reads steps.first, which throws StateError on an empty list.
    // The empty-steps Scaffold in build() handles rendering in that case.
    if (widget.steps.isEmpty) return;
    final cubit = InSessionCubit(
      steps: widget.steps,
      sessionLogsDao: null,
      planId: null,
      hapticService: VibrationHapticService(),
    )..start();
    _hostCubit = cubit;
    _hostSub = cubit.stream.listen(_onHostCubitState);
  }

  void _onHostCubitState(InSessionState cubitState) {
    if (!mounted) return;
    if (cubitState.currentStepIndex != _prevHostStepIndex) {
      final elapsed = _elapsedAtStepStart(cubitState.currentStepIndex);
      _prevHostStepIndex = cubitState.currentStepIndex;
      _sharedBloc.add(
        HostStepAdvanced(
          stepIndex: cubitState.currentStepIndex,
          elapsedSeconds: elapsed,
        ),
      );
    }
    if (cubitState.isComplete && !_endDispatched) {
      _endDispatched = true;
      _sharedBloc.add(const SessionEndRequested());
    }
  }

  // Total elapsed at the START of [stepIdx] = sum of all prior step durations.
  int _elapsedAtStepStart(int stepIdx) =>
      widget.steps.take(stepIdx).fold(0, (sum, s) => sum + s.durationSeconds);

  void _startFollowerTick() {
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _displayedElapsed++);
    });
  }

  @override
  void didUpdateWidget(_SharedInSessionView old) {
    super.didUpdateWidget(old);

    // Follower → host promotion: when the host drops, the bloc promotes the
    // lowest-userId follower (re-emits inSession with isHost: true). isHost is
    // captured once in initState, so we must react to the flip here — otherwise
    // _buildHostView finds _hostCubit == null and renders a blank screen,
    // stranding every participant with no way to advance or end the session.
    if (widget.isHost && !old.isHost && _hostCubit == null) {
      _promoteToHost();
      return;
    }

    if (!widget.isHost && widget.stepIndex != old.stepIndex) {
      // Snap the displayed elapsed to the authoritative broadcast value and
      // fire haptic for the step transition (NFR4).
      setState(() => _displayedElapsed = widget.elapsedSeconds);
      HapticFeedback.mediumImpact();
    }
  }

  // Tear down the follower tick and spin up the host cubit so the promoted
  // participant drives step advances and the eventual SessionEndRequested.
  // The cubit starts from step 0 (InSessionCubit cannot resume mid-session);
  // resume-at-current-step is deferred to Story 20.5.
  void _promoteToHost() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _prevHostStepIndex = 0;
    _initHostCubit();
    setState(() {});
  }

  @override
  void dispose() {
    _hostSub?.cancel();
    _hostCubit?.close();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      return Scaffold(
        backgroundColor: pulseTheme.surface,
        body: const SizedBox.shrink(),
      );
    }

    if (widget.isHost) {
      return _buildHostView(context);
    } else {
      return _buildFollowerView(context);
    }
  }

  Widget _buildHostView(BuildContext context) {
    final cubit = _hostCubit;
    if (cubit == null) return const SizedBox.shrink();
    return BlocProvider<InSessionCubit>.value(
      value: cubit,
      child: BlocBuilder<InSessionCubit, InSessionState>(
        builder: (ctx, cubitState) => Stack(
          children: [
            InSessionView(
              sessionState: cubitState,
              onAbandon: () => _onHostAbandon(),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _ParticipantBadge(count: widget.participantCount),
              ),
            ),
            if (widget.droppedHandle != null)
              _DroppedHandleNotice(handle: widget.droppedHandle!),
          ],
        ),
      ),
    );
  }

  void _onHostAbandon() {
    if (!_endDispatched) {
      _endDispatched = true;
      _sharedBloc.add(const SessionEndRequested());
    }
  }

  Widget _buildFollowerView(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final safeIndex = widget.stepIndex.clamp(0, widget.steps.length - 1);
    final step = widget.steps[safeIndex];
    final totalSteps = widget.steps.length;
    final displayStep = safeIndex + 1;
    // Show the current step's *remaining* time (count-down), matching the v1
    // solo InSessionView the host renders. _displayedElapsed is total elapsed;
    // widget.elapsedSeconds is the elapsed at this step's start (broadcast).
    final withinStep =
        (_displayedElapsed - widget.elapsedSeconds).clamp(0, step.durationSeconds);
    final secondsRemaining = step.durationSeconds - withinStep;

    return Scaffold(
      backgroundColor: pulseTheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ParticipantBadge(count: widget.participantCount),
                  const SizedBox(height: 8),
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
                    _formatTime(secondsRemaining),
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
                  if (widget.droppedHandle != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.sharedSessionParticipantDropped(widget.droppedHandle!),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: pulseTheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
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

class _ParticipantBadge extends StatelessWidget {
  final int count;

  const _ParticipantBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    return Text(
      l10n.sharedSessionParticipantCount(count.toString()),
      style: AppTextStyles.bodySmall.copyWith(
        color: pulseTheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _DroppedHandleNotice extends StatelessWidget {
  final String handle;

  const _DroppedHandleNotice({required this.handle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    return Positioned(
      bottom: 80,
      left: 24,
      right: 24,
      child: Text(
        l10n.sharedSessionParticipantDropped(handle),
        style: AppTextStyles.bodySmall.copyWith(
          color: pulseTheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
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
