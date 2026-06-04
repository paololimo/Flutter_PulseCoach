import 'dart:developer' as dev;

import 'package:flutter/foundation.dart'
    show kDebugMode, kReleaseMode, visibleForTesting;

typedef AppLogSink =
    void Function(
      String message, {
      required String name,
      Object? error,
      StackTrace? stackTrace,
      required int level,
    });

/// Centralized structured logger for PulseCoach.
///
/// Debug/warning logs stay development-only. Error logs always write to
/// dart:developer so release persistence failures are observable by any
/// attached platform log collector.
abstract final class AppLogger {
  @visibleForTesting
  static AppLogSink? debugSink;

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
    debugSink?.call(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: 500,
    );
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
    debugSink?.call(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: 900,
    );
  }

  static void error(
    String message, {
    String name = 'PulseCoach',
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    debugSink?.call(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
