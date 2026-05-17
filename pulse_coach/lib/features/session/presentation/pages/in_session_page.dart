import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
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
  bool _countdownDone = false;
  InSessionCubit? _cubit;

  void _onCountdownComplete() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final steps = SessionStepGenerator.generate(widget.session, l10n);
    final cubit = InSessionCubit(
      steps: steps,
      sessionLogsDao: getIt.isRegistered<SessionLogsDao>() ? getIt() : null,
      planId: widget.planId,
      sessionIndex: widget.sessionIndex,
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
            current.isComplete && !previous.isComplete,
        listener: (context, state) => context.go(AppRouter.sessionRpe),
        child: BlocBuilder<InSessionCubit, InSessionState>(
          builder: (context, state) => InSessionView(
            sessionState: state,
            onAbandon: () {
              _cubit!.abandon();
              context.go(AppRouter.today);
            },
          ),
        ),
      ),
    );
  }
}
