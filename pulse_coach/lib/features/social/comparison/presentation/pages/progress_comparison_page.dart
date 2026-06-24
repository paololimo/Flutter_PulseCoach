import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_bloc.dart';
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_event.dart';
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_state.dart';
import 'package:pulse_coach/features/social/comparison/presentation/widgets/comparison_row.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

class ProgressComparisonPage extends StatelessWidget {
  const ProgressComparisonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ComparisonView();
  }
}

class _ComparisonView extends StatefulWidget {
  const _ComparisonView();

  @override
  State<_ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<_ComparisonView> {
  @override
  void initState() {
    super.initState();
    // Dispatch once at init — ownHandle sourced from SocialProfileBloc above in tree
    final profileState = context.read<SocialProfileBloc>().state;
    final ownHandle =
        profileState.whenOrNull(loaded: (p) => p.displayHandle) ?? '';
    context
        .read<ProgressComparisonBloc>()
        .add(ProgressComparisonLoaded(ownHandle));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<SocialProfileBloc, SocialProfileState>(
      // Re-dispatch once the profile resolves: initState fires before
      // SocialProfileBloc is loaded, so the first own-handle is empty.
      listenWhen: (_, curr) => curr.whenOrNull(loaded: (_) => true) ?? false,
      listener: (context, profileState) {
        final ownHandle =
            profileState.whenOrNull(loaded: (p) => p.displayHandle) ?? '';
        context
            .read<ProgressComparisonBloc>()
            .add(ProgressComparisonLoaded(ownHandle));
      },
      child: BlocConsumer<ProgressComparisonBloc, ProgressComparisonState>(
        listener: (context, state) {
        state.whenOrNull(
          error: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.socialGenericError)),
            );
          },
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () => const _ComparisonShimmer(),
          loading: () => const _ComparisonShimmer(),
          loaded: (ownEntry, friendEntries) {
            return RefreshIndicator(
              onRefresh: () async {
                final profileState =
                    context.read<SocialProfileBloc>().state;
                final ownHandle =
                    profileState.whenOrNull(loaded: (p) => p.displayHandle) ??
                        '';
                context
                    .read<ProgressComparisonBloc>()
                    .add(ProgressComparisonLoaded(ownHandle));
              },
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      l10n.comparisonThisWeek,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  ComparisonRow(entry: ownEntry),
                  if (friendEntries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        l10n.comparisonEmptyFriends,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    ...friendEntries.map(
                      (e) => ComparisonRow(
                        key: ValueKey(e.displayHandle),
                        entry: e,
                      ),
                    ),
                ],
              ),
            );
          },
          error: (_) => const _ComparisonShimmer(),
        );
      },
      ),
    );
  }
}

class _ComparisonShimmer extends StatelessWidget {
  const _ComparisonShimmer();

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
