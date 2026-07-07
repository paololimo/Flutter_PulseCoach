import 'package:flutter/material.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

/// Contextual permission-rationale prompt shown once — the first time a
/// session starts while notification permission is undetermined — then
/// suppressed via a persisted flag by the caller (AC5). Mirrors
/// `_AbandonConfirmSheet`'s visual weight (title + body + two
/// actions) — no bespoke visual system to invent (no ratified DESIGN.md entry
/// exists for this feature).
class SessionNotificationRationaleDialog extends StatelessWidget {
  const SessionNotificationRationaleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.sessionNotificationRationaleTitle),
      content: Text(l10n.sessionNotificationRationaleBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.sessionNotificationRationaleNotNowButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.sessionNotificationRationaleAllowButton),
        ),
      ],
    );
  }
}
