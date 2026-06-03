import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:pulse_coach_wear/communication/phone_bridge.dart';
import 'package:pulse_coach_wear/session_display_page.dart';
import 'package:pulse_coach_wear/summary_display_page.dart';
import 'package:wear_plus/wear_plus.dart';

void main() {
  runApp(const WearApp());
}

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return AmbientMode(
          builder: (context, mode, child) {
            return MaterialApp(
              title: 'PulseCoach Wear',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF00C896),
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              home: _WearRoot(
                isAmbient: mode == WearMode.ambient,
                shape: shape,
              ),
            );
          },
        );
      },
    );
  }
}

class _WearRoot extends StatefulWidget {
  const _WearRoot({required this.isAmbient, required this.shape});

  final bool isAmbient;
  final WearShape shape;

  @override
  State<_WearRoot> createState() => _WearRootState();
}

class _WearRootState extends State<_WearRoot> {
  late final PhoneBridge _phoneBridge;

  @override
  void initState() {
    super.initState();
    _phoneBridge = PhoneBridge();
  }

  @override
  void dispose() {
    unawaited(_phoneBridge.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SessionWearState>(
      stream: _phoneBridge.states,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state != null && state.isSummary) {
          return SummaryDisplayPage(initialState: state);
        }
        if (state != null && !state.isEnded) {
          return SessionDisplayPage(bridge: _phoneBridge, initialState: state);
        }
        return PulseCoachWearHome(
          isAmbient: widget.isAmbient,
          shape: widget.shape,
        );
      },
    );
  }
}

class PulseCoachWearHome extends StatelessWidget {
  const PulseCoachWearHome({
    required this.isAmbient,
    required this.shape,
    super.key,
  });

  final bool isAmbient;
  final WearShape shape;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(shape == WearShape.round ? 32 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PulseCoach Wear',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isAmbient
                    ? null
                    : () => debugPrint('PulseCoach Wear button tapped'),
                child: const Text('Tap me'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
