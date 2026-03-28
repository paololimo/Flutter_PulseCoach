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

  Future<List<RpeFeedbackData>> getLastN(int n) =>
      (select(rpeFeedback)
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
            ..limit(n))
          .get();
}
