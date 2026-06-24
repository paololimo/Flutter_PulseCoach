import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider;
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_bloc.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_event.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_state.dart';
import 'package:pulse_coach/features/social/feed/presentation/widgets/activity_feed_card.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeedView();
  }
}

class _FeedView extends StatelessWidget {
  const _FeedView();

  bool _isOwn(String ownerId) {
    try {
      return getIt<SupabaseClientProvider>().client.auth.currentUser?.id ==
          ownerId;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<FeedBloc, FeedState>(
      listener: (context, state) {
        state.whenOrNull(
          // Show a localized generic message — never surface the raw
          // exception string (`failure.message` interpolates `$e`) to the user.
          error: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.socialGenericError)),
            );
          },
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () => const _FeedShimmer(),
          loading: () => const _FeedShimmer(),
          loaded: (entries, reactingIds) {
            if (entries.isEmpty) {
              return Center(child: Text(l10n.feedEmptyState));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<FeedBloc>().add(const FeedLoaded());
              },
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  final isOwn = _isOwn(entry.ownerId);
                  return ActivityFeedCard(
                    key: ValueKey(entry.id),
                    entry: entry,
                    isOwn: isOwn,
                    isReacting: reactingIds.contains(entry.id),
                    onReact: () => context.read<FeedBloc>().add(
                          FeedReactionSent(entry.id),
                        ),
                    onRevoke: isOwn
                        ? () => _confirmRevoke(context, entry.id, l10n)
                        : null,
                  );
                },
              ),
            );
          },
          error: (_) => const _FeedShimmer(),
        );
      },
    );
  }

  void _confirmRevoke(
      BuildContext context, String feedEntryId, AppLocalizations l10n) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.feedRevokeDialogTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.feedRevokeDialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.feedRevokeDialogConfirm),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<FeedBloc>().add(FeedEntryRevoked(feedEntryId));
      }
    });
  }
}

class _FeedShimmer extends StatelessWidget {
  const _FeedShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ShimmerPlaceholder(height: 80),
        ),
      ),
    );
  }
}
