import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/tables/rpe_feedback_table.dart';

part 'rpe_feedback_dao.g.dart';

@DriftAccessor(tables: [RpeFeedback])
class RpeFeedbackDao extends DatabaseAccessor<AppDatabase>
    with _$RpeFeedbackDaoMixin {
  RpeFeedbackDao(super.db);

  Future<List<RpeFeedbackData>> getAllFeedback() => select(rpeFeedback).get();

  Future<int> insertFeedback(RpeFeedbackCompanion entry) =>
      into(rpeFeedback).insert(entry);

  /// Idempotent on the natural key:
  ///   * if `sessionLogId` is set, dedupe by `session_log_id`
  ///   * otherwise dedupe by `(session_id, recorded_at)`.
  /// `InsertMode.insertOrIgnore` cannot cover this because the table has no
  /// UNIQUE constraint on either tuple — and adding one would force a schema
  /// bump beyond the E8-P3 cap. The DAO-level guard delivers the behaviour
  /// the method name promises.
  Future<int> insertFeedbackIdempotent(RpeFeedbackCompanion entry) async {
    final logIdValue = entry.sessionLogId;
    if (logIdValue.present && logIdValue.value != null) {
      final existing =
          await (select(rpeFeedback)
                ..where((t) => t.sessionLogId.equals(logIdValue.value!))
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) return existing.id;
    } else if (entry.sessionId.present && entry.recordedAt.present) {
      final existing =
          await (select(rpeFeedback)
                ..where(
                  (t) =>
                      t.sessionId.equals(entry.sessionId.value) &
                      t.recordedAt.equals(entry.recordedAt.value),
                )
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) return existing.id;
    }
    return into(rpeFeedback).insert(entry);
  }

  Future<List<RpeFeedbackData>> getLastN(int n) =>
      (select(rpeFeedback)
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
            ..limit(n))
          .get();
}
