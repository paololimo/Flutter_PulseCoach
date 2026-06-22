import 'package:flutter/material.dart';

class ProUpsellSheet extends StatelessWidget {
  const ProUpsellSheet._();

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const ProUpsellSheet._(),
    );
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
                        onPressed: () => Navigator.of(context).pop(),
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
                        onPressed: () => Navigator.of(context).pop(),
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
