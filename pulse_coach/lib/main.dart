import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:pulse_coach/app.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/sync/sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await configureDependencies();
    unawaited(getIt<SyncManager>().start());
  } catch (e, st) {
    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st));
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize app.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
    return;
  }
  runApp(const PulseCoachApp());
}
