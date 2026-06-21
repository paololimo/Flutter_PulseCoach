import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart';

const _keyEncryptionKey = 'backup_encryption_key';
const _keyBackupEnabled = 'backup_enabled';

@injectable
class BackupLocalDataSource {
  final AppDatabase _db;
  final FlutterSecureStorage _secureStorage;

  BackupLocalDataSource(this._db, this._secureStorage);

  Future<Map<String, dynamic>> exportDriftSnapshot() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final userProfiles = await _db.select(_db.userProfile).get();
    final sessions = await _db.select(_db.sessions).get();
    final banditStates = await _db.select(_db.banditState).get();
    final behavioralStates = await _db.select(_db.behavioralState).get();
    final dailyPlans =
        await (_db.select(_db.dailyPlans)
              ..where((t) => t.createdAt.isBiggerThanValue(cutoff)))
            .get();

    // Keep the snapshot referentially self-consistent: only export child rows
    // whose parent is also exported. dailyPlans is filtered to 30 days, and
    // SessionLogs.dailyPlanId is a hard FK with foreign_keys=ON, so logs whose
    // parent plan was filtered out must be dropped or the restore would fail.
    final planIds = dailyPlans.map((p) => p.id).toSet();
    final allLogs = await _db.select(_db.sessionLogs).get();
    final sessionLogs =
        allLogs.where((l) => planIds.contains(l.dailyPlanId)).toList();
    final logIds = sessionLogs.map((l) => l.id).toSet();
    final allRpe = await _db.select(_db.rpeFeedback).get();
    final rpeFeedback = allRpe
        .where((r) => r.sessionLogId == null || logIds.contains(r.sessionLogId))
        .toList();

