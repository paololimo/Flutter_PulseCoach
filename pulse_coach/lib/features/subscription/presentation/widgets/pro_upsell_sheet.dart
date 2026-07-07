import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/subscription/data/services/upsell_cooldown_service.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class ProUpsellSheet extends StatelessWidget {
  const ProUpsellSheet._({this.body});

  /// Optional context-specific body copy. When null, the generic
  /// (Progress-oriented) `proUpsellBody` is shown. The Social locked banner
  /// passes a friends/leaderboard-oriented string (E18R-4).
  final String? body;

  static void show(
    BuildContext context, {
    String? body,
    @visibleForTesting UpsellCooldownService? cooldownOverride,
  }) {
    final cooldown = cooldownOverride ?? getIt<UpsellCooldownService>();
    if (cooldown.isCoolingDown()) return;
    // 'Scopri Pro' pops `true` (positive intent — no cooldown). Every other
    // close path (non ora / scrim tap / swipe / back) resolves to non-true and
    // arms the cooldown, so the sheet does not re-nag for the rest of the day.
    showModalBottomSheet<bool>(
      context: context,
      builder: (_) => ProUpsellSheet._(body: body),
    ).then((intent) {
      if (intent != true) {
        cooldown.recordDismissal();
      } else if (context.mounted) {
        context.push(AppRouter.paywall);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: 'PulseCoach Pro',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                body ?? l10n.proUpsellBody,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: l10n.proUpsellNotNow,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.proUpsellNotNow),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: l10n.proUpsellDiscover,
                      child: FilledButton(
                        // Story 17.4 will wire the purchase flow.
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.proUpsellDiscover),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
