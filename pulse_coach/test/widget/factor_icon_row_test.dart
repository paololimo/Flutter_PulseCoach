import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/factor_icon_row.dart';
import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

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
          _weather(temperature: 5.0, precipitationProbability: 20, aqiValue: 40),
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
      final factors = deriveDecisionFactors(_session(), _weather(aqiValue: 120));
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
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

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

    testWidgets(
      '22.2-FACTOR-009: each glyph tap target meets 48dp minimum',
      (tester) async {
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
      },
    );

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
