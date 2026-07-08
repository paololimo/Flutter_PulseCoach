import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:pulse_coach/core/database/app_database.dart';

/// Debug-only utility to populate the local DB with demo session history so
/// the Progress charts can be exercised without weeks of real usage.
/// Reachable only via the kDebugMode-gated Debug drawer entry.
class DebugSeedPage extends StatefulWidget {
  const DebugSeedPage(this._db, {super.key});

  final AppDatabase _db;

  @override
  State<DebugSeedPage> createState() => _DebugSeedPageState();
}

class _DebugSeedPageState extends State<DebugSeedPage> {
  bool _seeding = false;
  String? _result;

  Future<void> _seedThreeWeeks() async {
    setState(() {
      _seeding = true;
      _result = null;
    });
    final count = await _seedDemoSessions(widget._db);
    if (!mounted) return;
    setState(() {
      _seeding = false;
      _result = 'Sostituite con $count sessioni su 3 settimane '
          '(media RPE 7 / 6 / 5 +-1, 4 giorni con sessioni abbandonate).';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sostituisce i dati demo con 3 settimane (dal 15 giugno 2026), '
                '3 sessioni/giorno (mobility/cardio/breathing). Media RPE: 7 '
                '(sett. 1), 6 (sett. 2), 5 (sett. 3), varianza +-1 sulle '
                'sessioni completate. 4 giorni hanno meno di 3/3 sessioni '
                'completate (0, 1 o 2 su 3) — le mancanti sono registrate '
                'come abbandonate, così il Tasso di completamento le '
                'riflette. Nota: il grafico "RPE trend" mostra solo le '
                'ultime 20 sessioni completate.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _seeding ? null : _seedThreeWeeks,
                child: _seeding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Semina dati demo (3 settimane)'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 16),
                Text(_result!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Day indices (0 = 2026-06-15) that don't have all 3 sessions completed,
// mapped to how many of the 3 were actually done that day. Chosen to read as
// "life happened" rather than a pattern: one day short by one session in
// each of weeks 1 and 3, one day short by two in week 2, and one fully
// missed day near the end of week 3.
const _incompleteDays = {
  3: 2, // 2026-06-18 -> 2/3
  10: 1, // 2026-06-25 -> 1/3
  16: 2, // 2026-07-01 -> 2/3
  19: 0, // 2026-07-04 -> 0/3
};

const _allTypes = ['mobility', 'cardio', 'breathing'];

/// Replaces any previously seeded demo rows (session_logs with a null
/// dailyPlanId — the denormalized "shared session" path, never used by real
/// plan-based completions) with 3 weeks of history starting 2026-06-15 UTC.
/// Every day gets 3 session_log rows (mobility/cardio/breathing) so the
/// Completion Rate chart (completed vs. abandoned) reflects [_incompleteDays]
/// correctly; on those days the last `3 - completedCount` rows are marked
/// `abandoned: true` (cut from the end — mobility is the one most likely to
/// still get done) with no RPE feedback, matching a session started/skipped
/// rather than rated. Each week's RPE values for the *completed* sessions are
/// randomized around that week's target mean (7 / 6 / 5, +-1) with a small
/// integer residual correction so the weekly mean lands exactly on target.
Future<int> _seedDemoSessions(AppDatabase db) async {
  await _clearPreviousDemoData(db);

  const durations = {'mobility': 10, 'cardio': 15, 'breathing': 8};
  const daysPerWeek = 7;
  const weekTargets = [7, 6, 5];
  final start = DateTime.utc(2026, 6, 15);

  var inserted = 0;
  var globalIndex = 0;
  for (var week = 0; week < weekTargets.length; week++) {
    // How many *completed* sessions this week has, given the incomplete days.
    var weekCompletedCount = 0;
    for (var day = 0; day < daysPerWeek; day++) {
      final dayIndex = week * daysPerWeek + day;
      weekCompletedCount += _incompleteDays[dayIndex] ?? 3;
    }

    final rpeValues = _weekRpeValues(
      target: weekTargets[week],
      count: weekCompletedCount,
      seed: 1000 + week,
    );
    var withinWeekIndex = 0;

    for (var day = 0; day < daysPerWeek; day++) {
      final dayIndex = week * daysPerWeek + day;
      final date = start.add(Duration(days: dayIndex));
      final completedToday = _incompleteDays[dayIndex] ?? 3;

      for (var i = 0; i < _allTypes.length; i++) {
        final sessionType = _allTypes[i];
        final isAbandoned = i >= completedToday;
        final completedAt = date.add(Duration(hours: 8 + i * 4));
        final fullDurationSeconds = durations[sessionType]! * 60;

        final logId = await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            sessionIndex: globalIndex,
            completedAt: completedAt,
            createdAt: completedAt,
            abandoned: Value(isAbandoned),
            elapsedSeconds: isAbandoned
                ? Value((fullDurationSeconds * 0.4).round())
                : const Value.absent(),
            sessionType: Value(sessionType),
            durationMinutes: Value(durations[sessionType]!),
          ),
        );

        if (!isAbandoned) {
          final rpe = rpeValues[withinWeekIndex];
          await db.rpeFeedbackDao.insertFeedback(
            RpeFeedbackCompanion.insert(
              sessionId: logId,
              sessionLogId: Value(logId),
              rpeValue: rpe,
              recordedAt: completedAt,
            ),
          );
          withinWeekIndex++;
        }

        inserted++;
        globalIndex++;
      }
    }
  }
  return inserted;
}

Future<void> _clearPreviousDemoData(AppDatabase db) async {
  final oldLogs = await (db.select(
    db.sessionLogs,
  )..where((t) => t.dailyPlanId.isNull())).get();
  if (oldLogs.isEmpty) return;

  final oldIds = oldLogs.map((l) => l.id).toList();
  await (db.delete(
    db.rpeFeedback,
  )..where((t) => t.sessionLogId.isIn(oldIds))).go();
  await (db.delete(
    db.sessionLogs,
  )..where((t) => t.dailyPlanId.isNull())).go();
}

/// Random-ish integer RPE values (1-10 range) whose mean is exactly [target],
/// avoiding a sorted/staircase look. Deviations start in [-1, 1] around
/// [target], then a residual correction nudges a handful of entries by ±1
/// (clamped to 1-10) until the sum matches target * count exactly.
List<int> _weekRpeValues({
  required int target,
  required int count,
  required int seed,
}) {
  final random = Random(seed);
  final values = List<int>.generate(
    count,
    (_) => (target + random.nextInt(3) - 1).clamp(1, 10),
  );

  // Correction stays within [target - 1, target + 1] so the +-1 variance
  // bound holds even after nudging a value more than once.
  var diff = target * count - values.reduce((a, b) => a + b);
  var guard = 0;
  while (diff != 0 && guard < count * 10) {
    final idx = random.nextInt(count);
    if (diff > 0 && values[idx] < target + 1) {
      values[idx]++;
      diff--;
    } else if (diff < 0 && values[idx] > target - 1) {
      values[idx]--;
      diff++;
    }
    guard++;
  }
  return values;
}
