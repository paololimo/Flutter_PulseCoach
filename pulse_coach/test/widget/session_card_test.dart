import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/compact_session_card.dart';
import 'package:pulse_coach/features/today/presentation/widgets/hero_session_card.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

PlannedSession _session({
  String type = 'mobility',
  int intensity = 3,
  int duration = 5,
  String explanation = 'Buona base di mobilità per oggi.',
}) => PlannedSession(
  sessionType: type,
  intensity: intensity,
  durationMinutes: duration,
  isIndoor: true,
  explanation: explanation,
);

Icon _icon(IconData iconData) {
  final element = find.byIcon(iconData).evaluate().single;
  return element.widget as Icon;
}

Text _text(String value) {
  final element = find.text(value).evaluate().single;
  return element.widget as Text;
}

void main() {
  group('sessionDisplayName', () {
    test('7.2-HELPER-001: mobility -> Mobilità', () {
      expect(sessionDisplayName('mobility'), equals('Mobilità'));
    });

    test('7.2-HELPER-002: cardio -> Cardio', () {
      expect(sessionDisplayName('cardio'), equals('Cardio'));
    });

    test('7.2-HELPER-003: breathing -> Respirazione', () {
      expect(sessionDisplayName('breathing'), equals('Respirazione'));
    });

    test('7.2-HELPER-004: unknown type -> pass-through', () {
      expect(sessionDisplayName('unknown'), equals('unknown'));
    });
  });

  group('intensityLabel', () {
    test('7.2-HELPER-005: intensity 1 -> Leggera', () {
      expect(intensityLabel(1), equals('Leggera'));
    });

    test('7.2-HELPER-006: intensity 3 -> Leggera boundary', () {
      expect(intensityLabel(3), equals('Leggera'));
    });

    test('7.2-HELPER-007: intensity 4 -> Moderata boundary', () {
      expect(intensityLabel(4), equals('Moderata'));
    });

    test('7.2-HELPER-008: intensity 7 -> Moderata boundary', () {
      expect(intensityLabel(7), equals('Moderata'));
    });

    test('7.2-HELPER-009: intensity 8 -> Intensa boundary', () {
      expect(intensityLabel(8), equals('Intensa'));
    });

    test('7.2-HELPER-010: intensity 10 -> Intensa', () {
      expect(intensityLabel(10), equals('Intensa'));
    });

    test('7.2-HELPER-011: out-of-range low -> Moderata fallback', () {
      expect(intensityLabel(0), equals('Moderata'));
    });

    test('7.2-HELPER-012: out-of-range high -> Moderata fallback', () {
      expect(intensityLabel(11), equals('Moderata'));
    });
  });

  group('sessionAccentColor (AC4)', () {
    const theme = PulseCoachTheme.dark;

    test('7.2-COLOR-001: cardio -> soft coral #F0A1B0', () {
      expect(
        sessionAccentColor('cardio', theme),
        equals(const Color(0xFFF0A1B0)),
      );
    });

    test('7.2-COLOR-002: mobility -> primaryColor #7DD3C0', () {
      expect(
        sessionAccentColor('mobility', theme),
        equals(PulseCoachTheme.dark.primaryColor),
      );
    });

    test('7.2-COLOR-003: breathing -> secondary #A78BDA', () {
      expect(
        sessionAccentColor('breathing', theme),
        equals(PulseCoachTheme.dark.secondary),
      );
    });

    test('7.2-COLOR-004: unknown type -> onSurfaceVariant fallback', () {
      expect(
        sessionAccentColor('unknown', theme),
        equals(PulseCoachTheme.dark.onSurfaceVariant),
      );
    });
  });

  group('HeroSessionCard content (AC1)', () {
    testWidgets('7.2-WIDGET-001: displays session display name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HeroSessionCard(session: _session(type: 'mobility'))),
      );

      expect(find.text('Mobilità'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-002: displays duration label', (tester) async {
      await tester.pumpWidget(
        _wrap(HeroSessionCard(session: _session(duration: 10))),
      );

      expect(find.text('10 min'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-003: displays intensity label 3 -> Leggera', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HeroSessionCard(session: _session(intensity: 3))),
      );

      expect(find.text('Leggera'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-004: displays intensity label 8 -> Intensa', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HeroSessionCard(session: _session(intensity: 8))),
      );

      expect(find.text('Intensa'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-005: displays AI explanation text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HeroSessionCard(
            session: _session(explanation: 'Ottimo per recuperare energia.'),
          ),
        ),
      );

      expect(find.text('Ottimo per recuperare energia.'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-006: displays Inizia sessione CTA button', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session())));

      expect(find.text('Inizia sessione'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-007: onStart fires when button is tapped', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          HeroSessionCard(session: _session(), onStart: () => tapped = true),
        ),
      );

      await tester.tap(find.byType(FilledButton));

      expect(tapped, isTrue);
    });
  });

  group('HeroSessionCard visual contract (AC1, AC2, AC4)', () {
    testWidgets('7.2-WIDGET-008: no chevron icon on hero card', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session())));

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('7.2-WIDGET-009: cardio renders soft coral icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HeroSessionCard(session: _session(type: 'cardio'))),
      );

      final icon = _icon(Icons.favorite_border);
      expect(icon.size, equals(32));
      expect(icon.color, equals(const Color(0xFFF0A1B0)));
    });

    testWidgets('7.2-WIDGET-010: mobility renders primary icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HeroSessionCard(session: _session(type: 'mobility'))),
      );

      final icon = _icon(Icons.self_improvement);
      expect(icon.size, equals(32));
      expect(icon.color, equals(PulseCoachTheme.dark.primaryColor));
    });

    testWidgets('7.2-WIDGET-011: breathing renders secondary icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HeroSessionCard(session: _session(type: 'breathing'))),
      );

      final icon = _icon(Icons.air);
      expect(icon.size, equals(32));
      expect(icon.color, equals(PulseCoachTheme.dark.secondary));
    });

    testWidgets('7.4-HERO-001: shows regenerate icon when callback exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HeroSessionCard(session: _session(), onRegenerate: () {})),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('7.4-HERO-002: hides regenerate icon without callback', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session())));

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('7.4-HERO-003: tapping regenerate invokes the callback', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          HeroSessionCard(session: _session(), onRegenerate: () => taps++),
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh));

      expect(taps, equals(1));
    });
  });

  group('CompactSessionCard content (AC3)', () {
    testWidgets('7.2-WIDGET-012: displays session display name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(CompactSessionCard(session: _session(type: 'cardio'))),
      );

      expect(find.text('Cardio'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-013: displays duration', (tester) async {
      await tester.pumpWidget(
        _wrap(CompactSessionCard(session: _session(duration: 15))),
      );

      expect(find.text('15 min'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-014: shows chevron icon', (tester) async {
      await tester.pumpWidget(_wrap(CompactSessionCard(session: _session())));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-015: no Inizia sessione button', (tester) async {
      await tester.pumpWidget(_wrap(CompactSessionCard(session: _session())));

      expect(find.text('Inizia sessione'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('7.2-WIDGET-016: no explanation text visible', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CompactSessionCard(
            session: _session(explanation: 'Questo non deve apparire.'),
          ),
        ),
      );

      expect(find.text('Questo non deve apparire.'), findsNothing);
    });
  });

  // ── Extended coverage (beyond spec's named WIDGET-001..016) ────────────────

  group('HeroSessionCard extended coverage', () {
    testWidgets('7.2-WIDGET-017: semantic label includes session summary', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          HeroSessionCard(
            session: _session(explanation: 'Respira e sciogli le spalle'),
          ),
        ),
      );

      final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
      expect(
        semantics.any(
          (widget) =>
              widget.properties.label ==
              'Prossima sessione: Mobilità, 5 min, '
                  'Respira e sciogli le spalle. Tocca per iniziare.',
        ),
        isTrue,
      );
    });

    testWidgets('7.2-WIDGET-018: uses 16dp padding and 16dp radius', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session())));

      final paddings = tester.widgetList<Padding>(find.byType(Padding));
      expect(
        paddings.any((padding) => padding.padding == const EdgeInsets.all(16)),
        isTrue,
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(HeroSessionCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('7.2-WIDGET-019: gradient uses accent and surfaceContainer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HeroSessionCard(session: _session(type: 'cardio'))),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(HeroSessionCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.begin, equals(Alignment.topLeft));
      expect(gradient.end, equals(Alignment.bottomRight));
      expect(
        gradient.colors.first,
        const Color(0xFFF0A1B0).withValues(alpha: 0.12),
      );
      expect(gradient.colors.last, PulseCoachTheme.dark.surfaceContainer);
    });

    testWidgets('7.2-WIDGET-020: display name uses H2 typography', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session())));

      final label = _text('Mobilità');
      expect(label.style?.fontFamily, equals('Plus Jakarta Sans'));
      expect(label.style?.fontWeight, equals(FontWeight.w600));
      expect(label.style?.fontSize, equals(20));
    });

    testWidgets(
      '7.2-WIDGET-025: empty explanation hides Text and omits from semantic label',
      (tester) async {
        await tester.pumpWidget(
          _wrap(HeroSessionCard(session: _session(explanation: ''))),
        );

        final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
        expect(
          semantics.any(
            (widget) =>
                widget.properties.label ==
                'Prossima sessione: Mobilità, 5 min. Tocca per iniziare.',
          ),
          isTrue,
        );
      },
    );
  });

  group('CompactSessionCard extended coverage', () {
    testWidgets('7.2-WIDGET-021: onTap fires when card is tapped', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          CompactSessionCard(session: _session(), onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.byType(InkWell));

      expect(tapped, isTrue);
    });

    testWidgets('7.2-WIDGET-022: semantic label includes compact summary', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(CompactSessionCard(session: _session())));

      final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
      expect(
        semantics.any(
          (widget) =>
              widget.properties.label ==
              'Sessione successiva: Mobilità, 5 min. '
                  'Tocca per selezionare come prossima sessione.',
        ),
        isTrue,
      );
    });

    testWidgets('7.2-WIDGET-023: uses compact icon and Material surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(CompactSessionCard(session: _session(type: 'breathing'))),
      );

      final icon = _icon(Icons.air);
      expect(icon.size, equals(24));
      expect(icon.color, equals(PulseCoachTheme.dark.secondary));

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(CompactSessionCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, PulseCoachTheme.dark.surfaceContainer);
      expect(material.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('7.2-WIDGET-024: compact padding matches spec', (tester) async {
      await tester.pumpWidget(_wrap(CompactSessionCard(session: _session())));

      final paddings = tester.widgetList<Padding>(find.byType(Padding));
      expect(
        paddings.any(
          (padding) =>
              padding.padding ==
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        isTrue,
      );
    });
  });
}
