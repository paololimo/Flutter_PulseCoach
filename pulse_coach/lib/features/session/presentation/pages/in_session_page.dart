import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
import 'package:pulse_coach/features/session/presentation/utils/haptic_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/live_hr_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_notification_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_reconciliation_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_step_generator.dart';
import 'package:pulse_coach/features/session/presentation/utils/wear_bridge_service.dart';
import 'package:pulse_coach/features/session/presentation/widgets/countdown_overlay.dart';
import 'package:pulse_coach/features/session/presentation/widgets/in_session_view.dart';
import 'package:pulse_coach/features/session/presentation/widgets/session_notification_rationale_dialog.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InSessionPage extends StatefulWidget {
  final PlannedSession? session;
  final int? planId;
  final int sessionIndex;
  final SessionNotificationService? notificationService;
  final SessionReconciliationService? reconciliationService;
  // Story 22.5: non-null when deep-linking back into an already-running,
  // backgrounded session — see `build()`'s CountdownOverlay-skip branch.
  final int? resumeStepIndex;
  final int? resumeSecondsRemaining;
  final int? resumeElapsedSeconds;

  const InSessionPage({
    this.session,
    this.planId,
    this.sessionIndex = 0,
    this.notificationService,
    this.reconciliationService,
    this.resumeStepIndex,
    this.resumeSecondsRemaining,
    this.resumeElapsedSeconds,
    super.key,
  });

  @override
  State<InSessionPage> createState() => _InSessionPageState();
}

