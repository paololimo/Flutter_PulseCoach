import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
import 'package:pulse_coach/features/session/presentation/bloc/mini_summary_cubit.dart';
import 'package:pulse_coach/features/session/presentation/bloc/mini_summary_state.dart';
import 'package:pulse_coach/features/social/feed/domain/usecases/share_feed_entry_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/features/today/presentation/widgets/completion_ring.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class MiniSummaryPage extends StatefulWidget {
  final MiniSummaryArgs? args;

  const MiniSummaryPage({this.args, super.key});

  @override
  State<MiniSummaryPage> createState() => _MiniSummaryPageState();
}

class _MiniSummaryPageState extends State<MiniSummaryPage>
    with SingleTickerProviderStateMixin {
  MiniSummaryCubit? _cubit;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  // Review patch #2: cache the last Loaded payload so the ring keeps showing
  // newCompletedCount/totalSessions during Fading/Done/Error rather than
  // snapping back to 0/0 via the BlocBuilder default arm.
  MiniSummaryLoaded? _lastLoaded;
  bool _shareEnabled = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0,
    );
    _fadeAnimation = _fadeController;
    final args = widget.args;
    if (args == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRouter.today);
      });
      return;
    }
    _cubit = MiniSummaryCubit(
      args: args,
      sessionLogsDao: getIt<SessionLogsDao>(),
      dailyPlansDao: getIt<DailyPlansDao>(),
    );
    unawaited(_cubit!.init());
  }

  @override
  void dispose() {
    _cubit?.close();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    final args = widget.args;
    if (cubit == null || args == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.shrink(),
      );
    }

    return PopScope(
      canPop: false,
      child: BlocProvider.value(
        value: cubit,
        child: BlocListener<MiniSummaryCubit, MiniSummaryState>(
          listenWhen: (_, current) =>
              current is MiniSummaryLoaded ||
              current is MiniSummaryFading ||
              current is MiniSummaryDone ||
              current is MiniSummaryError,
          listener: (context, state) {
            if (state is MiniSummaryLoaded) {
              _lastLoaded = state;
              return;
            }
            // Review patch #1: MiniSummaryError is terminal — short-circuit
            // to Today rather than trapping the user behind PopScope.
            if (state is MiniSummaryError && context.mounted) {
              context.go(AppRouter.today);
              return;
            }
            if (state is MiniSummaryFading) {
              final args = widget.args;
              if (_shareEnabled && args != null && !args.abandoned) {
                final useCase = getIt<ShareFeedEntryUseCase>();
                // Capture the messenger + localized text synchronously: the
                // summary route is torn down by the navigation below, so looking
                // them up off `context` after the async gap would target a
                // deactivated widget. The app-level ScaffoldMessenger survives
                // the route change, so the SnackBar still lands on Today.
                final messenger = ScaffoldMessenger.of(context);
                final failedMessage =
                    AppLocalizations.of(context)!.feedShareFailedError;
                unawaited(useCase(
                  sessionType: args.sessionType,
                  durationMinutes: args.durationMinutes,
                  completedAt: DateTime.now().toUtc(),
                ).then((result) {
                  result.fold(
                    (f) => messenger.showSnackBar(
                      SnackBar(content: Text(failedMessage)),
                    ),
                    (_) {},
                  );
                }));
              }
              final disableAnimations = MediaQuery.disableAnimationsOf(context);
              if (disableAnimations) {
                // Review patch #12: skip the 300ms invisible-page gap on
                // Reduce Motion — jump straight to Today.
                _fadeController.value = 0.0;
                if (context.mounted) context.go(AppRouter.today);
                return;
              }
              unawaited(_fadeController.reverse());
            }
            if (state is MiniSummaryDone && context.mounted) {
              context.go(AppRouter.today);
            }
          },
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildContent(context, args),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MiniSummaryArgs args) {
    final theme = Theme.of(context);
    final pulseTheme = theme.extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final sessionTypeName = _localizedSessionType(l10n, args.sessionType);
    final header = args.abandoned
        ? l10n.miniSummaryAbandonedHeader
        : l10n.miniSummaryHeader;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Semantics(
          label: l10n.miniSummarySemanticLabel(
            args.durationMinutes.toString(),
            args.rpeValue.toString(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  header,
                  style: AppTextStyles.h1.copyWith(
                    color: pulseTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                BlocBuilder<MiniSummaryCubit, MiniSummaryState>(
                  builder: (context, state) {
                    final loaded = state is MiniSummaryLoaded
                        ? state
                        : _lastLoaded;
                    if (loaded == null) {
                      return const CompletionRing(completed: 0, total: 0);
                    }
                    return _AnimatedRingTransition(
                      previousCount: loaded.previousCompletedCount,
                      newCount: loaded.newCompletedCount,
                      total: loaded.totalSessions,
                    );
                  },
                ),
                const SizedBox(height: 32),
                _StatRow(
                  label: sessionTypeName,
                  value: '${args.durationMinutes} min',
                ),
                const SizedBox(height: 12),
                _StatRow(
                  label: l10n.miniSummaryRpeLabel,
                  value: '${args.rpeValue}/10',
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    if (args.abandoned) return const SizedBox.shrink();
                    SubscriptionState? subState;
                    try {
                      subState = context.read<SubscriptionBloc>().state;
                    } catch (_) {
                      subState = null;
                    }
                    final isPro =
                        subState?.whenOrNull(loaded: (t) => t) ==
                            SubscriptionTier.pro;
                    if (!isPro) return const SizedBox.shrink();
                    return SwitchListTile(
                      title: Text(l10n.miniSummaryShareToggle),
                      value: _shareEnabled,
                      onChanged: (val) => setState(() => _shareEnabled = val),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.miniSummaryFeedback,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _localizedSessionType(AppLocalizations l10n, String type) {
    return switch (type) {
      'mobility' => l10n.sessionNameMobility,
      'cardio' => l10n.sessionNameCardio,
      'breathing' => l10n.sessionNameBreathing,
      _ => type,
    };
  }
}

class _AnimatedRingTransition extends StatefulWidget {
  final int previousCount;
  final int newCount;
  final int total;

  const _AnimatedRingTransition({
    required this.previousCount,
    required this.newCount,
    required this.total,
  });

  @override
  State<_AnimatedRingTransition> createState() =>
      _AnimatedRingTransitionState();
}

class _AnimatedRingTransitionState extends State<_AnimatedRingTransition> {
  late int _displayedCount;

  @override
  void initState() {
    super.initState();
    _displayedCount = widget.previousCount;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _displayedCount = widget.newCount);
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedRingTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.newCount != widget.newCount ||
        oldWidget.total != widget.total) {
      _displayedCount = widget.previousCount;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _displayedCount = widget.newCount);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      CompletionRing(completed: _displayedCount, total: widget.total);
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: AppTextStyles.h3)),
        const SizedBox(width: 16),
        Text(value, style: AppTextStyles.h3),
      ],
    );
  }
}
