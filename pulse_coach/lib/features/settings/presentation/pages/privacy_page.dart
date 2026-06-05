import 'package:flutter/material.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PrivacySection(
            title: l10n.privacyOnDeviceTitle,
            body: l10n.privacyOnDeviceBody,
            textTheme: textTheme,
          ),
          _PrivacySection(
            title: l10n.privacyHealthApiTitle,
            body: l10n.privacyHealthApiBody,
            textTheme: textTheme,
          ),
          _PrivacySection(
            title: l10n.privacyLocationTitle,
            body: l10n.privacyLocationBody,
            textTheme: textTheme,
          ),
          _PrivacySection(
            title: l10n.privacyGdprTitle,
            body: l10n.privacyGdprBody,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.title,
    required this.body,
    required this.textTheme,
  });

  final String title;
  final String body;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(body, style: textTheme.bodyMedium),
        const SizedBox(height: 24),
      ],
    );
  }
}
