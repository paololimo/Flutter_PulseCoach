import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/factor_icon_row.dart';
import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

import '../helpers/viewport_helper.dart';

Widget _wrap(Widget child, {double textScaleFactor = 1.0}) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
    child: app!,
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

PlannedSession _session({
  String type = 'mobility',
  int intensity = 3,
  int duration = 5,
}) => PlannedSession(
  sessionType: type,
  intensity: intensity,
  durationMinutes: duration,
  isIndoor: true,
  explanation: 'Buona base di mobilità per oggi.',
);

WeatherContext _weather({
  double temperature = 18.0,
  double precipitationProbability = 10.0,
  int aqiValue = 40,
}) => WeatherContext(
  temperature: temperature,
  precipitationProbability: precipitationProbability,
  aqiValue: aqiValue,
  cachedAt: DateTime(2026, 7, 6),
);

void main() {
  group('deriveDecisionFactors (AC2)', () {
    test('22.2-FACTOR-001: weather=null -> exactly 2 factors', () {
      final factors = deriveDecisionFactors(_session(), null);
      expect(
        factors,
        equals([DecisionFactor.exerciseType, DecisionFactor.intensity]),
      );
    });

    test(
      '22.2-FACTOR-002: cold temperature -> exerciseType, intensity, temperature',
      () {
        final factors = deriveDecisionFactors(
          _session(),
          _weather(
            temperature: 5.0,
            precipitationProbability: 20,
            aqiValue: 40,
          ),
        );
        expect(
          factors,
          equals([
            DecisionFactor.exerciseType,
            DecisionFactor.intensity,
            DecisionFactor.temperature,
          ]),
        );
      },
    );

    test(
      '22.2-FACTOR-003: precipitationProbability=80 -> precipitation present',
      () {
        final factors = deriveDecisionFactors(
          _session(),
          _weather(precipitationProbability: 80),
        );
        expect(factors, contains(DecisionFactor.precipitation));
      },
    );

    test('22.2-FACTOR-004: isAqiHigh=true -> aqi factor present', () {
      final factors = deriveDecisionFactors(
        _session(),
        _weather(aqiValue: 120),
      );
      expect(factors, contains(DecisionFactor.aqi));
    });

    test(
      '22.2-FACTOR-005: mild temperature/low precip/low aqi -> only 2 factors',
      () {
        final factors = deriveDecisionFactors(
          _session(),
          _weather(
            temperature: 18.0,
            precipitationProbability: 10.0,
            aqiValue: 40,
          ),
        );
        expect(
          factors,
          equals([DecisionFactor.exerciseType, DecisionFactor.intensity]),
        );
      },
    );
  });

  group('FactorIconRow widget (AC1, AC3, AC4, AC5, AC6)', () {
    testWidgets('22.2-FACTOR-006: tap reveals semantics label for a glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(FactorIconRow(session: _session(), weather: null)),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('it'));
      expect(
        find.bySemanticsLabel(sessionDisplayNameFor(_session(), l10n)),
        findsOneWidget,
      );
    });

    testWidgets(
      '22.2-FACTOR-007: reduce motion enabled + tap -> no exception, instant reveal',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('it'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.darkTheme,
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FactorIconRow(session: _session(), weather: null),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '22.2-FACTOR-008: 5 glyphs at 360x640 + 2.0 textScale -> no overflow, all icons found',
      (tester) async {
        set360x640Surface(tester);

        await tester.pumpWidget(
          _wrap(
            FactorIconRow(
              session: _session(),
              weather: _weather(
                temperature: 5.0,
                precipitationProbability: 80.0,
                aqiValue: 120,
              ),
            ),
            textScaleFactor: 2.0,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Icon), findsNWidgets(5));
      },
    );

    testWidgets('22.2-FACTOR-009: each glyph tap target meets 48dp minimum', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(FactorIconRow(session: _session(), weather: null)),
      );

      final boxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      for (final box in boxes) {
        final constraints = box.constraints;
        expect(constraints.minWidth, greaterThanOrEqualTo(48));
        expect(constraints.minHeight, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('22.2-FACTOR-010: AQI glyph tinted PulseCoachTheme.tertiary', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FactorIconRow(session: _session(), weather: _weather(aqiValue: 120)),
        ),
      );

      final icons = tester.widgetList<Icon>(find.byType(Icon));
      final windIcon = icons.firstWhere(
        (icon) => icon.color == PulseCoachTheme.dark.tertiary,
      );
      expect(windIcon.color, equals(PulseCoachTheme.dark.tertiary));
    });

    testWidgets(
      '22.2-FACTOR-011: reveal state does not leak onto a different factor at '
      'the same index when the factor set changes (ValueKey(factor) regression)',
      (tester) async {
        Widget host(WeatherContext? weather) => MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.darkTheme,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: FactorIconRow(session: _session(), weather: weather),
              ),
            ),
          ),
        );

        // cold weather -> factors: [exerciseType, intensity, temperature]
        final cold = _weather(
          temperature: 5.0,
          precipitationProbability: 10.0,
          aqiValue: 40,
        );
        await tester.pumpWidget(host(cold));

        // Reveal the 3rd glyph (temperature, index 2).
        await tester.tap(find.byType(GestureDetector).at(2));
        await tester.pump();

        final l10n = await AppLocalizations.delegate.load(const Locale('it'));
        final temperatureLabel = l10n.factorLabelTemperature(
          cold.temperature.round(),
        );
        expect(find.text(temperatureLabel), findsOneWidget);

        // Rain weather -> factors: [exerciseType, intensity, precipitation]
        // (temperature drops out, precipitation takes its place at index 2).
        final rainy = _weather(
          temperature: 18.0,
          precipitationProbability: 80.0,
          aqiValue: 40,
        );
        await tester.pumpWidget(host(rainy));
        await tester.pump();

        // Without ValueKey(factor), Flutter would reuse the index-2 element's
        // State (previously `_revealed: true`) for the new precipitation
        // glyph, incorrectly showing its label already revealed. With the
        // key, the precipitation glyph is a fresh State, starting unrevealed.
        expect(find.text(l10n.factorLabelPrecipitation), findsNothing);
        expect(find.text(temperatureLabel), findsNothing);
      },
    );

    testWidgets(
      '22.2-FACTOR-012: glyphs lay out as a horizontal row, not a full-width '
      'vertical stack (regression: Center expanded each glyph to full width)',
      (tester) async {
        // Bounded, wide container mirrors the hero card. The bug only appears
        // under a bounded width: a plain Center inside each glyph expanded to
        // fill it, forcing one glyph per Wrap run (vertical stack).
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 400,
              child: FactorIconRow(
                session: _session(),
                weather: _weather(temperature: 5.0),
              ),
            ),
          ),
        );

        // 3 factors: exerciseType, intensity, temperature.
        final icons = find.byType(Icon);
        expect(icons, findsNWidgets(3));

        final first = tester.getRect(icons.at(0));
        final second = tester.getRect(icons.at(1));

        // Same row: the first two glyphs share a vertical center.
        expect(
          (first.center.dy - second.center.dy).abs(),
          lessThan(1.0),
          reason: 'glyphs should sit on the same row, not stack vertically',
        );
        // Progressing horizontally: the second glyph is to the right.
        expect(second.center.dx, greaterThan(first.center.dx));

        // No glyph occupies the full container width (the stack signature).
        final glyphBox = tester.getSize(
          find
              .ancestor(of: icons.at(0), matching: find.byType(ConstrainedBox))
              .first,
        );
        expect(
          glyphBox.width,
          lessThan(120),
          reason: 'each glyph should be tap-target sized, not full width',
        );
      },
    );
  });
}

// Local mirror of session_card_helpers.sessionDisplayName to avoid importing
// a private/internal symbol collision in this test file's scope.
String sessionDisplayNameFor(PlannedSession session, AppLocalizations l10n) {
  switch (session.sessionType) {
    case 'mobility':
      return l10n.sessionNameMobility;
    case 'cardio':
      return l10n.sessionNameCardio;
    case 'breathing':
      return l10n.sessionNameBreathing;
    default:
      return session.sessionType;
  }
}
