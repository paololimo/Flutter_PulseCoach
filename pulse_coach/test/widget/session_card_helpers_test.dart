import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/explainability/explanation_key.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

void main() {
  group('explanationText resolver (E7.5-T1)', () {
    late AppLocalizations it;
    late AppLocalizations en;

    setUpAll(() async {
      it = await AppLocalizations.delegate.load(const Locale('it'));
      en = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('EXPL-RESOLVE-001: known key resolves per-locale (it != en)', () {
      final key = ExplanationKey.atRiskMissed.storageValue;
      expect(explanationText(key, it), it.explAtRiskMissed);
      expect(explanationText(key, en), en.explAtRiskMissed);
      expect(explanationText(key, it), isNot(explanationText(key, en)));
    });

    test('EXPL-RESOLVE-002: every ExplanationKey resolves to non-empty text '
        'in both locales', () {
      for (final key in ExplanationKey.values) {
        final stored = key.storageValue;
        expect(
          explanationText(stored, it),
          isNotEmpty,
          reason: 'IT missing for ${key.name}',
        );
        expect(
          explanationText(stored, en),
          isNotEmpty,
          reason: 'EN missing for ${key.name}',
        );
        // A resolved key must not leak its raw enum name to the UI.
        expect(explanationText(stored, it), isNot(stored));
        expect(explanationText(stored, en), isNot(stored));
      }
    });

    test('EXPL-RESOLVE-003: unknown/legacy value falls back to raw text', () {
      const legacy = 'Una vecchia spiegazione salvata in chiaro.';
      expect(explanationText(legacy, it), legacy);
      expect(explanationText(legacy, en), legacy);
    });
  });
}
