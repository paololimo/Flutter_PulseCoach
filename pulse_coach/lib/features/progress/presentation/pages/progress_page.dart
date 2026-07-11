import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_gating_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_gating_state.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_state.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_state.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/completion_rate_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/minutes_per_week_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/rpe_trend_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/session_history_tile.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/session_type_breakdown_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/weekly_goal_indicator.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/features/subscription/presentation/widgets/pro_upsell_sheet.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProgressCubit>(
          create: (_) => getIt<ProgressCubit>()..load(),
        ),
        BlocProvider<ProgressStatsCubit>(
          create: (_) => getIt<ProgressStatsCubit>()..load(),
        ),
        BlocProvider<ProgressGatingCubit>(
          create: (_) => getIt<ProgressGatingCubit>()..load(),
        ),
      ],
      child: const _ProgressView(),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressGatingCubit, ProgressGatingState>(
      builder: (context, gatingState) {
        if (gatingState is ProgressGatingInitial) {
          // Show shimmer while gating resolves — never flash locked content.
          return const _ProgressLoadingShimmer();
        }

        final isGrandfathered = gatingState is ProgressGatingLoaded
            ? gatingState.isGrandfathered
            : false;

        return BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, subState) {
            final tier = subState.whenOrNull(loaded: (t) => t);
            final showFull = isGrandfathered || tier == SubscriptionTier.pro;
            // While entitlement is still resolving, don't flash the locked
            // banner at a (possibly Pro) user — show shimmer until the
            // SubscriptionBloc settles on loaded/error.
            final subscriptionResolving = subState.maybeWhen(
              initial: () => true,
              loading: () => true,
              orElse: () => false,
            );

            return Column(
              children: [
                BlocBuilder<ProgressStatsCubit, ProgressStatsState>(
                  builder: (context, state) {
                    if (state is ProgressStatsLoaded) {
                      return WeeklyGoalIndicator(
                        completedThisWeek: state.stats.completedThisWeek,
                        weeklyTarget: state.stats.weeklyTarget,
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: ShimmerPlaceholder(height: 56),
                    );
                  },
                ),
                if (showFull)
                  const Expanded(child: _FullProgressContent())
                else if (subscriptionResolving)
                  const _ProgressLoadingShimmer()
                else
                  _ProgressLockedBanner(
                    onTap: () => ProUpsellSheet.show(context),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FullProgressContent extends StatelessWidget {
  const _FullProgressContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.progressTabHistory),
              Tab(text: l10n.progressTabCharts),
            ],
          ),
          const Expanded(
            child: TabBarView(children: [_HistoryTab(), _ChartsTab()]),
          ),
        ],
      ),
    );
  }
}

class _ProgressLoadingShimmer extends StatelessWidget {
  const _ProgressLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ShimmerPlaceholder(height: 56),
    );
  }
}

class _ProgressLockedBanner extends StatelessWidget {
  const _ProgressLockedBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          AppLocalizations.of(context)!.progressLockedPro,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, ProgressState>(
      builder: (context, state) => switch (state) {
        ProgressInitial() ||
        ProgressHistoryLoading() => const _HistoryShimmer(),
        ProgressHistoryLoaded(:final entries) when entries.isEmpty =>
          const _EmptyState(),
        ProgressHistoryLoaded(:final entries) => _HistoryList(entries: entries),
        ProgressHistoryError() => const _HistoryErrorState(),
      },
    );
  }
}

class _HistoryShimmer extends StatelessWidget {
  const _HistoryShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: const [
        ShimmerPlaceholder(height: 72),
        SizedBox(height: 8),
        ShimmerPlaceholder(height: 72),
        SizedBox(height: 8),
        ShimmerPlaceholder(height: 72),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.progressHistoryEmpty,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries});

  final List<SessionHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          SessionHistoryTile(entry: entries[index]),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.progressHistoryError,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _ChartsTab extends StatelessWidget {
  const _ChartsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressStatsCubit, ProgressStatsState>(
      builder: (context, state) => switch (state) {
        ProgressStatsInitial() ||
        ProgressStatsLoading() => const _ChartsShimmer(),
        ProgressStatsLoaded(:final stats)
            when stats.completedCount + stats.abandonedCount < 3 =>
          const _InsufficientDataState(),
        ProgressStatsLoaded(:final stats) => _ChartsDashboard(stats: stats),
        ProgressStatsError() => const _ChartsErrorState(),
      },
    );
  }
}

class _ChartsShimmer extends StatelessWidget {
  const _ChartsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ShimmerPlaceholder(height: 200),
        SizedBox(height: 24),
        ShimmerPlaceholder(height: 200),
        SizedBox(height: 24),
        ShimmerPlaceholder(height: 200),
      ],
    );
  }
}

class _InsufficientDataState extends StatelessWidget {
  const _InsufficientDataState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.progressInsufficientData,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ChartsErrorState extends StatelessWidget {
  const _ChartsErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.progressChartsError,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _RpeEmptyState extends StatelessWidget {
  const _RpeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.progressRpeEmpty,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Width (logical px) at which the charts dashboard switches from a single
/// scrolling column (phone / tablet portrait) to a two-column grid. Matches
/// Material's "expanded" breakpoint and sits above the default test surface
/// (800) so narrow layouts keep their single-column behaviour.
const double _chartsGridBreakpoint = 840;

class _ChartsDashboard extends StatelessWidget {
  const _ChartsDashboard({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = <Widget>[
      _ChartCard(
        title: l10n.progressChartMinutesPerWeek,
        child: MinutesPerWeekChart(minutesPerWeek: stats.minutesPerWeek),
      ),
      _ChartCard(
        title: l10n.progressChartCompletionRate,
        child: CompletionRateChart(
          completedCount: stats.completedCount,
          abandonedCount: stats.abandonedCount,
        ),
      ),
      _ChartCard(
        title: l10n.progressChartRpeTrend,
        child: stats.rpeTrend.isEmpty
            ? const _RpeEmptyState()
            : RpeTrendChart(rpeTrend: stats.rpeTrend),
      ),
      _ChartCard(
        title: l10n.progressChartSessionTypes,
        child: SessionTypeBreakdownChart(
          sessionTypeCounts: stats.sessionTypeCounts,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _chartsGridBreakpoint) {
          // Phone / tablet-portrait: single scrolling column.
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 24),
            itemBuilder: (context, index) => cards[index],
          );
        }

        // Wide tablet: two-column grid so charts use the horizontal space
        // instead of stretching edge to edge.
        final cardWidth = (constraints.maxWidth - 32 - 16) / 2;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 24,
            children: [
              for (final card in cards)
                SizedBox(width: cardWidth, child: card),
            ],
          ),
        );
      },
    );
  }
}

/// A titled, fixed-height chart tile shared by the single-column and grid
/// layouts of the charts dashboard.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(height: 200, child: child),
      ],
    );
  }
}
