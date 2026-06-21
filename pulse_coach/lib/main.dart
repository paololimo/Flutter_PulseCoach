import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:pulse_coach/app.dart';
import 'package:pulse_coach/core/cloud/secure_local_storage.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/sync/sync_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase init before DI setup — SupabaseClientProvider singleton needs
  // the instance ready. Free core must not crash if credentials are absent.
  try {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(),
      ),
    );
  } catch (e) {
    // Empty --dart-define in dev/test environments is expected; log and continue.
    debugPrint('Supabase init failed: $e — running in offline-only mode');
  }

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
