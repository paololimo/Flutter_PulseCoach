import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/tables/behavioral_state_table.dart';

part 'behavioral_state_dao.g.dart';

@DriftAccessor(tables: [BehavioralState])
class BehavioralStateDao extends DatabaseAccessor<AppDatabase>
    with _$BehavioralStateDaoMixin {
  BehavioralStateDao(super.db);

  Future<BehavioralStateData?> getLatestState() =>
      (select(behavioralState)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertState(BehavioralStateCompanion entry) =>
      into(behavioralState).insert(entry);
}
