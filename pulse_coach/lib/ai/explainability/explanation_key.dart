/// Stable, locale-independent identifiers for the rule-based session
/// explanations produced by `ExplanationGenerator`.
///
/// Pure Dart — no Flutter imports (ARCH7), so it is safe to use inside the AI
/// isolate. The generator emits one of these keys per session; the
/// presentation layer resolves it to a localized string via
/// `explanationText` (session_card_helpers.dart). Persisting the key name
/// (instead of a baked Italian string) is what lets the same plan render in
/// either locale. See [storageValue] for the persisted form.
enum ExplanationKey {
  recovering,
  atRiskMissed,
  atRiskHighLoad,
  fatigued,
  elevatedRestingHr,
  lowSteps,
  optimalRestingHr,
  consistentWeek,
  intenseEffort,
  comfortZone,
  greatStreak,
  welcomeBack,
  breathingFallback,
  mobilityFallback,
  genericFallback;

  /// The string persisted into `PlannedSession.explanation` and later
  /// resolved back at display time. Using the enum name keeps it stable.
  String get storageValue => name;

  /// Parses a stored value back into a key, or `null` if it is not a known
  /// key (e.g. a legacy plan that stored a raw localized string). Callers
  /// fall back to showing the raw stored text in that case.
  static ExplanationKey? tryParse(String value) {
    for (final key in ExplanationKey.values) {
      if (key.name == value) return key;
    }
    return null;
  }
}
