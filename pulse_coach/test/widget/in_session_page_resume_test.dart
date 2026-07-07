import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/app_database.dart'
    show SessionLogsCompanion;
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/presentation/pages/in_session_page.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_notification_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_reconciliation_service.dart';
import 'package:pulse_coach/features/session/presentation/widgets/countdown_overlay.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _session = PlannedSession(
  sessionType: 'cardio',
  intensity: 3,
  durationMinutes: 1,
  isIndoor: true,
);

class _FakeSessionLogsDao extends Fake implements SessionLogsDao {
  final List<SessionLogsCompanion> insertedLogs = [];

  @override
  Future<int> insertLog(SessionLogsCompanion entry) async {
    insertedLogs.add(entry);
    return 1;
  }
}

class _FakeSessionNotificationService implements SessionNotificationService {
  int showSessionPausedCallCount = 0;
  int cancelCallCount = 0;

  @override
  Future<void> init() async {}

  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.granted;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showSessionPaused({
    required String sessionName,
    required int secondsRemaining,
  }) async {
    showSessionPausedCallCount++;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount++;
  }

  @override
  Future<bool> didLaunchFromNotification() async => false;
}

/// Drives `DateTime.now()` in tests — `WidgetTester.pump()` advances
/// `Timer.periodic` but not the wall clock.
class _ManualClock {
  DateTime current;
  _ManualClock(this.current);
  DateTime call() => current;
  void advance(Duration d) => current = current.add(d);
}

GoRouter _router({
  required SessionNotificationService notificationService,
  required SessionReconciliationService reconciliationService,
  int? resumeStepIndex,
  int? resumeSecondsRemaining,
  int? resumeElapsedSeconds,
}) => GoRouter(
  initialLocation: AppRouter.sessionActive,
  routes: [
    GoRoute(
      path: AppRouter.sessionActive,
      builder: (_, _) => InSessionPage(
        session: _session,
        notificationService: notificationService,
        reconciliationService: reconciliationService,
        resumeStepIndex: resumeStepIndex,
        resumeSecondsRemaining: resumeSecondsRemaining,
        resumeElapsedSeconds: resumeElapsedSeconds,
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

  group('InSessionPage resume/reconciliation', () {
    testWidgets(
      '22.5-VIEW-001: paused then resumed before timeout → timer resumes '
      'advancing, notification service .cancel() called',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final clock = _ManualClock(DateTime.now());
        final reconciliationService = SessionReconciliationService(
          prefs,
          _FakeSessionLogsDao(),
          now: clock.call,
          timeout: const Duration(minutes: 5),
        );
        final fakeService = _FakeSessionNotificationService();

        await tester.pumpWidget(
          _wrap(
            _router(
              notificationService: fakeService,
              reconciliationService: reconciliationService,
            ),
          ),
        );
        await _pumpPastCountdown(tester);

        expect(find.text('01:00'), findsOneWidget);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pump();

        clock.advance(const Duration(minutes: 2));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump();

        await tester.pump(const Duration(seconds: 2));
        expect(find.text('00:58'), findsOneWidget);
        expect(fakeService.cancelCallCount, 1);
      },
    );

    testWidgets(
      '22.5-VIEW-002: paused then resumed after timeout → cubit abandons, '
      'navigates to sessionRpe route, notification .cancel() called',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final clock = _ManualClock(DateTime.now());
        final reconciliationService = SessionReconciliationService(
          prefs,
          _FakeSessionLogsDao(),
          now: clock.call,
          timeout: const Duration(minutes: 5),
        );
        final fakeService = _FakeSessionNotificationService();

        await tester.pumpWidget(
          _wrap(
            _router(
              notificationService: fakeService,
              reconciliationService: reconciliationService,
            ),
          ),
        );
        await _pumpPastCountdown(tester);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pump();

        clock.advance(const Duration(minutes: 6));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('RPE target'), findsOneWidget);
        expect(fakeService.cancelCallCount, 1);

        // Let the WearBridgeService reconnect poller settle before teardown
        // (mirrors 8.2-VIEW-004's precedent in in_session_page_abandon_test).
        await tester.pump(const Duration(seconds: 60));
      },
    );

    testWidgets(
      '22.5-VIEW-003: rapid paused→resumed→paused→resumed toggling is '
      'idempotent — no crash, no drift in secondsRemaining, single cancel '
      'per resume',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final clock = _ManualClock(DateTime.now());
        final reconciliationService = SessionReconciliationService(
          prefs,
          _FakeSessionLogsDao(),
          now: clock.call,
          timeout: const Duration(minutes: 5),
        );
        final fakeService = _FakeSessionNotificationService();

        await tester.pumpWidget(
          _wrap(
            _router(
              notificationService: fakeService,
              reconciliationService: reconciliationService,
            ),
          ),
        );
        await _pumpPastCountdown(tester);

        for (var i = 0; i < 3; i++) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump();
          clock.advance(const Duration(seconds: 5));
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          await tester.pump();
        }

        expect(find.text('01:00'), findsOneWidget);
        expect(fakeService.showSessionPausedCallCount, 3);
        expect(fakeService.cancelCallCount, 3);
      },
    );

    testWidgets(
      '22.5-VIEW-004: resumed with no prior paused (result none) → no-op, '
      'no crash',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final reconciliationService = SessionReconciliationService(
          prefs,
          _FakeSessionLogsDao(),
        );
        final fakeService = _FakeSessionNotificationService();

        await tester.pumpWidget(
          _wrap(
            _router(
              notificationService: fakeService,
              reconciliationService: reconciliationService,
            ),
          ),
        );
        await _pumpPastCountdown(tester);

        expect(
          () => tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          ),
          returnsNormally,
        );
        await tester.pump();

        expect(fakeService.cancelCallCount, 0);
      },
    );

    testWidgets(
      '22.5-VIEW-005: deep-link construction (non-null resumeStepIndex/'
      'resumeSecondsRemaining) → CountdownOverlay is skipped entirely, '
      'InSessionView renders immediately showing the resumed step/seconds',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final reconciliationService = SessionReconciliationService(
          prefs,
          _FakeSessionLogsDao(),
        );
        final fakeService = _FakeSessionNotificationService();

        await tester.pumpWidget(
          _wrap(
            _router(
              notificationService: fakeService,
              reconciliationService: reconciliationService,
              resumeStepIndex: 0,
              resumeSecondsRemaining: 42,
              resumeElapsedSeconds: 5,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CountdownOverlay), findsNothing);
        expect(find.text('00:42'), findsOneWidget);
      },
    );
  });
}
