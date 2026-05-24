import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_state.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/session_history_tile.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProgressCubit>(
      create: (_) => getIt<ProgressCubit>()..load(),
      child: const _ProgressView(),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, ProgressState>(
      builder: (context, state) => switch (state) {
        ProgressInitial() ||
        ProgressHistoryLoading() => const _HistoryShimmer(),
        ProgressHistoryLoaded(:final entries) when entries.isEmpty =>
          const _EmptyState(),
        ProgressHistoryLoaded(:final entries) => _HistoryList(entries: entries),
        ProgressHistoryError() => const _ErrorState(),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState();

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
