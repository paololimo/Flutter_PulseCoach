import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_bloc.dart';
import 'package:pulse_coach/features/social/comparison/presentation/pages/progress_comparison_page.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_bloc.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_event.dart';
import 'package:pulse_coach/features/social/feed/presentation/pages/feed_page.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/friend_item.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/pending_requests.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/friends_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/friends_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/friends_state.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';
import 'package:pulse_coach/features/social/friends/presentation/widgets/friend_row.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/pages/leaderboard_page.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session_start_args.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_creation_cubit.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_join_cubit.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/features/subscription/presentation/widgets/pro_upsell_sheet.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FriendsBloc>(
          create: (_) => getIt<FriendsBloc>()..add(const FriendsLoaded()),
        ),
        BlocProvider<SocialProfileBloc>(
          create: (_) =>
              getIt<SocialProfileBloc>()..add(const SocialProfileLoaded()),
        ),
        BlocProvider<FeedBloc>(
          create: (_) => getIt<FeedBloc>()..add(const FeedLoaded()),
        ),
        BlocProvider<ProgressComparisonBloc>(
          create: (_) => getIt<ProgressComparisonBloc>(),
          // Event is dispatched from _ComparisonViewState.initState — NOT here
        ),
        BlocProvider<LeaderboardBloc>(
          create: (_) => getIt<LeaderboardBloc>(),
          // Event dispatched from LeaderboardPage's own initState, same
          // convention as ProgressComparisonBloc immediately above.
        ),
        BlocProvider<SharedSessionCreationCubit>(
          create: (_) => getIt<SharedSessionCreationCubit>(),
        ),
        BlocProvider<SharedSessionJoinCubit>(
          create: (_) => getIt<SharedSessionJoinCubit>(),
        ),
      ],
      child: const _SocialView(),
    );
  }
}

class _SocialView extends StatefulWidget {
  const _SocialView();

  @override
  State<_SocialView> createState() => _SocialViewState();
}

class _SocialViewState extends State<_SocialView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, subState) {
        final tier = subState.whenOrNull(loaded: (t) => t);

        if (tier == null) {
          return const _FriendsShimmer();
        }

        if (tier != SubscriptionTier.pro) {
          return _LockedBanner(
            onTap: () => ProUpsellSheet.show(context),
          );
        }

