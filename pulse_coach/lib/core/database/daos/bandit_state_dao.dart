import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/tables/bandit_state_table.dart';

part 'bandit_state_dao.g.dart';

@DriftAccessor(tables: [BanditState])
class BanditStateDao extends DatabaseAccessor<AppDatabase>
    with _$BanditStateDaoMixin {
  BanditStateDao(super.db);

  Future<BanditStateData?> getLatestState() =>
      (select(banditState)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertState(BanditStateCompanion entry) =>
      into(banditState).insert(entry);

  Future<bool> updateState(BanditStateData data) =>
      update(banditState).replace(data);
}