class _InSessionPageState extends State<InSessionPage>
    with WidgetsBindingObserver {
  // Suppresses re-prompting the rationale dialog once the user has been asked.
  // Persisted because the plugin (flutter_local_notifications v21) cannot
  // distinguish "denied" from "never asked" — both resolve to `undetermined`,
  // so without this flag a declined user would be re-prompted every session.
  static const String _kRationaleShownKey = 'notification_rationale_shown';

  final VibrationHapticService _hapticService = VibrationHapticService();
  HealthLiveHrService? _liveHrService;
  late final SessionNotificationService _notificationService;
  late final SessionReconciliationService? _reconciliationService;
  bool _countdownDone = false;
  InSessionCubit? _cubit;
  WearBridgeService? _wearBridge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Claim ownership of the warm notification-tap path: while this page is
    // mounted, `_handleResumed` (lifecycle) is the sole handler and the plugin
    // tap callback must no-op to avoid racing the single snapshot (review F1).
    inSessionPageActive = true;
    _notificationService =
        widget.notificationService ?? LocalSessionNotificationService();
    unawaited(_notificationService.init());
    _reconciliationService =
        widget.reconciliationService ??
        (getIt.isRegistered<SessionLogsDao>() &&
                getIt.isRegistered<SharedPreferences>()
            ? SessionReconciliationService(
                getIt<SharedPreferences>(),
                getIt<SessionLogsDao>(),
              )
            : null);
    _hapticService.init();
    if (getIt.isRegistered<Health>()) {
      _liveHrService = HealthLiveHrService(getIt<Health>());
      unawaited(_liveHrService!.init());
    }
    // A resumed (deep-linked) session must never show the 3-2-1 countdown
    // ceremony — it is returning to an already-running session, not starting
    // a fresh one.
    if (widget.resumeStepIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onCountdownComplete(),
      );
    }
  }

  void _onCountdownComplete() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final steps = SessionStepGenerator.generate(widget.session, l10n);
    final cubit = InSessionCubit(
      steps: steps,
      sessionLogsDao: getIt.isRegistered<SessionLogsDao>() ? getIt() : null,
      planId: widget.planId,
      sessionIndex: widget.sessionIndex,
      hapticService: _hapticService,
      liveHrService: _liveHrService,
      initialStepIndex: widget.resumeStepIndex,
      initialSecondsRemaining: widget.resumeSecondsRemaining,
      initialElapsedSeconds: widget.resumeElapsedSeconds,
    )..start();
    _wearBridge = WearBridgeService()
      ..start(
        cubit.stream,
        sessionType: widget.session?.sessionType,
        durationMinutes: widget.session?.durationMinutes ?? 0,
      );

    setState(() {
      _cubit = cubit;
      _countdownDone = true;
    });

    // Permission was already resolved before this session was ever
    // backgrounded — re-prompting on resume would be jarring.
    if (widget.resumeStepIndex == null) {
      unawaited(_maybeShowNotificationRationale());
    }
  }

  Future<void> _maybeShowNotificationRationale() async {
    final status = await _notificationService.permissionStatus();
    if (status != NotificationPermissionStatus.undetermined) return;

    final prefs = getIt.isRegistered<SharedPreferences>()
        ? getIt<SharedPreferences>()
        : null;
    if (prefs?.getBool(_kRationaleShownKey) ?? false) return;

    if (!mounted) return;
    final allow = await showDialog<bool>(
      context: context,
      builder: (_) => const SessionNotificationRationaleDialog(),
    );
    // Record that we asked (regardless of the answer) so a declined user is
    // not re-prompted on every subsequent session — see judgment call #2.
    await prefs?.setBool(_kRationaleShownKey, true);
    if (allow == true) {
      await _notificationService.requestPermission();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _handlePaused();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_handleResumed());
    }
  }

  void _handlePaused() {
    if (!mounted) return;
    final cubit = _cubit;
    final session = widget.session;
    if (cubit == null || session == null) return;
    if (cubit.state.isComplete || cubit.state.isAbandoned) return;

    cubit.pauseTimers();
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      _notificationService.showSessionPaused(
        sessionName: sessionDisplayName(session.sessionType, l10n),
        secondsRemaining: cubit.state.secondsRemaining,
      ),
    );

    final reconciliationService = _reconciliationService;
    if (reconciliationService != null) {
      unawaited(
        reconciliationService.writeSnapshot(
          BackgroundedSessionSnapshot(
            planId: widget.planId,
            sessionIndex: widget.sessionIndex,
            session: session,
            currentStepIndex: cubit.state.currentStepIndex,
            secondsRemaining: cubit.state.secondsRemaining,
            elapsedSeconds: cubit.elapsedSeconds,
            backgroundedAt: DateTime.now(),
          ),
        ),
      );
    }
  }

  Future<void> _handleResumed() async {
    if (!mounted) return;
    final cubit = _cubit;
    final session = widget.session;
    final reconciliationService = _reconciliationService;
    if (cubit == null || session == null || reconciliationService == null) {
      return;
    }

    final result = await reconciliationService.reconcile();
    if (!mounted) return;
    switch (result) {
      case SessionReconciliationResult.stillWithinWindow:
        // Re-anchor elapsed to the value frozen at backgrounding so the dead
        // background interval is not counted as session time — matches the
        // cold-start deep-link path's `_startedAt` seeding (review F2).
        final snapshot = reconciliationService.readSnapshot();
        if (snapshot != null) cubit.reseedElapsed(snapshot.elapsedSeconds);
        cubit.resumeTimers();
        await reconciliationService.clearSnapshot();
        unawaited(_notificationService.cancel());
      case SessionReconciliationResult.abandonedByTimeout:
        unawaited(cubit.abandon());
        unawaited(_notificationService.cancel());
      case SessionReconciliationResult.none:
        break;
    }
  }

  @override
  void dispose() {
    inSessionPageActive = false;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_wearBridge?.stop());
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_countdownDone || _cubit == null) {
      // A resumed (deep-linked) session must never show the 3-2-1 countdown
      // ceremony (Story 22.5) — `_onCountdownComplete` is already scheduled
      // via `initState`'s post-frame callback, so render nothing until it
      // flips `_countdownDone`.
      if (widget.resumeStepIndex != null) return const SizedBox.shrink();

      final l10n = AppLocalizations.of(context)!;
      final sessionTitle = widget.session != null
          ? sessionDisplayName(widget.session!.sessionType, l10n)
          : null;

      return CountdownOverlay(
        sessionTitle: sessionTitle,
        onCountdownComplete: _onCountdownComplete,
      );
    }

    return BlocProvider.value(
      value: _cubit!,
      child: BlocListener<InSessionCubit, InSessionState>(
        listenWhen: (previous, current) =>
            (current.isComplete && !previous.isComplete) ||
            (current.isAbandoned && !previous.isAbandoned),
        listener: (context, state) {
          final session = widget.session;
          // Skip the RPE leg entirely when we cannot derive a real arm key —
          // an empty key would otherwise be persisted into bandit reward
          // space (Story 9.3) and corrupt arm statistics.
          if (session == null) {
            context.go(AppRouter.today);
            return;
          }
          final armKey =
              '${session.sessionType}_${_intensityName(session.intensity)}';
          context.go(
            AppRouter.sessionRpe,
            extra: RpeSubmitArgs(
              planId: widget.planId,
              sessionIndex: widget.sessionIndex,
              abandoned: state.isAbandoned,
              armKey: armKey,
              durationMinutes: session.durationMinutes,
              // Resolved by RpeFeedbackCubit from (planId, sessionIndex) —
              // InSessionCubit owns the SessionLog write but does not surface
              // the row id here.
              sessionLogId: null,
            ),
          );
        },
        child: BlocBuilder<InSessionCubit, InSessionState>(
          builder: (context, state) => InSessionView(
            sessionState: state,
            onAbandon: () => unawaited(_confirmAndAbandon(context)),
          ),
        ),
      ),
    );
  }

  /// Inverse of `ContextualBandit._intensityValue`: maps the persisted
  /// `PlannedSession.intensity` int (1..10) back to the arm-key bucket. Ranges
  /// follow `safety_constraints.dart`: low = 1..3, medium = 4..7, high = 8..10.
  /// Inputs outside that range are clamped into the nearest bucket so a
  /// corrupted intensity cannot silently invent a new arm.
  String _intensityName(int intensity) {
    if (intensity <= 3) return 'low';
    if (intensity <= 7) return 'medium';
    return 'high';
  }

  Future<void> _confirmAndAbandon(BuildContext context) async {
    // Pause the countdown while the sheet is open so the session cannot
    // auto-complete underneath the modal (review fix: pause-on-sheet).
    _cubit?.pauseTimers();
    bool? confirmed;
    try {
      confirmed = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => _AbandonConfirmSheet(sheetContext),
      );
    } catch (e, st) {
      AppLogger.warning(
        'confirmation sheet failed',
        name: 'InSessionPage',
        error: e,
        stackTrace: st,
      );
    }

    if (confirmed == true && mounted) {
      try {
        await _cubit?.abandon();
      } catch (e, st) {
        AppLogger.warning(
          'abandon failed',
          name: 'InSessionPage',
          error: e,
          stackTrace: st,
        );
      }
    } else {
      // User cancelled (or sheet failed). Resume the countdown.
      _cubit?.resumeTimers();
    }
  }
}

class _AbandonConfirmSheet extends StatefulWidget {
  // The sheet's own BuildContext from showModalBottomSheet's builder. Held so
  // pop() targets the correct route even if the underlying page is rebuilt.
  final BuildContext sheetContext;

  const _AbandonConfirmSheet(this.sheetContext);

  @override
  State<_AbandonConfirmSheet> createState() => _AbandonConfirmSheetState();
}

class _AbandonConfirmSheetState extends State<_AbandonConfirmSheet> {
  // Debounce double-taps: once a decision is being processed, ignore further
  // taps so a second tap cannot pop the underlying InSessionPage route
  // (review fix: button debounce).
  bool _popping = false;

  void _pop(bool value) {
    if (_popping) return;
    _popping = true;
    Navigator.of(widget.sheetContext).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.inSessionAbandonConfirmTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.inSessionAbandonConfirmBody,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _popping ? null : () => _pop(false),
              child: Text(l10n.inSessionAbandonKeepGoingButton),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _popping ? null : () => _pop(true),
              child: Text(l10n.inSessionAbandonConfirmButton),
            ),
          ],
        ),
      ),
    );
  }
}
