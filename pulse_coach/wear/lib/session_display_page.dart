import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:pulse_coach_wear/communication/phone_bridge.dart';
import 'package:wear_plus/wear_plus.dart';

class SessionDisplayPage extends StatefulWidget {
  const SessionDisplayPage({
    this.states,
    this.initialState,
    this.onSessionEnded,
    this.bridge,
    super.key,
  });

  final Stream<SessionWearState>? states;
  final SessionWearState? initialState;
  final VoidCallback? onSessionEnded;
  final PhoneBridge? bridge;

  @override
  State<SessionDisplayPage> createState() => _SessionDisplayPageState();
}

class _SessionDisplayPageState extends State<SessionDisplayPage> {
  PhoneBridge? _ownedBridge;
  bool _endedNotified = false;

  Stream<SessionWearState> get _states =>
      widget.states ?? (widget.bridge ?? _ownedBridge!).states;

  @override
  void initState() {
    super.initState();
    if (widget.states == null && widget.bridge == null) {
      _ownedBridge = PhoneBridge();
    }
  }

  @override
  void dispose() {
    unawaited(_ownedBridge?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return StreamBuilder<SessionWearState>(
          stream: _states,
          initialData: widget.initialState,
          builder: (context, snapshot) {
            final state = snapshot.data;
            if (state?.isEnded == true) {
              _notifyEnded();
            }
            return _SessionDisplayContent(
              shape: shape,
              state: state,
            );
          },
        );
      },
    );
  }

  void _notifyEnded() {
    if (_endedNotified) return;
    _endedNotified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final callback = widget.onSessionEnded;
      if (callback != null) {
        callback();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }
}

class _SessionDisplayContent extends StatelessWidget {
  const _SessionDisplayContent({
    required this.shape,
    required this.state,
  });

  final WearShape shape;
  final SessionWearState? state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final heartRate = state?.heartRate;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(shape == WearShape.round ? 40 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state?.stepName.isNotEmpty == true
                    ? state!.stepName
                    : 'Waiting',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
                style: textTheme.titleMedium,
              ),
              Text(
                _formatTime(state?.secondsRemaining ?? 0),
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
                style: textTheme.displaySmall?.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontFamilyFallback: const ['monospace'],
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (heartRate != null)
                Text(
                  '♥ $heartRate bpm',
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  style: textTheme.titleSmall,
                )
              else
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int secs) {
    final clamped = secs < 0 ? 0 : secs;
    final minutes = clamped ~/ 60;
    final seconds = clamped % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
