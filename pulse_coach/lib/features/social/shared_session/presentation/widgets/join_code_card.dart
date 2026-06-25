import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

class JoinCodeCard extends StatelessWidget {
  final String joinCode;
  final VoidCallback onRefresh;

  const JoinCodeCard({
    super.key,
    required this.joinCode,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>();
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: joinCode,
              version: QrVersions.auto,
              size: 200,
            ),
            const SizedBox(height: 16),
            Text(
              joinCode,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: pulseTheme?.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.sharedSessionRefreshCode),
              onPressed: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}
