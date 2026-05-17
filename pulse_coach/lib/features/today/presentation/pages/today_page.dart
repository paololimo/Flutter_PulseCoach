import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
import 'package:pulse_coach/features/today/presentation/widgets/compact_session_card.dart';
import 'package:pulse_coach/features/today/presentation/widgets/completed_session_card.dart';
import 'package:pulse_coach/features/today/presentation/widgets/completion_ring.dart';
import 'package:pulse_coach/features/today/presentation/widgets/hero_session_card.dart';
import 'package:pulse_coach/features/today/presentation/widgets/state_indicator.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DailyPlanBloc, DailyPlanState>(
      listenWhen: (previous, current) {
        if (current is! DailyPlanLoaded) return false;
        if (previous is! DailyPlanLoaded) return true;
        // planDbId is nullable: null means "not persisted" (e.g. fresh-install
        // race or a future ephemeral preview). Two consecutive nulls still
        // fire — we cannot tell them apart and the cubit's reset is cheap.
        if (previous.planDbId == null || current.planDbId == null) return true;
        return previous.planDbId != current.planDbId;
      },
      listener: (context, state) {
        if (state case DailyPlanLoaded(:final plan, :final planDbId)) {
          context
              .read<TodaySessionCubit>()
              .planLoaded(plan.sessions.length, planDbId)
              .ignore();
        }
      },
      builder: (context, state) {
        return switch (state) {
          DailyPlanInitial() || DailyPlanLoading() => _buildShimmer(context),
          final DailyPlanLoaded loaded =>
            BlocBuilder<TodaySessionCubit, TodaySessionState>(
              builder: (context, sessionState) =>
                  _buildLoaded(context, loaded, sessionState),
            ),
          final DailyPlanError error => _buildError(context, error),
        };
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShimmerPlaceholder(height: 80),
          SizedBox(height: 16),
          ShimmerPlaceholder(height: 180),
          SizedBox(height: 16),
          ShimmerPlaceholder(height: 56),
          SizedBox(height: 8),
          ShimmerPlaceholder(height: 56),
        ],
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    DailyPlanLoaded loaded,
    TodaySessionState sessionState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final plan = loaded.plan;
    final sessions = plan.sessions;
    final total = sessions.length;
    final completedCount = sessionState.completedCount.clamp(0, total);
    final heroIndex = total == 0
        ? 0
        : sessionState.heroIndex.clamp(0, total - 1);
    final allDone = total == 0 || completedCount >= total;

    final completedEntries = <_SessionEntry>[
      for (var i = 0; i < total; i++)
        if (sessionState.isCompleted(i))
          _SessionEntry(index: i, session: sessions[i]),
    ];
    final upcomingEntries = <_SessionEntry>[
      for (var i = 0; i < total; i++)
        if (!sessionState.isCompleted(i) && i != heroIndex)
          _SessionEntry(index: i, session: sessions[i]),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StateIndicator(state: loaded.behavioralState),
                        ),
                        const SizedBox(width: 12),
                        CompletionRing(completed: completedCount, total: total),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final entry in completedEntries) ...[
                      CompletedSessionCard(session: entry.session),
                      const SizedBox(height: 8),
                    ],
                    if (allDone)
                      const Expanded(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: _AllDoneWidget(key: ValueKey('all-done')),
                          ),
                        ),
                      )
                    else ...[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _HeroZone(
                          key: ValueKey(
                            'hero-${sessions[heroIndex].sessionType}-$heroIndex',
                          ),
                          plan: plan,
                          heroIndex: heroIndex,
                          onRegenerate: () {
                            final bloc = context.read<DailyPlanBloc>();
                            // Guard against rapid double-taps while
                            // AnimatedSwitcher is cross-fading the old hero
                            // card out.
                            if (bloc.state is DailyPlanLoaded) {
                              bloc.add(DailyPlanRegenerateRequested());
                            }
                          },
                        ),
                      ),
                      if (upcomingEntries.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.comingUpHeader,
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(
                              context,
                            ).extension<PulseCoachTheme>()!.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final entry in upcomingEntries) ...[
                          CompactSessionCard(
                            session: entry.session,
                            heroTag:
                                'session-compact-${entry.session.sessionType}-${entry.index}',
                            onTap: () => context
                                .read<TodaySessionCubit>()
                                .swapHero(entry.index),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, DailyPlanError error) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 48,
            color: pulseTheme.tertiary,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.errorLoadingPlan,
            style: AppTextStyles.bodySmall.copyWith(
              color: pulseTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroZone extends StatelessWidget {
  final DailyPlan plan;
  final int heroIndex;
  final VoidCallback? onRegenerate;

  const _HeroZone({
    super.key,
    required this.plan,
    required this.heroIndex,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    final session = plan.sessions[heroIndex];
    return HeroSessionCard(
      session: session,
      heroTag: 'session-hero-${session.sessionType}-$heroIndex',
      onStart: () => context.go(AppRouter.sessionActive, extra: session),
      onRegenerate: onRegenerate,
    );
  }
}

class _AllDoneWidget extends StatelessWidget {
  const _AllDoneWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: pulseTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(l10n.allDoneTitle, style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text(
          l10n.allDoneBody,
          style: AppTextStyles.bodySmall.copyWith(
            color: pulseTheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SessionEntry {
  final int index;
  final PlannedSession session;

  const _SessionEntry({required this.index, required this.session});
}
