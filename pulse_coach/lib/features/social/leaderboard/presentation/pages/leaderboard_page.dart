import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_event.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_state.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/widgets/leaderboard_row.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<LeaderboardBloc>().add(const LeaderboardLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<LeaderboardBloc, LeaderboardState>(
      listener: (context, state) {
        state.whenOrNull(
          error: (_) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.socialGenericError)),
          ),
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () => const _LeaderboardShimmer(),
          loading: () => const _LeaderboardShimmer(),
          loaded: (entries, isFrozen) {
            if (entries.isEmpty) {
              return Center(child: Text(l10n.leaderboardEmpty));
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<LeaderboardBloc>().add(const LeaderboardLoaded()),
              child: ListView(
                children: [
                  for (final e in entries)
                    LeaderboardRow(key: ValueKey(e.userId), entry: e),
                ],
              ),
            );
          },
          error: (_) => const _LeaderboardShimmer(),
        );
      },
    );
  }
}

class _LeaderboardShimmer extends StatelessWidget {
  const _LeaderboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ShimmerPlaceholder(height: 72),
        ),
      ),
    );
  }
}