        final l10n = AppLocalizations.of(context)!;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.socialScreenTitle),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.friendsScreenTitle),
                Tab(text: l10n.feedScreenTitle),
                Tab(text: l10n.comparisonScreenTitle),
                Tab(text: l10n.leaderboardScreenTitle),
              ],
            ),
          ),
          body: MultiBlocListener(
            listeners: [
              BlocListener<SharedSessionCreationCubit,
                  SharedSessionCreationState>(
                listener: (context, state) {
                  state.mapOrNull(
                    created: (s) {
                      final authState = context.read<AuthBloc>().state;
                      final socialState =
                          context.read<SocialProfileBloc>().state;
                      final userId = authState.mapOrNull(
                        authenticated: (a) => a.user.id,
                      );
                      if (userId == null) return;
                      final displayHandle = socialState.mapOrNull(
                        loaded: (p) => p.profile.displayHandle,
                      );
                      context.push(
                        AppRouter.sharedSessionLobby,
                        extra: SharedSessionStartArgs(
                          sessionId: s.sessionId,
                          isHost: true,
                          userId: userId,
                          displayHandle: displayHandle,
                          steps: const [],
                          joinCode: s.joinCode,
                        ),
                      );
                    },
                    error: (_) {
                      final l10n = AppLocalizations.of(context)!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(l10n.sharedSessionCreateError)),
                      );
                    },
                  );
                },
              ),
              BlocListener<SharedSessionJoinCubit, SharedSessionJoinState>(
                listener: (context, joinState) {
                  joinState.mapOrNull(
                    joined: (s) {
                      final authState = context.read<AuthBloc>().state;
                      final socialState =
                          context.read<SocialProfileBloc>().state;
                      final userId = authState.mapOrNull(
                        authenticated: (a) => a.user.id,
                      );
                      if (userId == null) return;
                      final displayHandle = socialState.mapOrNull(
                        loaded: (p) => p.profile.displayHandle,
                      );
                      context.push(
                        AppRouter.sharedSessionLobby,
                        extra: SharedSessionStartArgs(
                          sessionId: s.sessionId,
                          isHost: false,
                          userId: userId,
                          displayHandle: displayHandle,
                          steps: const [],
                          joinCode: null,
                        ),
                      );
                      context.read<SharedSessionJoinCubit>().reset();
                    },
                    sessionAlreadyStarted: (_) {
                      _showSessionAlreadyStartedDialog(context);
                      context.read<SharedSessionJoinCubit>().reset();
                    },
                    error: (_) {
                      final l10n = AppLocalizations.of(context)!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        // E18R-2 / E18R-CB2: localized string — never failure.message
                        SnackBar(
                            content: Text(l10n.sharedSessionJoinError)),
                      );
                      context.read<SharedSessionJoinCubit>().reset();
                    },
                  );
                },
              ),
            ],
            child: TabBarView(
              controller: _tabController,
              children: [
                _FriendsTab(searchController: _searchController),
                const FeedPage(),
                const ProgressComparisonPage(),
                const LeaderboardPage(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSessionAlreadyStartedDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.sharedSessionAlreadyStarted),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  final TextEditingController searchController;

  const _FriendsTab({required this.searchController});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendsBloc, FriendsState>(
      listener: (context, state) {
        state.whenOrNull(
          // Show a localized generic message — never surface the raw
          // exception string (`failure.message` interpolates `$e`) to the user.
          error: (_) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.socialGenericError)),
            );
          },
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () => const _FriendsShimmer(),
          loading: () => const _FriendsShimmer(),
          loaded: (friends, pendingRequests, searchResult, requestSent) =>
              _FriendsList(
            searchController: searchController,
            friends: friends,
            pendingRequests: pendingRequests,
            searchResult: searchResult,
            requestSent: requestSent,
          ),
          error: (_) => const _FriendsShimmer(),
        );
      },
    );
  }
}

class _FriendsList extends StatelessWidget {
  final TextEditingController searchController;
  final List<FriendItem> friends;
  final PendingRequests pendingRequests;
  final SocialProfile? searchResult;
  final bool requestSent;

