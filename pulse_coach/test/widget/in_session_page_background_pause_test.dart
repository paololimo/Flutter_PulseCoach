import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/presentation/pages/in_session_page.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_notification_service.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _session = PlannedSession(
  sessionType: 'cardio',
  intensity: 3,
  durationMinutes: 1,
  isIndoor: true,
);

class _FakeSessionNotificationService implements SessionNotificationService {
  _FakeSessionNotificationService({
    this.permissionStatusToReturn = NotificationPermissionStatus.granted,
  });

  final NotificationPermissionStatus permissionStatusToReturn;
  int showSessionPausedCallCount = 0;
  int requestPermissionCallCount = 0;

  @override
  Future<void> init() async {}

  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      permissionStatusToReturn;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCallCount++;
    return true;
  }

  @override
  Future<void> showSessionPaused({
    required String sessionName,
    required int secondsRemaining,
  }) async {
    showSessionPausedCallCount++;
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<bool> didLaunchFromNotification() async => false;
}

GoRouter _router({
  PlannedSession? session = _session,
  SessionNotificationService? notificationService,
}) => GoRouter(
      initialLocation: AppRouter.sessionActive,
      routes: [
        GoRoute(
          path: AppRouter.sessionActive,
          builder: (_, _) => InSessionPage(
            session: session,
            notificationService: notificationService,
          ),
        ),
        GoRoute(
          path: AppRouter.sessionRpe,
          builder: (_, _) => const Scaffold(body: Text('RPE target')),
        ),
      ],
    );

Widget _wrap(GoRouter router) => MaterialApp.router(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  routerConfig: router,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
);

Future<void> _pumpPastCountdown(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 3400));
  await tester.pump();
}

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  group('InSessionPage background pause', () {
    testWidgets(
      '22.4-VIEW-001: backgrounding pauses the timer (secondsRemaining frozen)',
      (tester) async {
        final fakeService = _FakeSessionNotificationService();
        await tester.pumpWidget(
          _wrap(_router(notificationService: fakeService)),
        );
        await _pumpPastCountdown(tester);

        expect(find.text('01:00'), findsOneWidget);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pump();

        await tester.pump(const Duration(seconds: 3));

        expect(find.text('01:00'), findsOneWidget);
        expect(fakeService.showSessionPausedCallCount, 1);
      },
    );

    testWidgets(
      '22.4-VIEW-002: backgrounding after completion is a no-op (no notification call)',
      (tester) async {
        final fakeService = _FakeSessionNotificationService();
        await tester.pumpWidget(
          _wrap(_router(notificationService: fakeService)),
        );
        await _pumpPastCountdown(tester);

        // Drive the session to natural completion (3 phases x 60s, +1 tick each).
        await tester.pump(const Duration(seconds: 183));
        await tester.pump();

        expect(
          () => tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          ),
          returnsNormally,
        );
        await tester.pump();

        expect(fakeService.showSessionPausedCallCount, 0);

        // Let the WearBridgeService reconnect poller settle before teardown
        // (mirrors 8.2-VIEW-004's precedent in in_session_page_abandon_test).
        await tester.pump(const Duration(seconds: 60));
      },
    );

    testWidgets(
      '22.4-VIEW-003: widget.session == null → paused is a no-op (no crash)',
      (tester) async {
        final fakeService = _FakeSessionNotificationService();
        await tester.pumpWidget(
          _wrap(_router(session: null, notificationService: fakeService)),
        );
        await _pumpPastCountdown(tester);

        expect(
          () => tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          ),
          returnsNormally,
        );
        await tester.pump();

        expect(fakeService.showSessionPausedCallCount, 0);
      },
    );

    testWidgets(
      '22.4-VIEW-004: undetermined permission shows the rationale dialog; '
      'tapping Allow calls requestPermission',
      (tester) async {
        final fakeService = _FakeSessionNotificationService(
          permissionStatusToReturn: NotificationPermissionStatus.undetermined,
        );
        await tester.pumpWidget(
          _wrap(_router(notificationService: fakeService)),
        );
        await _pumpPastCountdown(tester);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Consenti'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(fakeService.requestPermissionCallCount, 1);
      },
    );

    testWidgets(
      '22.4-VIEW-005: tapping "Not now" dismisses the dialog and does not '
      'request permission',
      (tester) async {
        final fakeService = _FakeSessionNotificationService(
          permissionStatusToReturn: NotificationPermissionStatus.undetermined,
        );
        await tester.pumpWidget(
          _wrap(_router(notificationService: fakeService)),
        );
        await _pumpPastCountdown(tester);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Non ora'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(fakeService.requestPermissionCallCount, 0);
      },
    );

    testWidgets(
      '22.4-VIEW-006: granted permission suppresses the rationale dialog',
      (tester) async {
        final fakeService = _FakeSessionNotificationService(
          permissionStatusToReturn: NotificationPermissionStatus.granted,
        );
        await tester.pumpWidget(
          _wrap(_router(notificationService: fakeService)),
        );
        await _pumpPastCountdown(tester);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(fakeService.requestPermissionCallCount, 0);
      },
    );

    testWidgets(
      '22.4-VIEW-007: a persisted "already shown" flag suppresses the dialog '
      'even when status is undetermined',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'notification_rationale_shown': true,
        });
        getIt.registerSingleton<SharedPreferences>(
          await SharedPreferences.getInstance(),
        );
        final fakeService = _FakeSessionNotificationService(
          permissionStatusToReturn: NotificationPermissionStatus.undetermined,
        );
        await tester.pumpWidget(
          _wrap(_router(notificationService: fakeService)),
        );
        await _pumpPastCountdown(tester);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(fakeService.requestPermissionCallCount, 0);
      },
    );
  });
}
