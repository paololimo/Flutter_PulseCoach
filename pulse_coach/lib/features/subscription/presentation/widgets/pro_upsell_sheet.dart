import 'package:flutter/material.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/subscription/data/services/upsell_cooldown_service.dart';

class ProUpsellSheet extends StatelessWidget {
  const ProUpsellSheet._();

  static void show(
    BuildContext context, {
    @visibleForTesting UpsellCooldownService? cooldownOverride,
  }) {
    final cooldown = cooldownOverride ?? getIt<UpsellCooldownService>();
    if (cooldown.isCoolingDown()) return;
    // 'Scopri Pro' pops `true` (positive intent — no cooldown). Every other
    // close path (non ora / scrim tap / swipe / back) resolves to non-true and
    // arms the cooldown, so the sheet does not re-nag for the rest of the day.
    showModalBottomSheet<bool>(
      context: context,
      builder: (_) => const ProUpsellSheet._(),
    ).then((intent) {
      if (intent != true) cooldown.recordDismissal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'PulseCoach Pro — upsell sheet',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Accedi a tutto lo storico e ai grafici con PulseCoach Pro.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'non ora — chiudi',
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('non ora'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: 'Scopri Pro',
                      child: FilledButton(
                        // Story 17.4 will wire the purchase flow.
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Scopri Pro'),
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