  const _FriendsList({
    required this.searchController,
    required this.friends,
    required this.pendingRequests,
    this.searchResult,
    required this.requestSent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final alreadyFriend = searchResult != null &&
        friends.any((f) => f.userId == searchResult!.userId);
    final alreadySent = searchResult != null &&
        pendingRequests.sent.any((r) => r.userId == searchResult!.userId);
    final alreadyReceived = searchResult != null &&
        pendingRequests.received.any((r) => r.userId == searchResult!.userId);
    final canAdd = searchResult != null &&
        !alreadyFriend &&
        !alreadySent &&
        !alreadyReceived;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: l10n.friendsSearchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      context.read<FriendsBloc>().add(
                            FriendSearchRequested(value.trim()),
                          );
                    }
                  },
                  textInputAction: TextInputAction.search,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.qr_code),
            label: Text(l10n.friendsShowQrButton),
            onPressed: () => context.push(AppRouter.socialQr),
          ),
          const SizedBox(height: 8),
          BlocBuilder<SharedSessionCreationCubit, SharedSessionCreationState>(
            builder: (context, creationState) {
              final isCreating = creationState.mapOrNull(creating: (_) => true) ?? false;
              return OutlinedButton.icon(
                icon: isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.group_add),
                label: Text(l10n.sharedSessionCreateButton),
                onPressed: isCreating
                    ? null
                    : () {
                        final authState = context.read<AuthBloc>().state;
                        final userId = authState.mapOrNull(
                          authenticated: (a) => a.user.id,
                        );
                        if (userId != null) {
                          context
                              .read<SharedSessionCreationCubit>()
                              .create(hostUserId: userId);
                        }
                      },
              );
            },
          ),
          const SizedBox(height: 8),
          BlocBuilder<SharedSessionJoinCubit, SharedSessionJoinState>(
            builder: (context, joinState) {
              final isJoining =
                  joinState.mapOrNull(joining: (_) => true) ?? false;
              return OutlinedButton.icon(
                icon: isJoining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(l10n.sharedSessionJoinButton),
                onPressed: isJoining
                    ? null
                    : () => _showJoinDialog(context, l10n),
              );
            },
          ),
          if (searchResult != null) ...[
            const Divider(height: 24),
            Text(
              l10n.friendsSearchResultLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (alreadyFriend)
              ListTile(title: Text(l10n.friendsAlreadyFriend))
            else if (alreadySent)
              FriendRow(
                displayHandle: searchResult!.displayHandle ?? '',
                variant: FriendRowVariant.searchResult,
                requestSent: true,
              )
            else if (alreadyReceived)
              ListTile(title: Text(l10n.friendsAlreadyReceivedRequest))
            else
              FriendRow(
                displayHandle: searchResult!.displayHandle ?? '',
                variant: FriendRowVariant.searchResult,
                requestSent: requestSent || !canAdd,
                onPrimaryAction: canAdd && !requestSent
                    ? () => context.read<FriendsBloc>().add(
                          FriendRequestSent(searchResult!.userId),
                        )
                    : null,
              ),
          ] else if (searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(child: Text(l10n.friendsNoUserFound)),
          ],
          if (pendingRequests.received.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              l10n.friendsIncomingSection,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final req in pendingRequests.received)
              FriendRow(
                displayHandle: req.displayHandle,
                variant: FriendRowVariant.receivedRequest,
                onPrimaryAction: () => context.read<FriendsBloc>().add(
                      FriendRequestAccepted(req.friendshipId),
                    ),
                onSecondaryAction: () => context.read<FriendsBloc>().add(
                      FriendRequestDeclined(req.friendshipId),
                    ),
              ),
          ],
          if (pendingRequests.sent.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              l10n.friendsOutgoingSection,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final req in pendingRequests.sent)
              FriendRow(
                displayHandle: req.displayHandle,
                variant: FriendRowVariant.sentRequest,
              ),
          ],
          if (friends.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              l10n.friendsListSection,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final friend in friends)
              FriendRow(
                displayHandle: friend.displayHandle,
                variant: FriendRowVariant.friend,
                onPrimaryAction: () => _confirmRemove(context, friend, l10n),
              ),
          ],
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sharedSessionJoinDialogTitle),
        content: TextField(
          controller: controller,
          decoration:
              InputDecoration(hintText: l10n.sharedSessionJoinDialogHint),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.sharedSessionCancelDialogKeep),
          ),
          FilledButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              final authState = context.read<AuthBloc>().state;
              final userId = authState.mapOrNull(
                authenticated: (a) => a.user.id,
              );
              if (userId == null) return;
              final joinCubit = context.read<SharedSessionJoinCubit>();
              // Dismiss the keyboard, then defer the join (and the lobby
              // navigation it triggers) until after the dialog has fully popped.
              // Navigating while the autofocus TextField's IME focus is still
              // tearing down trips a `_dependents.isEmpty` framework assertion
              // (red screen) on the joiner.
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(ctx).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                joinCubit.join(joinCode: code, userId: userId);
              });
            },
            child: Text(l10n.sharedSessionJoinDialogConfirm),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _confirmRemove(
      BuildContext context, FriendItem friend, AppLocalizations l10n) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.friendsRemoveDialogTitle),
        content: Text(l10n.friendsRemoveDialogBody(friend.displayHandle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.friendsRemoveDialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.friendsRemoveDialogConfirm),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<FriendsBloc>().add(FriendRemoved(friend.friendshipId));
      }
    });
  }
}

class _LockedBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _LockedBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.friendsLockedBannerBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTap,
              child: Text(l10n.friendsDiscoverProButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsShimmer extends StatelessWidget {
  const _FriendsShimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const ShimmerPlaceholder(height: 56),
          const SizedBox(height: 12),
          ...List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerPlaceholder(height: 60),
            ),
          ),
        ],
      ),
    );
  }
}
