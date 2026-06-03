import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';
import 'package:pulse_coach/features/session/domain/usecases/update_bandit_reward.dart';
import 'package:pulse_coach/features/session/presentation/bloc/post_rpe_adaptation_cubit.dart';
import 'package:pulse_coach/features/session/presentation/bloc/rpe_feedback_cubit.dart';
import 'package:pulse_coach/features/session/presentation/bloc/rpe_feedback_state.dart';
import 'package:pulse_coach/features/session/presentation/utils/wear_bridge_service.dart';
import 'package:pulse_coach/features/session/presentation/widgets/rpe_input_widget.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class RpePage extends StatefulWidget {
  final RpeSubmitArgs? args;

  const RpePage({this.args, super.key});

  @override
  State<RpePage> createState() => _RpePageState();
}

class _RpePageState extends State<RpePage> {
  RpeFeedbackCubit? _cubit;
  PostRpeAdaptationCubit? _adaptationCubit;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    if (args == null) {
      // Deep-link or stale navigation: no extras to persist against. Bounce to
      // Today on the next frame rather than silently writing a garbage row.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRouter.today);
      });
      return;
    }
    _cubit = RpeFeedbackCubit(
      dao: getIt<RpeFeedbackDao>(),
      sessionLogsDao: getIt.isRegistered<SessionLogsDao>()
          ? getIt<SessionLogsDao>()
          : null,
      args: args,
    );
    _adaptationCubit = PostRpeAdaptationCubit(
      useCase: getIt<UpdateBanditReward>(),
      armKey: args.armKey,
    );
  }

  @override
  void dispose() {
    _cubit?.close();
    _adaptationCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cubit = _cubit;

    if (cubit == null) {
      // Missing-args branch: render a transient surface; the post-frame
      // callback in initState routes us to Today.
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const SizedBox.shrink(),
      );
    }

    return PopScope(
      // Disable hardware back: RPE submission is single-tap and routes itself
      // to Today on success — letting the user pop back would either re-arm
      // the in-session route (which has already emitted isComplete) or escape
      // the post-session loop entirely.
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: BlocProvider.value(
            value: cubit,
            child: MultiBlocListener(
              listeners: [
                BlocListener<RpeFeedbackCubit, RpeFeedbackState>(
                  listenWhen: (previous, current) =>
                      current is RpeFeedbackSubmitted &&
                      previous is! RpeFeedbackSubmitted,
                  listener: (context, state) {
                    if (!context.mounted) return;
                    final submitted = state as RpeFeedbackSubmitted;
                    _adaptationCubit?.triggerUpdate(submitted.rpeValue);
                    final args = widget.args;
                    final summaryArgs = args == null
                        ? null
                        : MiniSummaryArgs(
                            rpeValue: submitted.rpeValue,
                            sessionType: args.armKey.split('_').first,
                            durationMinutes: args.durationMinutes,
                            abandoned: args.abandoned,
                            planId: args.planId,
                          );
                    unawaited(WearBridgeService.sendEndMessage());
                    context.go(AppRouter.sessionSummary, extra: summaryArgs);
                  },
                ),
                BlocListener<RpeFeedbackCubit, RpeFeedbackState>(
                  listenWhen: (previous, current) =>
                      current is RpeFeedbackError &&
                      previous is! RpeFeedbackError,
                  listener: (context, state) {
                    if (!context.mounted) return;
                    final error = state as RpeFeedbackError;
                    // The cubit is single-shot after error (D3), so the page
                    // cannot offer an in-place retry. Show the failure on the
                    // next surface and bounce out — losing this RPE row is the
                    // explicit cost of the spec-correct idempotency choice.
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      SnackBar(content: Text(error.failure.message)),
                    );
                    context.go(AppRouter.today);
                  },
                ),
              ],
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.rpePrompt,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<RpeFeedbackCubit, RpeFeedbackState>(
                        builder: (context, state) {
                          final selectedRpe = state is RpeFeedbackAnimating
                              ? state.rpe
                              : null;
                          return RPEInputWidget(
                            selectedRpe: selectedRpe,
                            semanticLabelBuilder: l10n.rpeSemanticLabel,
                            onRpeSelected: context
                                .read<RpeFeedbackCubit>()
                                .submit,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
