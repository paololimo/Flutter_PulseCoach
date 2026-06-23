import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/visibility_cubit.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class VisibilityTierSelector extends StatelessWidget {
  const VisibilityTierSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<VisibilityCubit, VisibilityTier>(
      builder: (context, selected) {
        // Disable interaction while an update is in flight to avoid firing
        // concurrent PATCHes whose responses could arrive out of order.
        final isUpdating = context.select<SocialProfileBloc, bool>(
          (bloc) => bloc.state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          ),
        );
        return SegmentedButton<VisibilityTier>(
          segments: [
            ButtonSegment(
              value: VisibilityTier.private,
              label: Text(l10n.visibilityTierPrivate),
            ),
            ButtonSegment(
              value: VisibilityTier.friendsOnly,
              label: Text(l10n.visibilityTierFriendsOnly),
            ),
          ],
          selected: {selected},
          onSelectionChanged: isUpdating
              ? null
              : (Set<VisibilityTier> newSelection) {
                  final tier = newSelection.first;
                  if (tier == selected) return;
                  context.read<VisibilityCubit>().select(tier);
                  context
                      .read<SocialProfileBloc>()
                      .add(VisibilityTierUpdateRequested(tier));
                },
        );
      },
    );
  }
}
