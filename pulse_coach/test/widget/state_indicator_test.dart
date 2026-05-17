import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/today/presentation/widgets/state_indicator.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

Text _text(String value) {
  return _testerText(find.text(value));
}

Text _testerText(Finder finder) {
  final element = finder.evaluate().single;
  return element.widget as Text;
}

Map<String, Object?> _stateMessagesArb() {
  final file = File('lib/l10n/app/app_it.arb');
  return (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>).cast();
}

void main() {
  group('StateIndicator — state labels and colors (AC1–AC4)', () {
    testWidgets('7.1-WIDGET-001: active state shows "In forma"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const StateIndicator(state: BehavioralState.active)),
      );

      expect(find.text('In forma'), findsOneWidget);
      expect(find.text('Pronto per il piano di oggi.'), findsOneWidget);
      expect(
        _text('In forma').style?.color,
        equals(PulseCoachTheme.dark.primaryColor),
      );
    });

    testWidgets('7.1-WIDGET-002: fatigued state shows "Sotto sforzo"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const StateIndicator(state: BehavioralState.fatigued)),
      );

      expect(find.text('Sotto sforzo'), findsOneWidget);
      expect(find.text('Oggi alleggeriamo per recuperare.'), findsOneWidget);
      expect(
        _text('Sotto sforzo').style?.color,
        equals(PulseCoachTheme.dark.secondary),
      );
    });

    testWidgets('7.1-WIDGET-003: atRisk state shows "In ripresa"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const StateIndicator(state: BehavioralState.atRisk)),
      );

      expect(find.text('In ripresa'), findsOneWidget);
      expect(
        find.text('Ripartiamo con calma. Sessioni brevi e leggere.'),
        findsOneWidget,
      );
      expect(
        _text('In ripresa').style?.color,
        equals(PulseCoachTheme.dark.tertiary),
      );
    });

    testWidgets('7.1-WIDGET-004: recovering state shows "In recupero"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const StateIndicator(state: BehavioralState.recovering)),
      );

      expect(find.text('In recupero'), findsOneWidget);
      expect(
        find.text('Costruiamo il ritmo, un passo alla volta.'),
        findsOneWidget,
      );
      expect(
        _text('In recupero').style?.color,
        equals(PulseCoachTheme.dark.secondary.withValues(alpha: 0.70)),
      );
    });
  });

  group('StateIndicator — copy logic (AC6)', () {
    testWidgets('7.1-WIDGET-005: no transitionMessage shows static copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const StateIndicator(
            state: BehavioralState.active,
            transitionMessage: null,
          ),
        ),
      );

      expect(find.text('Pronto per il piano di oggi.'), findsOneWidget);
    });

    testWidgets('7.1-WIDGET-006: transitionMessage replaces static copy', (
      tester,
    ) async {
      const msg = 'Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi.';
      await tester.pumpWidget(
        _wrap(
          const StateIndicator(
            state: BehavioralState.atRisk,
            transitionMessage: msg,
          ),
        ),
      );

      expect(find.text(msg), findsOneWidget);
      expect(
        find.text('Ripartiamo con calma. Sessioni brevi e leggere.'),
        findsNothing,
      );
    });
  });

  group('StateIndicator — icon and typography (AC5, AC10)', () {
    testWidgets('7.1-WIDGET-007: atRisk and recovering show different icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              StateIndicator(state: BehavioralState.atRisk),
              StateIndicator(state: BehavioralState.recovering),
            ],
          ),
        ),
      );

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons, hasLength(2));
      expect(icons[0].icon, equals(Icons.warning_amber_outlined));
      expect(icons[1].icon, equals(Icons.autorenew));
    });

    testWidgets('7.1-WIDGET-008: typography matches StateIndicator spec', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const StateIndicator(state: BehavioralState.active)),
      );

      final label = _text('In forma');
      final subCopy = _text('Pronto per il piano di oggi.');
      expect(label.style?.fontFamily, equals('Plus Jakarta Sans'));
      expect(label.style?.fontWeight, equals(FontWeight.w500));
      expect(label.style?.fontSize, equals(17));
      expect(subCopy.style?.fontFamily, equals('Plus Jakarta Sans'));
      expect(subCopy.style?.fontWeight, equals(FontWeight.w400));
      expect(subCopy.style?.fontSize, equals(13));
      expect(
        subCopy.style?.color,
        equals(PulseCoachTheme.dark.onSurfaceVariant),
      );
    });
  });

  group('StateIndicator — no internal state codes exposed (AC11)', () {
    testWidgets('7.1-WIDGET-009: no internal state code appears in text', (
      tester,
    ) async {
      for (final state in BehavioralState.values) {
        await tester.pumpWidget(_wrap(StateIndicator(state: state)));

        expect(find.textContaining('atRisk'), findsNothing);
        expect(find.textContaining('fatigued'), findsNothing);
        expect(find.textContaining('active'), findsNothing);
        expect(find.textContaining('recovering'), findsNothing);
      }
    });
  });

  group('StateMessages — ARB invariants (AC7, AC8, AC11)', () {
    test('7.1-ARB-001: ARB file has exactly 46 user-facing keys', () {
      final arb = _stateMessagesArb();
      final userFacingKeys = arb.keys.where((key) => !key.startsWith('@'));

      expect(userFacingKeys, hasLength(46));
      expect(
        userFacingKeys,
        containsAll([
          'transitionActiveAtRisk',
          'transitionActiveFatigued',
          'transitionFatiguedAtRisk',
          'transitionRecoveringFatigued',
          'countdownSemanticAnnounce',
          'countdownGoAnnounce',
          'transitionAtRiskRecovering',
          'transitionFatiguedRecovering',
          'transitionRecoveringActive',
          'stateLabelActive',
          'stateLabelFatigued',
          'stateLabelAtRisk',
          'stateLabelRecovering',
          'staticCopyActive',
          'staticCopyFatigued',
          'staticCopyAtRisk',
          'staticCopyRecovering',
        ]),
      );
    });

    test('7.1-ARB-002: active→fatigued differs from recovering→fatigued', () {
      final arb = _stateMessagesArb();

      expect(
        arb['transitionActiveFatigued'],
        isNot(equals(arb['transitionRecoveringFatigued'])),
      );
    });

    test('7.1-ARB-003: copy excludes internal state codes and emoji', () {
      final arb = _stateMessagesArb();
      final userFacingValues = arb.entries
          .where(
            (entry) =>
                !entry.key.startsWith('@') && entry.key != 'inSessionHrDisplay',
          )
          .map((entry) => entry.value as String);

      for (final value in userFacingValues) {
        expect(value, isNot(contains('atRisk')));
        expect(value, isNot(contains('fatigued')));
        expect(value, isNot(contains('recovering')));
        expect(value, isNot(contains('active')));
        expect(
          value,
          isNot(
            contains(
              RegExp(r'[\u{2600}-\u{27BF}\u{1F300}-\u{1FAFF}]', unicode: true),
            ),
          ),
        );
      }
    });
  });
}
