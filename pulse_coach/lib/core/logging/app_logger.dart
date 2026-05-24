import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;

/// Centralized structured logger for PulseCoach.
///
/// Debug builds write to dart:developer. Release builds keep this sink no-op;
/// callers must emit user-observable failure state independently.
abstract final class AppLogger {
  static void debug(
    String message, {
    String name = 'PulseCoach',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      dev.log(
        message,
        name: name,
        error: error,
        stackTrace: stackTrace,
        level: 500,
      );
    }
  }

  static void warning(
    String message, {
    String name = 'PulseCoach',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kReleaseMode) {
      dev.log(
        message,
        name: name,
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  static void error(
    String message, {
    String name = 'PulseCoach',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kReleaseMode) {
      dev.log(
        message,
        name: name,
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }
}