    return {
      'userProfile': userProfiles.map(_userProfileToMap).toList(),
      'sessions': sessions.map(_sessionToMap).toList(),
      'sessionLogs': sessionLogs.map(_sessionLogToMap).toList(),
      'rpeFeedback': rpeFeedback.map(_rpeFeedbackToMap).toList(),
      'banditState': banditStates.map(_banditStateToMap).toList(),
      'behavioralState': behavioralStates.map(_behavioralStateToMap).toList(),
      'dailyPlans': dailyPlans.map(_dailyPlanToMap).toList(),
    };
  }

  Future<void> restoreDriftSnapshot(Map<String, dynamic> snapshot) async {
    await _db.transaction(() async {
      await _db.delete(_db.sessionLogs).go();
      await _db.delete(_db.rpeFeedback).go();
      await _db.delete(_db.sessions).go();
      await _db.delete(_db.dailyPlans).go();
      await _db.delete(_db.banditState).go();
      await _db.delete(_db.behavioralState).go();
      await _db.delete(_db.userProfile).go();

      for (final row in (snapshot['userProfile'] as List)) {
        await _db.into(_db.userProfile).insert(
          _userProfileCompanionFromMap(row as Map<String, dynamic>),
        );
      }
      for (final row in (snapshot['sessions'] as List)) {
        await _db.into(_db.sessions).insert(
          _sessionCompanionFromMap(row as Map<String, dynamic>),
        );
      }
      for (final row in (snapshot['dailyPlans'] as List)) {
        await _db.into(_db.dailyPlans).insert(
          _dailyPlanCompanionFromMap(row as Map<String, dynamic>),
        );
      }
      for (final row in (snapshot['sessionLogs'] as List)) {
        await _db.into(_db.sessionLogs).insert(
          _sessionLogCompanionFromMap(row as Map<String, dynamic>),
        );
      }
      for (final row in (snapshot['rpeFeedback'] as List)) {
        await _db.into(_db.rpeFeedback).insert(
          _rpeFeedbackCompanionFromMap(row as Map<String, dynamic>),
        );
      }
      for (final row in (snapshot['banditState'] as List)) {
        await _db.into(_db.banditState).insert(
          _banditStateCompanionFromMap(row as Map<String, dynamic>),
        );
      }
      for (final row in (snapshot['behavioralState'] as List)) {
        await _db.into(_db.behavioralState).insert(
          _behavioralStateCompanionFromMap(row as Map<String, dynamic>),
        );
      }
    });
  }

  Future<void> storeEncryptionKey(String base64Key) async {
    await _secureStorage.write(key: _keyEncryptionKey, value: base64Key);
  }

  Future<String?> loadEncryptionKey() async {
    return _secureStorage.read(key: _keyEncryptionKey);
  }

  Future<void> setBackupEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBackupEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool> loadBackupEnabled() async {
    return (await _secureStorage.read(key: _keyBackupEnabled)) == 'true';
  }

  Future<void> queueBackupTask({required String userId}) async {
    await _db.syncQueueDao.insertEntry(
      SyncQueueCompanion(
        eventType: const Value('backup'),
        payload: Value(jsonEncode({'userId': userId})),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  // ─── serialization helpers ──────────────────────────────────────────────────

  Map<String, dynamic> _userProfileToMap(UserProfileData r) => {
    'id': r.id,
    'fitnessGoal': r.fitnessGoal,
    'weeklySessionTarget': r.weeklySessionTarget,
    'intensityPreference': r.intensityPreference,
    'environmentPreference': r.environmentPreference,
    'availableTime': r.availableTime,
    'physicalConstraints': r.physicalConstraints,
    'onboardingCompleted': r.onboardingCompleted,
    'disclaimerAccepted': r.disclaimerAccepted,
    'createdAt': r.createdAt.toIso8601String(),
    'updatedAt': r.updatedAt.toIso8601String(),
  };

  UserProfileCompanion _userProfileCompanionFromMap(Map<String, dynamic> m) =>
      UserProfileCompanion(
        id: Value(m['id'] as int),
        fitnessGoal: Value(m['fitnessGoal'] as String?),
        weeklySessionTarget: Value(m['weeklySessionTarget'] as int),
        intensityPreference: Value(m['intensityPreference'] as String?),
        environmentPreference: Value(m['environmentPreference'] as String?),
        availableTime: Value(m['availableTime'] as String?),
        physicalConstraints: Value(m['physicalConstraints'] as String?),
        onboardingCompleted: Value(m['onboardingCompleted'] as bool),
        disclaimerAccepted: Value(m['disclaimerAccepted'] as bool),
        createdAt: Value(DateTime.parse(m['createdAt'] as String)),
        updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
      );

  Map<String, dynamic> _sessionToMap(Session r) => {
    'id': r.id,
    'sessionType': r.sessionType,
    'intensity': r.intensity,
    'durationSeconds': r.durationSeconds,
    'abandoned': r.abandoned,
    'completedAt': r.completedAt?.toIso8601String(),
    'createdAt': r.createdAt.toIso8601String(),
  };

  SessionsCompanion _sessionCompanionFromMap(Map<String, dynamic> m) =>
      SessionsCompanion(
        id: Value(m['id'] as int),
        sessionType: Value(m['sessionType'] as String),
        intensity: Value(m['intensity'] as int),
        durationSeconds: Value(m['durationSeconds'] as int),
        abandoned: Value(m['abandoned'] as bool),
        completedAt: Value(
          m['completedAt'] != null
              ? DateTime.parse(m['completedAt'] as String)
              : null,
        ),
        createdAt: Value(DateTime.parse(m['createdAt'] as String)),
      );

  Map<String, dynamic> _sessionLogToMap(SessionLog r) => {
    'id': r.id,
    'dailyPlanId': r.dailyPlanId,
    'sessionIndex': r.sessionIndex,
    'completedAt': r.completedAt.toIso8601String(),
    'createdAt': r.createdAt.toIso8601String(),
    'abandoned': r.abandoned,
    'elapsedSeconds': r.elapsedSeconds,
    'currentStepIndex': r.currentStepIndex,
  };

  SessionLogsCompanion _sessionLogCompanionFromMap(Map<String, dynamic> m) =>
      SessionLogsCompanion(
        id: Value(m['id'] as int),
        dailyPlanId: Value(m['dailyPlanId'] as int),
        sessionIndex: Value(m['sessionIndex'] as int),
        completedAt: Value(DateTime.parse(m['completedAt'] as String)),
        createdAt: Value(DateTime.parse(m['createdAt'] as String)),
        abandoned: Value(m['abandoned'] as bool),
        elapsedSeconds: Value(m['elapsedSeconds'] as int?),
        currentStepIndex: Value(m['currentStepIndex'] as int?),
      );

  Map<String, dynamic> _rpeFeedbackToMap(RpeFeedbackData r) => {
    'id': r.id,
    'sessionId': r.sessionId,
    'sessionLogId': r.sessionLogId,
    'rpeValue': r.rpeValue,
    'recordedAt': r.recordedAt.toIso8601String(),
  };

  RpeFeedbackCompanion _rpeFeedbackCompanionFromMap(Map<String, dynamic> m) =>
      RpeFeedbackCompanion(
        id: Value(m['id'] as int),
        sessionId: Value(m['sessionId'] as int),
        sessionLogId: Value(m['sessionLogId'] as int?),
        rpeValue: Value(m['rpeValue'] as int),
        recordedAt: Value(DateTime.parse(m['recordedAt'] as String)),
      );

  Map<String, dynamic> _banditStateToMap(BanditStateData r) => {
    'id': r.id,
    'armWeightsJson': r.armWeightsJson,
    'updatedAt': r.updatedAt.toIso8601String(),
  };

  BanditStateCompanion _banditStateCompanionFromMap(Map<String, dynamic> m) =>
      BanditStateCompanion(
        id: Value(m['id'] as int),
        armWeightsJson: Value(m['armWeightsJson'] as String),
        updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
      );

  Map<String, dynamic> _behavioralStateToMap(BehavioralStateData r) => {
    'id': r.id,
    'currentState': r.currentState,
    'restingHr': r.restingHr,
    'stepCount': r.stepCount,
    'streakCount': r.streakCount,
    'recordedAt': r.recordedAt.toIso8601String(),
    'updatedAt': r.updatedAt.toIso8601String(),
  };

  BehavioralStateCompanion _behavioralStateCompanionFromMap(
    Map<String, dynamic> m,
  ) => BehavioralStateCompanion(
    id: Value(m['id'] as int),
    currentState: Value(m['currentState'] as String),
    restingHr: Value(m['restingHr'] as int?),
    stepCount: Value(m['stepCount'] as int?),
    streakCount: Value(m['streakCount'] as int),
    recordedAt: Value(DateTime.parse(m['recordedAt'] as String)),
    updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
  );

  Map<String, dynamic> _dailyPlanToMap(DailyPlan r) => {
    'id': r.id,
    'planDate': r.planDate,
    'planJson': r.planJson,
    'generatedAt': r.generatedAt.toIso8601String(),
    'createdAt': r.createdAt.toIso8601String(),
    'isCompleted': r.isCompleted,
  };

  DailyPlansCompanion _dailyPlanCompanionFromMap(Map<String, dynamic> m) =>
      DailyPlansCompanion(
        id: Value(m['id'] as int),
        planDate: Value(m['planDate'] as String),
        planJson: Value(m['planJson'] as String),
        generatedAt: Value(DateTime.parse(m['generatedAt'] as String)),
        createdAt: Value(DateTime.parse(m['createdAt'] as String)),
        isCompleted: Value(m['isCompleted'] as bool),
      );
}
