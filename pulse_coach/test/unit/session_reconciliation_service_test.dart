import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_notification_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_reconciliation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSessionNotificationService implements SessionNotificationService {
  int cancelCallCount = 0;
  bool launchedFromNotification = false;

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
  }) async {}

  @override
  Future<void> cancel() async {
    cancelCallCount++;
  }

  @override
  Future<bool> didLaunchFromNotification() async => launchedFromNotification;
}

const _session = PlannedSession(
  sessionType: 'cardio',
  intensity: 3,
  durationMinutes: 10,
  isIndoor: true,
);

BackgroundedSessionSnapshot _snapshot({
  required int planId,
  required DateTime backgroundedAt,
}) => BackgroundedSessionSnapshot(
  planId: planId,
  sessionIndex: 1,
  session: _session,
  currentStepIndex: 2,
  secondsRemaining: 30,
  elapsedSeconds: 90,
  backgroundedAt: backgroundedAt,
);

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late int planId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final now = DateTime.utc(2026, 7, 7);
    planId = await db.dailyPlansDao.insertPlan(
      DailyPlansCompanion.insert(
        planDate: '2026-07-07',
        planJson: '{"sessions":[]}',
        generatedAt: now,
        createdAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SessionReconciliationService', () {
    test(
      '22.5-SVC-001: no snapshot persisted → reconcile() returns none',
      () async {
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
        );

        final result = await service.reconcile();

        expect(result, SessionReconciliationResult.none);
      },
    );

    test(
      '22.5-SVC-002: snapshot persisted, elapsed < timeout → stillWithinWindow, '
      'snapshot NOT cleared, no DAO write',
      () async {
        final now = DateTime.utc(2026, 7, 7, 12);
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
          now: () => now,
          timeout: const Duration(minutes: 5),
        );
        await service.writeSnapshot(
          _snapshot(
            planId: planId,
            backgroundedAt: now.subtract(const Duration(minutes: 2)),
          ),
        );

        final result = await service.reconcile();

        expect(result, SessionReconciliationResult.stillWithinWindow);
        expect(service.readSnapshot(), isNotNull);
        final logs = await db.sessionLogsDao.getLogsForPlan(planId);
        expect(logs, isEmpty);
      },
    );

    test(
      '22.5-SVC-003: snapshot persisted, elapsed >= timeout → abandonedByTimeout, '
      'snapshot cleared, SessionLogsDao row written with correct fields',
      () async {
        final backgroundedAt = DateTime.utc(2026, 7, 7, 12);
        final now = backgroundedAt.add(const Duration(minutes: 5));
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
          now: () => now,
          timeout: const Duration(minutes: 5),
        );
        await service.writeSnapshot(
          _snapshot(planId: planId, backgroundedAt: backgroundedAt),
        );

        final result = await service.reconcile();

        expect(result, SessionReconciliationResult.abandonedByTimeout);
        expect(service.readSnapshot(), isNull);
        final logs = await db.sessionLogsDao.getLogsForPlan(planId);
        expect(logs, hasLength(1));
        final log = logs.single;
        expect(log.sessionIndex, 1);
        expect(log.abandoned, isTrue);
        expect(log.elapsedSeconds, 90);
        expect(log.currentStepIndex, 2);
      },
    );

    test(
      '22.5-SVC-004: calling reconcile() twice after timeout → second call '
      'returns none (already cleared), no duplicate DAO row',
      () async {
        final backgroundedAt = DateTime.utc(2026, 7, 7, 12);
        final now = backgroundedAt.add(const Duration(minutes: 10));
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
          now: () => now,
          timeout: const Duration(minutes: 5),
        );
        await service.writeSnapshot(
          _snapshot(planId: planId, backgroundedAt: backgroundedAt),
        );

        final first = await service.reconcile();
        final second = await service.reconcile();

        expect(first, SessionReconciliationResult.abandonedByTimeout);
        expect(second, SessionReconciliationResult.none);
        final logs = await db.sessionLogsDao.getLogsForPlan(planId);
        expect(logs, hasLength(1));
      },
    );

    test(
      '22.5-SVC-005: corrupted persisted JSON string → readSnapshot()/'
      'reconcile() returns null/none, does not throw',
      () async {
        await prefs.setString('backgrounded_session_snapshot', 'not-json{{');
        final service = SessionReconciliationService(prefs, db.sessionLogsDao);

        expect(service.readSnapshot(), isNull);
        await expectLater(
          service.reconcile(),
          completion(SessionReconciliationResult.none),
        );
      },
    );

    test(
      '22.5-SVC-006: writeSnapshot() then readSnapshot() round-trips all '
      'fields correctly (including nested PlannedSession)',
      () async {
        final backgroundedAt = DateTime.utc(2026, 7, 7, 12, 30);
        final service = SessionReconciliationService(prefs, db.sessionLogsDao);
        final original = _snapshot(
          planId: planId,
          backgroundedAt: backgroundedAt,
        );

        await service.writeSnapshot(original);
        final decoded = service.readSnapshot();

        expect(decoded, isNotNull);
        expect(decoded!.planId, original.planId);
        expect(decoded.sessionIndex, original.sessionIndex);
        expect(decoded.session, original.session);
        expect(decoded.currentStepIndex, original.currentStepIndex);
        expect(decoded.secondsRemaining, original.secondsRemaining);
        expect(decoded.elapsedSeconds, original.elapsedSeconds);
        expect(decoded.backgroundedAt, original.backgroundedAt);
      },
    );

    test(
      'clearSnapshot() removes a persisted snapshot',
      () async {
        final service = SessionReconciliationService(prefs, db.sessionLogsDao);
        await service.writeSnapshot(
          _snapshot(planId: planId, backgroundedAt: DateTime.utc(2026, 7, 7)),
        );

        await service.clearSnapshot();

        expect(service.readSnapshot(), isNull);
      },
    );

    test(
      'reconcile() with a snapshot whose planId is null does not write a DAO '
      'row but still clears the snapshot once timed out',
      () async {
        final backgroundedAt = DateTime.utc(2026, 7, 7, 12);
        final now = backgroundedAt.add(const Duration(minutes: 10));
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
          now: () => now,
        );
        await service.writeSnapshot(
          BackgroundedSessionSnapshot(
            planId: null,
            sessionIndex: 0,
            session: _session,
            currentStepIndex: 0,
            secondsRemaining: 10,
            elapsedSeconds: 5,
            backgroundedAt: backgroundedAt,
          ),
        );

        final result = await service.reconcile();

        expect(result, SessionReconciliationResult.abandonedByTimeout);
        expect(service.readSnapshot(), isNull);
      },
    );
  });

  group('handleNotificationTap', () {
    test(
      'snapshot still within window → navigates to sessionActive with '
      'resume args, clears snapshot, cancels notification',
      () async {
        final now = DateTime.utc(2026, 7, 7, 12);
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
          now: () => now,
          timeout: const Duration(minutes: 5),
        );
        await service.writeSnapshot(
          _snapshot(
            planId: planId,
            backgroundedAt: now.subtract(const Duration(minutes: 1)),
          ),
        );
        final notificationService = _FakeSessionNotificationService();

        await handleNotificationTap(
          reconciliationService: service,
          notificationService: notificationService,
        );

        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          AppRouter.sessionActive,
        );
        expect(service.readSnapshot(), isNull);
        expect(notificationService.cancelCallCount, 1);
      },
    );

    test(
      'snapshot already abandoned by timeout → navigates to today, no cancel',
      () async {
        final backgroundedAt = DateTime.utc(2026, 7, 7, 12);
        final now = backgroundedAt.add(const Duration(minutes: 10));
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
          now: () => now,
          timeout: const Duration(minutes: 5),
        );
        await service.writeSnapshot(
          _snapshot(planId: planId, backgroundedAt: backgroundedAt),
        );
        final notificationService = _FakeSessionNotificationService();

        await handleNotificationTap(
          reconciliationService: service,
          notificationService: notificationService,
        );

        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          AppRouter.today,
        );
        expect(notificationService.cancelCallCount, 0);
      },
    );

    test(
      'no snapshot ever existed → navigates to today, no cancel',
      () async {
        final service = SessionReconciliationService(prefs, db.sessionLogsDao);
        final notificationService = _FakeSessionNotificationService();

        await handleNotificationTap(
          reconciliationService: service,
          notificationService: notificationService,
        );

        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          AppRouter.today,
        );
        expect(notificationService.cancelCallCount, 0);
      },
    );

    test(
      '22.5-SVC-008: inSessionPageActive true → short-circuits, no navigation, '
      'no reconcile side effect, no cancel (warm double-handling guard, review F1)',
      () async {
        final now = DateTime.utc(2026, 7, 7, 12);
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
          now: () => now,
          timeout: const Duration(minutes: 5),
        );
        await service.writeSnapshot(
          _snapshot(
            planId: planId,
            backgroundedAt: now.subtract(const Duration(minutes: 1)),
          ),
        );
        final notificationService = _FakeSessionNotificationService();
        AppRouter.router.go(AppRouter.today);

        inSessionPageActive = true;
        try {
          await handleNotificationTap(
            reconciliationService: service,
            notificationService: notificationService,
          );
        } finally {
          inSessionPageActive = false;
        }

        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          AppRouter.today,
        );
        // reconcile() was never called: snapshot is untouched (still within
        // window, not cleared), unlike the not-guarded path in the sibling test.
        expect(service.readSnapshot(), isNotNull);
        expect(notificationService.cancelCallCount, 0);
      },
    );
  });

  group('reconcileSessionOnColdStart', () {
    test(
      '22.5-SVC-009: abandonedByTimeout on plain icon launch (no tap) still '
      'cancels the orphaned notification (review F5 regression guard)',
      () async {
        final now = DateTime.utc(2026, 7, 7, 12);
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
          now: () => now,
          timeout: const Duration(minutes: 5),
        );
        await service.writeSnapshot(
          _snapshot(
            planId: planId,
            backgroundedAt: now.subtract(const Duration(minutes: 10)),
          ),
        );
        final notificationService = _FakeSessionNotificationService()
          ..launchedFromNotification = false;

        await reconcileSessionOnColdStart(
          reconciliationService: service,
          notificationService: notificationService,
        );

        expect(notificationService.cancelCallCount, 1);
        expect(service.readSnapshot(), isNull);
      },
    );

    test(
      '22.5-SVC-010: stillWithinWindow on plain icon launch (no tap) does '
      'not cancel the notification, does not navigate',
      () async {
        final now = DateTime.utc(2026, 7, 7, 12);
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
          now: () => now,
          timeout: const Duration(minutes: 5),
        );
        await service.writeSnapshot(
          _snapshot(
            planId: planId,
            backgroundedAt: now.subtract(const Duration(minutes: 1)),
          ),
        );
        final notificationService = _FakeSessionNotificationService()
          ..launchedFromNotification = false;
        AppRouter.router.go(AppRouter.today);

        await reconcileSessionOnColdStart(
          reconciliationService: service,
          notificationService: notificationService,
        );

        expect(notificationService.cancelCallCount, 0);
        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          AppRouter.today,
        );
      },
    );

    test(
      '22.5-SVC-011: didLaunchFromNotification true delegates to '
      'handleNotificationTap and still cancels on abandonedByTimeout',
      () async {
        final now = DateTime.utc(2026, 7, 7, 12);
        final service = SessionReconciliationService(
          prefs,
          db.sessionLogsDao,
          now: () => now,
          timeout: const Duration(minutes: 5),
        );
        await service.writeSnapshot(
          _snapshot(
            planId: planId,
            backgroundedAt: now.subtract(const Duration(minutes: 10)),
          ),
        );
        final notificationService = _FakeSessionNotificationService()
          ..launchedFromNotification = true;

        await reconcileSessionOnColdStart(
          reconciliationService: service,
          notificationService: notificationService,
        );

        // Both the cold-start-level cancel (result == abandonedByTimeout) and
        // handleNotificationTap's own already-abandoned → go(today) path run;
        // cancel is only invoked once here since handleNotificationTap only
        // cancels on the still-within-window branch (snapshot already null).
        expect(notificationService.cancelCallCount, 1);
        expect(
          AppRouter.router.routeInformationProvider.value.uri.path,
          AppRouter.today,
        );
      },
    );
  });
}
