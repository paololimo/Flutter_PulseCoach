import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';
import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

/// Decision factors that may have shaped today's session recommendation.
/// `exerciseType`/`intensity` describe the session itself and are always
/// present; the weather-derived factors are shown only when they are
/// notable per the thresholds in [deriveDecisionFactors]. Humidity is
/// never surfaced (FR82).
enum DecisionFactor { exerciseType, intensity, temperature, precipitation, aqi }

/// Pure derivation of which factors to show for [session] given the current
/// [weather] snapshot (or `null` if unavailable). Presentation-only — does
/// not reflect new AI inference; see Story 22.2 Dev Notes for the rationale
/// behind the temperature/precipitation thresholds.
List<DecisionFactor> deriveDecisionFactors(
  PlannedSession session,
  WeatherContext? weather,
) {
  final factors = <DecisionFactor>[
    DecisionFactor.exerciseType,
    DecisionFactor.intensity,
  ];
  if (weather != null) {
    if (weather.temperature <= 10.0 || weather.temperature >= 28.0) {
      factors.add(DecisionFactor.temperature);
    }
    if (weather.precipitationProbability > 50.0) {
      factors.add(DecisionFactor.precipitation);
    }
    if (weather.isAqiHigh) {
      factors.add(DecisionFactor.aqi);
    }
  }
  return factors;
}

/// Row of quiet Lucide glyphs beneath the hero card's explanation line,
/// showing which decision factors shaped today's recommendation. Purely
/// informational — no navigation, no state mutation (AC6).
class FactorIconRow extends StatelessWidget {
  final PlannedSession session;
  final WeatherContext? weather;

  const FactorIconRow({super.key, required this.session, this.weather});

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final factors = deriveDecisionFactors(session, weather);

    if (factors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 4,
      runSpacing: 0,
      children: [
        for (final factor in factors)
          _FactorGlyph(
            key: ValueKey(factor),
            icon: _iconFor(factor),
            label: _labelFor(factor, l10n),
            color: _colorFor(factor, pulseTheme),
          ),
      ],
    );
  }

  IconData _iconFor(DecisionFactor factor) {
    switch (factor) {
      case DecisionFactor.exerciseType:
        return LucideIcons.dumbbell300;
      case DecisionFactor.intensity:
        return LucideIcons.gauge300;
      case DecisionFactor.temperature:
        return LucideIcons.thermometer300;
      case DecisionFactor.precipitation:
        return LucideIcons.cloudRain300;
      case DecisionFactor.aqi:
        return LucideIcons.wind300;
    }
  }

  String _labelFor(DecisionFactor factor, AppLocalizations l10n) {
    switch (factor) {
      case DecisionFactor.exerciseType:
        return sessionDisplayName(session.sessionType, l10n);
      case DecisionFactor.intensity:
        return intensityLabel(session.intensity, l10n);
      case DecisionFactor.temperature:
        return l10n.factorLabelTemperature(weather!.temperature.round());
      case DecisionFactor.precipitation:
        return l10n.factorLabelPrecipitation;
      case DecisionFactor.aqi:
        return l10n.factorLabelAqi;
    }
  }

  Color _colorFor(DecisionFactor factor, PulseCoachTheme theme) {
    switch (factor) {
      case DecisionFactor.aqi:
        return theme.tertiary;
      case DecisionFactor.exerciseType:
      case DecisionFactor.intensity:
      case DecisionFactor.temperature:
      case DecisionFactor.precipitation:
        return theme.onSurfaceVariant;
    }
  }
}

class _FactorGlyph extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FactorGlyph({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<_FactorGlyph> createState() => _FactorGlyphState();
}

class _FactorGlyphState extends State<_FactorGlyph> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final revealChild = _revealed
        ? Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.label,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : const SizedBox.shrink();

    return Semantics(
      label: widget.label,
      button: true,
      onTap: () => setState(() => _revealed = !_revealed),
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: () => setState(() => _revealed = !_revealed),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 16, color: widget.color),
                  reduceMotion
                      ? revealChild
                      : AnimatedSize(
                          duration: const Duration(milliseconds: 150),
                          child: revealChild,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
