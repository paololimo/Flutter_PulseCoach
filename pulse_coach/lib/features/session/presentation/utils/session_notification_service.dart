import 'dart:async' show unawaited;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_reconciliation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPermissionStatus { granted, denied, undetermined }

/// Abstracts the session-paused status notification so InSessionPage can be
/// tested without platform-channel noise.
abstract interface class SessionNotificationService {
  Future<void> init();
  Future<NotificationPermissionStatus> permissionStatus();
  Future<bool> requestPermission();
  Future<void> showSessionPaused({
    required String sessionName,
    required int secondsRemaining,
  });
  Future<void> cancel();

  /// True when the app's current process was cold-started by the user
  /// tapping this notification (Story 22.5, AC3/AC4/AC6).
  Future<bool> didLaunchFromNotification();
}

/// Wraps `flutter_local_notifications` to post a best-effort ongoing
/// (Android) / one-shot (iOS) notification showing the frozen session timer
/// while the app is backgrounded (FR79/FR80/NFR39).
class LocalSessionNotificationService implements SessionNotificationService {
  static const int _notificationId = 1001;
  static const String _channelId = 'session_status';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is requested contextually (AC5), not at init time.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onTap,
      );
      _initialized = true;
    } catch (e, st) {
      AppLogger.warning(
        'init failed',
        name: 'LocalSessionNotificationService',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _onTap(NotificationResponse response) {
    // Constructed inline (rather than threaded through the constructor) so
    // this service does not need to depend on SessionReconciliationService/
    // AppRouter in its own signature (Story 22.5 judgment call #7).
    if (!getIt.isRegistered<SessionLogsDao>() ||
        !getIt.isRegistered<SharedPreferences>()) {
      return;
    }
    final reconciliationService = SessionReconciliationService(
      getIt<SharedPreferences>(),
      getIt<SessionLogsDao>(),
    );
    unawaited(
      handleNotificationTap(
        reconciliationService: reconciliationService,
        notificationService: this,
      ),
    );
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final enabled = await android.areNotificationsEnabled();
        return enabled == true
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.undetermined;
      }

      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final options = await ios.checkPermissions();
        return options?.isEnabled == true
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.undetermined;
      }

      return NotificationPermissionStatus.denied;
    } catch (e, st) {
      AppLogger.warning(
        'permissionStatus failed',
        name: 'LocalSessionNotificationService',
        error: e,
        stackTrace: st,
      );
      return NotificationPermissionStatus.denied;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }

      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }

      return false;
    } catch (e, st) {
      AppLogger.warning(
        'requestPermission failed',
        name: 'LocalSessionNotificationService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  @override
  Future<void> showSessionPaused({
    required String sessionName,
    required int secondsRemaining,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        'Session status',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        visibility: NotificationVisibility.public,
        showWhen: false,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );

      await _plugin.show(
        id: _notificationId,
        title: sessionName,
        body: _formatTime(secondsRemaining),
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
    } catch (e, st) {
      AppLogger.warning(
        'showSessionPaused failed',
        name: 'LocalSessionNotificationService',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (e, st) {
      AppLogger.warning(
        'cancel failed',
        name: 'LocalSessionNotificationService',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<bool> didLaunchFromNotification() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      return details?.didNotificationLaunchApp ?? false;
    } catch (e, st) {
      AppLogger.warning(
        'didLaunchFromNotification failed',
        name: 'LocalSessionNotificationService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
