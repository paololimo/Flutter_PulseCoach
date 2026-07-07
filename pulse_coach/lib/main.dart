import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:pulse_coach/app.dart';
import 'package:pulse_coach/core/cloud/secure_local_storage.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/sync/sync_manager.dart';
import 'package:pulse_coach/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_notification_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_reconciliation_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // RevenueCat must be configured before configureDependencies() because
  // SubscriptionBloc constructor self-dispatches SubscriptionCheckRequested
  // which calls Purchases.getCustomerInfo(). Empty key → observer mode (NFR34).
  try {
    final rcKey = Platform.isAndroid
        ? const String.fromEnvironment(
            'REVENUECAT_API_KEY_ANDROID',
            defaultValue: '',
          )
        : const String.fromEnvironment(
            'REVENUECAT_API_KEY_IOS',
            defaultValue: '',
          );
    await Purchases.configure(PurchasesConfiguration(rcKey));
  } catch (e) {
    debugPrint('RevenueCat init failed: $e — running without subscription gating');
  }

  try {
    await configureDependencies();
    getIt<SyncManager>().registerHandler(
      LeaderboardRemoteDataSource.awardEventType,
      getIt<LeaderboardRemoteDataSource>().replayAward,
    );
    getIt<SyncManager>().registerHandler(
      LeaderboardRemoteDataSource.sharedResultEventType,
      getIt<LeaderboardRemoteDataSource>().replaySubmitSharedResult,
    );
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

  // Story 22.5: reconcile any backgrounded session left over from before this
  // cold start (AC2/AC6), then check whether this launch was triggered by
  // tapping the session-paused notification (AC3/AC4). Must never block
  // startup — mirrors the Supabase/RevenueCat try/catch style above.
  try {
    final reconciliationService = SessionReconciliationService(
      getIt<SharedPreferences>(),
      getIt<SessionLogsDao>(),
    );
    final notificationService = LocalSessionNotificationService();
    final result = await reconciliationService.reconcile();
    // A force-kill + plain icon relaunch after the timeout finalizes the
    // abandon but would otherwise leave the ongoing (autoCancel:false) paused
    // notification orphaned on the status bar — clear it (AC6, review F5).
    if (result == SessionReconciliationResult.abandonedByTimeout) {
      unawaited(notificationService.cancel());
    }
    if (await notificationService.didLaunchFromNotification()) {
      await handleNotificationTap(
        reconciliationService: reconciliationService,
        notificationService: notificationService,
      );
    }
  } catch (e) {
    debugPrint('Session reconciliation failed: $e — continuing cold start');
  }

  runApp(const PulseCoachApp());
}
