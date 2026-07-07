import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/paywall_cubit.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaywallCubit>()..loadOfferings(),
      child: BlocListener<SubscriptionBloc, SubscriptionState>(
        // Fire only on a fresh action result (loading -> loaded). The bloc's
        // initial checkRequested resolves before this page mounts, so a
        // loading -> loaded transition here always follows a purchase/restore.
        listenWhen: (previous, current) =>
            previous.maybeWhen(loading: () => true, orElse: () => false) &&
            current.maybeWhen(loaded: (_) => true, orElse: () => false),
        listener: (context, state) {
          final isPro = state.maybeWhen(
            loaded: (tier) => tier == SubscriptionTier.pro,
            orElse: () => false,
          );
          if (isPro) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          } else {
            // Purchase/restore completed without granting Pro (e.g. nothing to
            // restore, or entitlement not yet active): keep the user on the
            // paywall and tell them, rather than silently dismissing it.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.paywallNoActiveSub),
              ),
            );
          }
        },
        child: BlocListener<SubscriptionBloc, SubscriptionState>(
          listenWhen: (_, current) =>
              current.maybeWhen(error: (_) => true, orElse: () => false),
          listener: (context, state) {
            state.maybeWhen(
              // Show a localized generic message rather than the raw
              // failure.message, which may be a store SDK exception in another
              // language (Epic-17 finding).
              error: (failure) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.subActionError),
                ),
              ),
              orElse: () {},
            );
          },
          child: const _PaywallBody(),
        ),
      ),
    );
  }
}

class _PaywallBody extends StatelessWidget {
  const _PaywallBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PulseCoach Pro')),
      body: BlocBuilder<PaywallCubit, PaywallState>(
        builder: (context, state) {
          return state.when(
            loading: () => const _PaywallShimmer(),
            error: (msg) => const _PaywallError(),
            loaded: (offers) => _PaywallLoaded(offers: offers),
          );
        },
      ),
    );
  }
}

class _PaywallError extends StatelessWidget {
  const _PaywallError();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.paywallLoadError, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<PaywallCubit>().loadOfferings(),
              child: Text(l10n.paywallRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallShimmer extends StatelessWidget {
  const _PaywallShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        ShimmerPlaceholder(height: 32),
        SizedBox(height: 8),
        ShimmerPlaceholder(height: 20),
        SizedBox(height: 24),
        ShimmerPlaceholder(height: 72),
        SizedBox(height: 12),
        ShimmerPlaceholder(height: 72),
        SizedBox(height: 16),
        ShimmerPlaceholder(height: 40),
      ],
    );
  }
}

class _PaywallLoaded extends StatelessWidget {
  final List<ProOffer> offers;
  const _PaywallLoaded({required this.offers});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, subState) {
        final isLoading = subState.maybeWhen(
          loading: () => true,
          orElse: () => false,
        );
        final l10n = AppLocalizations.of(context)!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.paywallHeadline,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.paywallSubhead,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...offers.map(
              (offer) => _PlanCard(
                offer: offer,
                isLoading: isLoading,
                onPurchase: () => context.read<SubscriptionBloc>().add(
                  SubscriptionEvent.purchaseRequested(
                    packageId: offer.packageId,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => context.read<SubscriptionBloc>().add(
                      const SubscriptionEvent.restoreRequested(),
                    ),
              child: Text(l10n.paywallRestore),
            ),
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ProOffer offer;
  final bool isLoading;
  final VoidCallback onPurchase;
  const _PlanCard({
    required this.offer,
    required this.isLoading,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Pro ${offer.period}'),
        subtitle: Text(offer.priceString),
        trailing: FilledButton(
          onPressed: isLoading ? null : onPurchase,
          child: Text(AppLocalizations.of(context)!.paywallPurchase),
        ),
      ),
    );
  }
}
