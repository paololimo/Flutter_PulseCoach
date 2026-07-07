import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalSessionNotificationService', () {
    test(
      '22.4-SVC-001: init() does not throw with no platform channel present',
      () async {
        final service = LocalSessionNotificationService();

        await expectLater(service.init(), completes);
      },
    );

    test(
      '22.4-SVC-002: permissionStatus()/requestPermission() resolve to '
      'denied/false (not throw) with no platform channel present',
      () async {
        final service = LocalSessionNotificationService();
        await service.init();

        final status = await service.permissionStatus();
        final granted = await service.requestPermission();

        expect(status, isNot(NotificationPermissionStatus.granted));
        expect(granted, isFalse);
      },
    );

    test(
      '22.4-SVC-003: showSessionPaused(...) does not throw with no platform '
      'channel present (post-init)',
      () async {
        final service = LocalSessionNotificationService();
        await service.init();

        await expectLater(
          service.showSessionPaused(
            sessionName: 'Cardio',
            secondsRemaining: 90,
          ),
          completes,
        );
      },
    );

    test(
      '22.4-SVC-004: cancel() does not throw with no platform channel present',
      () async {
        final service = LocalSessionNotificationService();

        await expectLater(service.cancel(), completes);
      },
    );
  });
}
