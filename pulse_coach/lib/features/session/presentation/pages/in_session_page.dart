import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
import 'package:pulse_coach/features/session/presentation/utils/haptic_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/live_hr_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_step_generator.dart';
import 'package:pulse_coach/features/session/presentation/widgets/countdown_overlay.dart';
import 'package:pulse_coach/features/session/presentation/widgets/in_session_view.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class InSessionPage extends StatefulWidget {
  final PlannedSession? session;
  final int? planId;
  final int sessionIndex;

  const InSessionPage({
    this.session,
    this.planId,
    this.sessionIndex = 0,
    super.key,
  });

  @override
  State<InSessionPage> createState() => _InSessionPageState();
}

class _InSessionPageState extends State<InSessionPage> {
  final VibrationHapticService _hapticService = VibrationHapticService();
  HealthLiveHrService? _liveHrService;
  bool _countdownDone = false;
  InSessionCubit? _cubit;

  @override
  void initState() {
    super.initState();
    _hapticService.init();
    if (getIt.isRegistered<Health>()) {
      _liveHrService = HealthLiveHrService(getIt<Health>());
      unawaited(_liveHrService!.init());
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
    )..start();

    setState(() {
      _cubit = cubit;
      _countdownDone = true;
    });
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_countdownDone || _cubit == null) {
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
        listener: (context, state) => context.go(AppRouter.sessionRpe),
        child: BlocBuilder<InSessionCubit, InSessionState>(
          builder: (context, state) => InSessionView(
            sessionState: state,
            onAbandon: () => unawaited(_confirmAndAbandon(context)),
          ),
        ),
      ),
    );
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
      debugPrint('InSessionPage: confirmation sheet failed: $e\n$st');
    }

    if (confirmed == true && mounted) {
      try {
        await _cubit?.abandon();
      } catch (e, st) {
        debugPrint('InSessionPage: abandon failed: $e\n$st');
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
