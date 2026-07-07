import 'dart:async' show unawaited;
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:drift/drift.dart' show Value;
import 'package:pulse_coach/core/database/app_database.dart'
    show SessionLogsCompanion;
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/domain/entities/session_start_args.dart';
import 'package:pulse_coach/features/session/presentation/utils/session_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SessionReconciliationResult { none, stillWithinWindow, abandonedByTimeout }

/// Plain-class DTO for the `SharedPreferences`-persisted snapshot of a
/// backgrounded session. Not `@freezed` — a single internal, non-Bloc-state
/// value object used only to (de)serialize one string, not worth the codegen
/// ceremony (see Story 22.5 Dev Notes).
class BackgroundedSessionSnapshot {
  final int? planId;
  final int sessionIndex;
  final PlannedSession session;
  final int currentStepIndex;
  final int secondsRemaining;
  final int elapsedSeconds;
  final DateTime backgroundedAt;

  const BackgroundedSessionSnapshot({
    required this.planId,
    required this.sessionIndex,
    required this.session,
    required this.currentStepIndex,
    required this.secondsRemaining,
    required this.elapsedSeconds,
    required this.backgroundedAt,
  });

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'sessionIndex': sessionIndex,
    'session': session.toJson(),
    'currentStepIndex': currentStepIndex,
    'secondsRemaining': secondsRemaining,
    'elapsedSeconds': elapsedSeconds,
    'backgroundedAt': backgroundedAt.toIso8601String(),
  };

  factory BackgroundedSessionSnapshot.fromJson(Map<String, dynamic> json) =>
      BackgroundedSessionSnapshot(
        planId: json['planId'] as int?,
        sessionIndex: json['sessionIndex'] as int,
        session: PlannedSession.fromJson(
          json['session'] as Map<String, dynamic>,
        ),
        currentStepIndex: json['currentStepIndex'] as int,
        secondsRemaining: json['secondsRemaining'] as int,
        elapsedSeconds: json['elapsedSeconds'] as int,
        backgroundedAt: DateTime.parse(json['backgroundedAt'] as String),
      );
}

/// Single source of truth for "is there a backgrounded session, and has its
/// timeout elapsed" — read/write a `SharedPreferences`-backed
/// [BackgroundedSessionSnapshot], decide none/still-within-window/abandoned,
/// and (only when timed out) authoritatively commit the abandon via a direct
/// DAO write. Never navigates — callers own routing (Story 22.5).
class SessionReconciliationService {
  static const String _kSnapshotKey = 'backgrounded_session_snapshot';
  static const Duration defaultTimeout = Duration(minutes: 5);

  final SharedPreferences _prefs;
  final SessionLogsDao _sessionLogsDao;
  final DateTime Function() _now;
  final Duration _timeout;

  SessionReconciliationService(
    this._prefs,
    this._sessionLogsDao, {
    DateTime Function()? now,
    Duration timeout = defaultTimeout,
  }) : _now = now ?? DateTime.now,
       _timeout = timeout;

  BackgroundedSessionSnapshot? readSnapshot() {
    final raw = _prefs.getString(_kSnapshotKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return BackgroundedSessionSnapshot.fromJson(json);
    } catch (_) {
      // Corrupt/undeserializable payload: drop it so it does not wedge every
      // future `reconcile()` into `none` (never abandoning, never cancelling
      // the notification) and linger in SharedPreferences forever (review F6).
      unawaited(clearSnapshot());
      return null;
    }
  }

  Future<void> writeSnapshot(BackgroundedSessionSnapshot snapshot) =>
      _prefs.setString(_kSnapshotKey, jsonEncode(snapshot.toJson()));

  Future<void> clearSnapshot() => _prefs.remove(_kSnapshotKey);

  /// Reads the persisted snapshot (if any) and, when the inactivity timeout
  /// has elapsed, authoritatively commits the abandon via a direct DAO write
  /// (idempotent: `insertOrIgnore` on `(dailyPlanId, sessionIndex)`). Does NOT
  /// clear the snapshot on `stillWithinWindow` — only a caller that actually
  /// resumes clears it. Does NOT navigate; callers own routing.
  Future<SessionReconciliationResult> reconcile() async {
    final snapshot = readSnapshot();
    if (snapshot == null) return SessionReconciliationResult.none;

    final elapsed = _now().difference(snapshot.backgroundedAt);
    if (elapsed < _timeout) {
      return SessionReconciliationResult.stillWithinWindow;
    }

    if (snapshot.planId != null) {
      await _sessionLogsDao.insertLog(
        SessionLogsCompanion(
          dailyPlanId: Value(snapshot.planId),
          sessionIndex: Value(snapshot.sessionIndex),
          completedAt: Value(snapshot.backgroundedAt),
          createdAt: Value(snapshot.backgroundedAt),
          abandoned: const Value(true),
          elapsedSeconds: Value(snapshot.elapsedSeconds),
          currentStepIndex: Value(snapshot.currentStepIndex),
        ),
      );
    }
    await clearSnapshot();
    return SessionReconciliationResult.abandonedByTimeout;
  }
}

/// True while an `InSessionPage` with a live cubit is mounted and owns the
/// warm resume/abandon path via its `AppLifecycleState.resumed` handler. When
/// set, [handleNotificationTap] must not act: a notification tap on a warm app
/// fires BOTH the lifecycle `resumed` callback and the plugin tap callback, and
/// letting both consume the single snapshot races them to contradictory
/// outcomes (in-place resume vs `go(today)`; abandon→RPE vs `go(today)`). The
/// lifecycle handler is the sole owner while the page is mounted (review F1).
bool inSessionPageActive = false;

/// Shared tap-routing logic for both the cold-start (`main.dart`) and
/// warm/backgrounded (`onDidReceiveNotificationResponse`) notification-tap
/// paths (Story 22.5, AC3/AC4/AC6). Standalone so `SessionNotificationService`
/// does not need to depend on `SessionReconciliationService`/`AppRouter`.
/// Never has a `BuildContext` — `AppRouter.router.go(...)` is called directly
/// on the static router instance, which `go_router` supports independent of
/// whether a `Navigator` is currently mounted.
Future<void> handleNotificationTap({
  required SessionReconciliationService reconciliationService,
  required SessionNotificationService notificationService,
}) async {
  // Warm path: a mounted InSessionPage's `_handleResumed` already owns this
  // tap via the lifecycle `resumed` callback — do not double-handle (review F1).
  if (inSessionPageActive) return;
  await reconciliationService.reconcile();
  final snapshot = reconciliationService.readSnapshot();

  if (snapshot != null) {
    final args = SessionStartArgs(
      session: snapshot.session,
      planId: snapshot.planId,
      sessionIndex: snapshot.sessionIndex,
      resumeStepIndex: snapshot.currentStepIndex,
      resumeSecondsRemaining: snapshot.secondsRemaining,
      resumeElapsedSeconds: snapshot.elapsedSeconds,
    );
    AppRouter.router.go(AppRouter.sessionActive, extra: args);
    await reconciliationService.clearSnapshot();
    unawaited(notificationService.cancel());
  } else {
    // Already abandoned or never existed — explicit `.go(today)` rather than
    // relying on the default redirect, since this may run while the app is
    // already showing some other route mid-session-flow (e.g. sessionRpe).
    AppRouter.router.go(AppRouter.today);
  }
}
