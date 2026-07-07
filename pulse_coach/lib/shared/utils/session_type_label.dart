import 'package:pulse_coach/l10n/app_localizations.dart';

/// Localized display name for a session-type key (`mobility` / `cardio` /
/// `breathing`). Shared across features so the type label stays consistent
/// (Today hero, Progress history/charts, AI decision log). Unknown types fall
/// back to the raw key.
String sessionTypeLabel(String sessionType, AppLocalizations l10n) {
  switch (sessionType) {
    case 'mobility':
      return l10n.sessionNameMobility;
    case 'cardio':
      return l10n.sessionNameCardio;
    case 'breathing':
      return l10n.sessionNameBreathing;
    default:
      return sessionType;
  }
}
