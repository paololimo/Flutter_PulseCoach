import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_state.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_state.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/completion_rate_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/minutes_per_week_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/rpe_trend_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/session_history_tile.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/session_type_breakdown_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/weekly_goal_indicator.dart';
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
      ],
      child: const DefaultTabController(length: 2, child: _ProgressView()),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView();

  @override
  Widget build(BuildContext context) {
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ShimmerPlaceholder(height: 56),
            );
          },
        ),
        const TabBar(
          tabs: [
            Tab(text: 'Cronologia'),
            Tab(text: 'Grafici'),
          ],
        ),
        const Expanded(
          child: TabBarView(children: [_HistoryTab(), _ChartsTab()]),
        ),
      ],
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
        'Nessuna sessione ancora. Inizia la tua prima oggi!',
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
        'Impossibile caricare la cronologia',
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
        'Completa più sessioni per vedere i tuoi progressi',
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
        'Impossibile caricare i grafici',
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
        'Nessun dato RPE ancora disponibile',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ChartsDashboard extends StatelessWidget {
  const _ChartsDashboard({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Minuti per settimana', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: MinutesPerWeekChart(minutesPerWeek: stats.minutesPerWeek),
        ),
        const SizedBox(height: 24),
        Text('Tasso di completamento', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: CompletionRateChart(
            completedCount: stats.completedCount,
            abandonedCount: stats.abandonedCount,
          ),
        ),
        const SizedBox(height: 24),
        Text('Andamento RPE', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: stats.rpeTrend.isEmpty
              ? const _RpeEmptyState()
              : RpeTrendChart(rpeTrend: stats.rpeTrend),
        ),
        const SizedBox(height: 24),
        Text('Tipologie di sessione', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: SessionTypeBreakdownChart(
            sessionTypeCounts: stats.sessionTypeCounts,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
