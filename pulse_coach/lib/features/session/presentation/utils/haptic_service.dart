import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:vibration/vibration.dart';

/// Abstracts haptic feedback so InSessionCubit can be tested without
/// platform-channel noise.
abstract interface class HapticService {
  /// Called on every step transition, including final-step to complete.
  void stepTransition();
}

/// Wraps the vibration plugin with cached capability checks.
class VibrationHapticService implements HapticService {
  bool _supported = false;
  bool _initialized = false;

  Future<void>? _initFuture;

  /// Queries vibration support once and caches the result for the hot path.
  /// Concurrent calls share the same in-flight future, so `_supported` is
  /// observable as soon as any caller's await resolves.
  Future<void> init() {
    if (_initialized) return Future<void>.value();
    return _initFuture ??= _runInit();
  }

  Future<void> _runInit() async {
    try {
      _supported = await Vibration.hasVibrator();
    } catch (e) {
      debugPrint('VibrationHapticService.init: hasVibrator failed: $e');
      _supported = false;
    } finally {
      _initialized = true;
    }
  }

  @override
  void stepTransition() {
    if (!_supported) return;

    try {
      unawaited(
        Vibration.vibrate(duration: 200).catchError((Object e) {
          debugPrint(
            'VibrationHapticService.stepTransition: vibrate failed: $e',
          );
        }),
      );
    } catch (e) {
      debugPrint('VibrationHapticService.stepTransition: vibrate failed: $e');
    }
  }
}
