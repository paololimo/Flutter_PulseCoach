import 'dart:async' show StreamSubscription, unawaited;

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
              home: WearRoot(isAmbient: mode == WearMode.ambient, shape: shape),
            );
          },
        );
      },
    );
  }
}

class WearRoot extends StatefulWidget {
  const WearRoot({
    required this.isAmbient,
    required this.shape,
    this.bridge,
    super.key,
  });

  final bool isAmbient;
  final WearShape shape;
  final PhoneBridge? bridge;

  @override
  State<WearRoot> createState() => _WearRootState();
}

class _WearRootState extends State<WearRoot> {
  late final PhoneBridge _phoneBridge;
  StreamSubscription<SessionWearState>? _statesSub;
  SessionWearState? _state;
  bool _sawSummary = false;

  @override
  void initState() {
    super.initState();
    _phoneBridge = widget.bridge ?? PhoneBridge();
    _statesSub = _phoneBridge.states.listen(_onState);
  }

  @override
  void dispose() {
    unawaited(_statesSub?.cancel());
    unawaited(_phoneBridge.dispose());
    super.dispose();
  }

  void _onState(SessionWearState state) {
    if (!mounted) return;
    if (state.isEnded) {
      setState(() {
        _sawSummary = false;
        _state = state;
      });
      return;
    }
    if (state.isSummary) {
      setState(() {
        _sawSummary = true;
        _state = state;
      });
      return;
    }
    if (_sawSummary) return;
    setState(() => _state = state);
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state?.isSummary == true) {
      return SummaryDisplayPage(initialState: state!);
    }
    if (state != null && !state.isEnded) {
      return SessionDisplayPage(bridge: _phoneBridge, initialState: state);
    }
    return PulseCoachWearHome(isAmbient: widget.isAmbient, shape: widget.shape);
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
