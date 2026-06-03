import 'package:flutter/material.dart';
import 'package:pulse_coach_wear/communication/phone_bridge.dart';
import 'package:wear_plus/wear_plus.dart';

class SummaryDisplayPage extends StatelessWidget {
  const SummaryDisplayPage({required this.initialState, super.key});

  final SessionWearState initialState;

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(shape == WearShape.round ? 40 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _capitalize(initialState.summarySessionType ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: textTheme.titleMedium,
                  ),
                  Text(
                    '${initialState.summaryDurationMinutes} min',
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: textTheme.displaySmall?.copyWith(
                      fontFamilyFallback: const ['monospace'],
                    ),
                  ),
                  Text(
                    'Valuta RPE\nsul telefono',
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: textTheme.bodySmall,
                  ),
                  if (initialState.summaryAbandoned)
                    Text(
                      '(abbandonata)',
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.noScaling,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
