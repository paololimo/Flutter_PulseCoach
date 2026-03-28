import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/tables/user_profile_table.dart';

part 'user_profile_dao.g.dart';

@DriftAccessor(tables: [UserProfile])
class UserProfileDao extends DatabaseAccessor<AppDatabase>
    with _$UserProfileDaoMixin {
  UserProfileDao(super.db);

  Future<UserProfileData?> getProfile() =>
      select(userProfile).getSingleOrNull();

  Future<int> insertProfile(UserProfileCompanion entry) async {
    final existing = await getProfile();
    if (existing != null) {
      throw StateError(
        'A user profile already exists. Use updateProfile() instead.',
      );
    }
    return into(userProfile).insert(entry);
  }

  Future<bool> updateProfile(UserProfileData data) =>
      update(userProfile).replace(data);
}
