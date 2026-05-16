import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Map<String, Object?> _readArb(String path) {
  return (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>)
      .cast();
}

Set<String> _userFacingKeys(Map<String, Object?> arb) {
  return arb.keys.where((key) => !key.startsWith('@')).toSet();
}

Set<String> _placeholderTokens(String value) {
  return RegExp(
    r'{(\w+)}',
  ).allMatches(value).map((match) => match.group(1)!).toSet();
}

Set<String> _declaredPlaceholders(Map<String, Object?> arb, String key) {
  final metadata = arb['@$key'];
  if (metadata is! Map<String, dynamic>) return {};
  final placeholders = metadata['placeholders'];
  if (placeholders is! Map<String, dynamic>) return {};
  return placeholders.keys.toSet();
}

void main() {
  testWidgets('AppLocalizations resolves appTitle in Italian', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final title = AppLocalizations.of(context)!.appTitle;
            return Text(title);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PulseCoach'), findsOneWidget);
  });

  test('7.5-L10N-002: English and Italian ARB files expose the same keys', () {
    final english = _readArb('lib/l10n/app/app_en.arb');
    final italian = _readArb('lib/l10n/app/app_it.arb');

    expect(_userFacingKeys(english), equals(_userFacingKeys(italian)));
  });

  test('7.5-L10N-003: ARB placeholder metadata matches localized values', () {
    final english = _readArb('lib/l10n/app/app_en.arb');
    final italian = _readArb('lib/l10n/app/app_it.arb');

    for (final key in _userFacingKeys(english)) {
      final englishValue = english[key];
      final italianValue = italian[key];
      if (englishValue is! String || italianValue is! String) continue;

      final englishTokens = _placeholderTokens(englishValue);
      final italianTokens = _placeholderTokens(italianValue);
      final englishDeclared = _declaredPlaceholders(english, key);
      final italianDeclared = _declaredPlaceholders(italian, key);

      expect(
        englishTokens,
        equals(englishDeclared),
        reason: 'English placeholder metadata mismatch for $key',
      );
      expect(
        italianTokens,
        equals(italianDeclared),
        reason: 'Italian placeholder metadata mismatch for $key',
      );
      expect(
        englishDeclared,
        equals(italianDeclared),
        reason: 'Cross-locale placeholder mismatch for $key',
      );
    }
  });

  test('7.5-L10N-004: legacy state messages ARB file is removed', () {
    expect(File('lib/l10n/state_messages.it.arb').existsSync(), isFalse);
  });
}
